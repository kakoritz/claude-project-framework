#!/usr/bin/env python3
"""
Tree-sitter context extractor for secret scanner.
Parses a source file and returns only string literals and assignment values as JSON.
Comments are excluded automatically — no regex hacks needed.

Falls back gracefully if tree-sitter is not installed.

Usage: python3 ts-context.py <file_path>
Output: {"strings": [...], "assignments": [...]}
     or {"fallback": true, "reason": "..."} when tree-sitter unavailable
"""
import sys
import json
from pathlib import Path

LANG_MAP = {
    ".py":  "python",
    ".cs":  "c_sharp",
    ".js":  "javascript",
    ".jsx": "javascript",
    ".ts":  "typescript",
    ".tsx": "tsx",
}

STRING_TYPES = {
    "string",
    "string_literal",
    "verbatim_string_literal",
    "interpolated_string_expression",
    "raw_string_literal",
    "template_string",
    "string_value",
}

ASSIGNMENT_TYPES = {
    "assignment_expression",
    "variable_declarator",
    "local_declaration_statement",
    "field_declaration",
    "assignment_statement",
}


def walk(node, source: bytes, strings: list, assignments: list) -> None:
    if node.type in STRING_TYPES:
        strings.append(source[node.start_byte:node.end_byte].decode("utf-8", errors="replace"))
    elif node.type in ASSIGNMENT_TYPES:
        assignments.append(source[node.start_byte:node.end_byte].decode("utf-8", errors="replace")[:300])
    for child in node.children:
        walk(child, source, strings, assignments)


def main() -> None:
    if len(sys.argv) < 2:
        print(json.dumps({"fallback": True, "reason": "no file path provided"}))
        sys.exit(0)

    path = Path(sys.argv[1])
    if not path.exists():
        print(json.dumps({"fallback": True, "reason": "file not found"}))
        sys.exit(0)

    language = LANG_MAP.get(path.suffix.lower())
    if not language:
        print(json.dumps({"fallback": True, "reason": f"unsupported extension: {path.suffix}"}))
        sys.exit(0)

    try:
        from tree_sitter_languages import get_parser
    except ImportError:
        print(json.dumps({"fallback": True, "reason": "tree-sitter-languages not installed"}))
        sys.exit(0)

    try:
        source = path.read_bytes()
        parser = get_parser(language)
        tree = parser.parse(source)
    except Exception as e:
        print(json.dumps({"fallback": True, "reason": str(e)}))
        sys.exit(0)

    strings: list = []
    assignments: list = []
    walk(tree.root_node, source, strings, assignments)
    print(json.dumps({"strings": strings, "assignments": assignments}))


if __name__ == "__main__":
    main()
