#!/usr/bin/env python3
"""
CLAUDE.md framework marker management.

Subcommands:
  add-markers <file>                   — wrap known framework sections in <!-- BEGIN/END --> markers
  update-sections <installed> <tmpl>   — interactive update of framework sections from template

Framework-managed sections (wrapped with markers):
  framework-branch-protocol
  framework-doc-structure
  framework-agent-standards
  framework-code-style
  framework-token-habits

Personal sections (never touched):
  ## Who I Am
  ## DCLI Infrastructure
  anything else the engineer added
"""
import re
import sys
import shutil
import difflib
import datetime
from pathlib import Path

SECTION_TAGS: dict[str, str] = {
    "## Standard Branch Protocol": "framework-branch-protocol",
    "## Standard Doc Structure":   "framework-doc-structure",
    "## Agent Standards":           "framework-agent-standards",
    "## Code Style":                "framework-code-style",
    "## Token-Efficient Habits":    "framework-token-habits",
}

MARKER_PATTERN = re.compile(
    r'<!-- BEGIN:(framework-[\w-]+) -->(.*?)<!-- END:\1 -->',
    re.DOTALL,
)


def _backup(path: Path) -> Path:
    ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = Path(f"{path}.bak.{ts}")
    shutil.copy2(path, backup)
    return backup


# ── add-markers ───────────────────────────────────────────────────────────────

def add_markers(filepath: str) -> None:
    """Insert framework markers around known section headings without changing content."""
    path = Path(filepath)
    if not path.exists():
        print(f"  ERROR: {path} not found")
        sys.exit(1)

    content = path.read_text(encoding="utf-8")

    if "<!-- BEGIN:framework-" in content:
        print("  Markers already present — nothing to do")
        return

    lines = content.splitlines(keepends=True)
    result: list[str] = []
    i = 0
    modified = False

    while i < len(lines):
        line = lines[i]

        tag = None
        for heading, t in SECTION_TAGS.items():
            if line.startswith(heading):
                tag = t
                break

        if tag:
            # Collect lines until the next top-level ## heading
            section: list[str] = [line]
            j = i + 1
            while j < len(lines):
                if lines[j].startswith("## ") or lines[j].startswith("# "):
                    break
                section.append(lines[j])
                j += 1

            # Trim trailing blank lines
            while section and section[-1].strip() == "":
                section.pop()

            result.append(f"<!-- BEGIN:{tag} -->\n")
            result.extend(section)
            result.append(f"\n<!-- END:{tag} -->\n")
            modified = True
            i = j
        else:
            result.append(line)
            i += 1

    if modified:
        backup = _backup(path)
        path.write_text("".join(result), encoding="utf-8")
        print(f"  Markers added: {path}")
        print(f"  Backup: {backup}")
    else:
        print("  No matching framework sections found")


# ── update-sections ───────────────────────────────────────────────────────────

def update_sections(installed_path: str, template_path: str) -> None:
    """Interactively update framework-marked sections from the template."""
    inst = Path(installed_path)
    tmpl = Path(template_path)

    if not inst.exists():
        print(f"  CLAUDE.md not found at {inst} — skipping")
        return
    if not tmpl.exists():
        print(f"  Template not found at {tmpl} — skipping")
        return

    installed = inst.read_text(encoding="utf-8")
    template  = tmpl.read_text(encoding="utf-8")

    if "<!-- BEGIN:framework-" not in installed:
        print("  CLAUDE.md has no framework markers.")
        print("  Run: setup.sh --add-markers   (or setup.ps1 --add-markers)")
        print("  Then re-run the update.")
        return

    updated = installed
    any_changed = False

    for tag in SECTION_TAGS.values():
        pat = rf'<!-- BEGIN:{tag} -->(.*?)<!-- END:{tag} -->'
        inst_m = re.search(pat, installed, re.DOTALL)
        tmpl_m = re.search(pat, template, re.DOTALL)

        if not inst_m:
            print(f"  SKIP {tag} — not found in installed CLAUDE.md")
            continue
        if not tmpl_m:
            print(f"  SKIP {tag} — not in template")
            continue

        if inst_m.group(1).strip() == tmpl_m.group(1).strip():
            print(f"  = {tag}")
            continue

        any_changed = True
        print(f"\n  CHANGED: {tag}")

        old_lines = inst_m.group(1).splitlines()
        new_lines = tmpl_m.group(1).splitlines()
        diff = list(difflib.unified_diff(old_lines, new_lines, lineterm="", n=2))
        for line in diff[:25]:
            print(f"    {line}")
        if len(diff) > 25:
            print(f"    ... ({len(diff) - 25} more lines)")

        try:
            ans = input(f"\n  Update {tag}? [Y/n]: ").strip().lower()
        except EOFError:
            ans = "y"

        if ans in ("", "y", "yes"):
            new_block = f"<!-- BEGIN:{tag} -->{tmpl_m.group(1)}<!-- END:{tag} -->"
            updated = re.sub(pat, new_block, updated, flags=re.DOTALL)
            print(f"  OK updated: {tag}")
        else:
            print(f"  Skipped: {tag}")

    if any_changed and updated != installed:
        backup = _backup(inst)
        inst.write_text(updated, encoding="utf-8")
        print(f"\n  CLAUDE.md updated. Backup: {backup}")
    elif not any_changed:
        print("\n  All framework sections are up to date.")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print("Usage:")
        print("  claude-md.py add-markers <file>")
        print("  claude-md.py update-sections <installed> <template>")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "add-markers":
        if len(sys.argv) < 3:
            print("Usage: claude-md.py add-markers <file>")
            sys.exit(1)
        add_markers(sys.argv[2])

    elif cmd == "update-sections":
        if len(sys.argv) < 4:
            print("Usage: claude-md.py update-sections <installed> <template>")
            sys.exit(1)
        update_sections(sys.argv[2], sys.argv[3])

    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
