#!/usr/bin/env python3
"""
scan-orchestrator.py — Auto-populate an ORCHESTRATOR.md delta for a UiPath project.

Queries UiPath Orchestrator OData for all resources in the specified folder paths
(queues, assets, storage buckets, processes) and writes a ready-to-use
ORCHESTRATOR.md delta. No external pip installs required — stdlib only.

Usage:
    python3 scan-orchestrator.py --folders "Production/Dept/Bot,Test/Dept/Bot,Development/Dept/Bot"
    python3 scan-orchestrator.py --folders "Production/Dept/Bot" --project-name "MyBot" --output ./ORCHESTRATOR.md

Auth: reads from environment or .env file:
    UIPATH_CLIENT_ID       — OAuth2 client ID
    UIPATH_CLIENT_SECRET   — OAuth2 client secret
    UIPATH_BASE_URL        — e.g. https://cloud.uipath.com/myorg/mytenant/orchestrator_
    UIPATH_TOKEN_URL       — e.g. https://cloud.uipath.com/identity_/connect/token

Or pass --base-url and --token-url on the command line.
"""
import os
import sys
import json
import argparse
import urllib.request
import urllib.parse
import urllib.error
from pathlib import Path
from datetime import datetime

SCOPE = "OR.Assets OR.Queues OR.Execution OR.Folders OR.Buckets"

ENV_NAME_MAP = {
    "production":  "Prod",
    "test":        "Test",
    "development": "Dev",
}


def load_env(env_file: str = ".env") -> None:
    for path in [env_file, str(Path.home() / ".env")]:
        try:
            with open(path) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, v = line.split("=", 1)
                        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
            break
        except FileNotFoundError:
            continue


def get_token(token_url: str, client_id: str, client_secret: str) -> str:
    data = urllib.parse.urlencode({
        "grant_type":    "client_credentials",
        "client_id":     client_id,
        "client_secret": client_secret,
        "scope":         SCOPE,
    }).encode()
    req = urllib.request.Request(token_url, data=data, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())["access_token"]
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        print(f"  ERROR: Auth failed ({e.code}): {body[:300]}")
        sys.exit(1)


def odata_get(base_url: str, token: str, endpoint: str,
              folder_id: int | None = None, params: dict | None = None) -> list:
    url = f"{base_url.rstrip('/')}/odata/{endpoint}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Accept", "application/json")
    if folder_id is not None:
        req.add_header("X-UIPATH-OrganizationUnitId", str(folder_id))
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read()).get("value", [])
    except urllib.error.HTTPError as e:
        print(f"  WARN: {endpoint} → {e.code} (skipped)")
        return []


def resolve_folder(base_url: str, token: str, folder_path: str) -> tuple[int, str] | None:
    items = odata_get(base_url, token, "Folders", params={
        "$filter": f"FullyQualifiedName eq '{folder_path}'",
        "$select": "Id,FullyQualifiedName,DisplayName",
    })
    if not items:
        print(f"  WARN: Folder not found: '{folder_path}'")
        return None
    return items[0]["Id"], items[0]["FullyQualifiedName"]


def detect_env(folder_path: str) -> str:
    root = folder_path.split("/")[0].lower()
    return ENV_NAME_MAP.get(root, root.capitalize())


def scan_folder(base_url: str, token: str, folder_path: str) -> dict | None:
    resolved = resolve_folder(base_url, token, folder_path)
    if not resolved:
        return None
    folder_id, full_path = resolved
    env = detect_env(folder_path)
    print(f"  [{env}] {full_path}  (folder ID: {folder_id})")

    queues    = odata_get(base_url, token, "QueueDefinitions", folder_id, {"$select": "Id,Name,Description",                 "$top": "200"})
    assets    = odata_get(base_url, token, "Assets",           folder_id, {"$select": "Id,Name,ValueType",                   "$top": "200"})
    buckets   = odata_get(base_url, token, "Buckets",          folder_id, {"$select": "Id,Name,Description,StorageProvider", "$top": "200"})
    processes = odata_get(base_url, token, "Releases",         folder_id, {"$select": "Id,Key,Name,ProcessKey",              "$top": "200"})

    print(f"       queues={len(queues)}  assets={len(assets)}  buckets={len(buckets)}  processes={len(processes)}")

    return {
        "env":       env,
        "path":      full_path,
        "folder_id": folder_id,
        "queues":    sorted(queues,    key=lambda x: x["Name"]),
        "assets":    sorted(assets,    key=lambda x: x["Name"]),
        "buckets":   sorted(buckets,   key=lambda x: x["Name"]),
        "processes": sorted(processes, key=lambda x: x["Name"]),
    }


def md_table(headers: list, rows: list) -> list:
    lines = ["| " + " | ".join(str(h) for h in headers) + " |",
             "|" + "---|" * len(headers)]
    for row in rows:
        lines.append("| " + " | ".join(str(c) for c in row) + " |")
    return lines


def generate_delta(project_name: str, folders: list) -> str:
    ts    = datetime.now().strftime("%Y-%m-%d")
    lines = [
        f"# Orchestrator Reference — {project_name}",
        "",
        "Extends: ~/dotfiles-claude/docs/ORCHESTRATOR_STANDARD.md",
        "",
        "For connection settings, OData patterns, folder hierarchy, and uip CLI — see the standard.",
        f"_Generated: {ts} — re-run `python3 ~/dotfiles-claude/tools/scan-orchestrator.py` to refresh._",
        "",
        "---",
        "",
        "## Folder Paths",
        "",
    ]
    lines += md_table(
        ["Environment", "Folder Path", "Folder ID"],
        [[f["env"], f"`{f['path']}`", f["folder_id"]] for f in folders],
    )

    lines += ["", "---", "", "## Queues", ""]
    rows = [[f"`{q['Name']}`", q["Id"], f["env"]] for f in folders for q in f["queues"]]
    lines += md_table(["Queue Name", "ID", "Environment"], rows) if rows else ["_No queues found._"]

    lines += ["", "---", "", "## Storage Buckets", ""]
    rows = [[f"`{b['Name']}`", b["Id"], b.get("StorageProvider", ""), f["env"]]
            for f in folders for b in f["buckets"]]
    lines += md_table(["Bucket Name", "ID", "Provider", "Environment"], rows) if rows else ["_No storage buckets found._"]

    lines += ["", "---", "", "## Assets", ""]
    rows = [[f"`{a['Name']}`", a["Id"], a.get("ValueType", ""), f["env"]]
            for f in folders for a in f["assets"]]
    lines += md_table(["Asset Name", "ID", "Type", "Environment"], rows) if rows else ["_No assets found._"]

    lines += ["", "---", "", "## Processes", ""]
    rows = [[f"`{p['Name']}`", f"`{p.get('Key', '')}`", f["env"]]
            for f in folders for p in f["processes"]]
    lines += md_table(["Process Name", "Key", "Environment"], rows) if rows else ["_No processes found._"]

    lines += ["", "---", "", "## Notes", "", ""]
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scan Orchestrator and generate ORCHESTRATOR.md delta",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Required env vars (or set in .env):
  UIPATH_CLIENT_ID       OAuth2 client ID
  UIPATH_CLIENT_SECRET   OAuth2 client secret
  UIPATH_BASE_URL        e.g. https://cloud.uipath.com/myorg/mytenant/orchestrator_
  UIPATH_TOKEN_URL       e.g. https://cloud.uipath.com/identity_/connect/token

Example:
  python3 scan-orchestrator.py --folders "Production/Dept/Bot,Test/Dept/Bot" --project-name "MyBot"
        """,
    )
    parser.add_argument("--folders",       required=True,   help="Comma-separated Orchestrator folder paths")
    parser.add_argument("--project-name",  default="",      help="Project name for the delta header")
    parser.add_argument("--output",        default="ORCHESTRATOR.md", help="Output file path")
    parser.add_argument("--env-file",      default=".env",  help=".env file path")
    parser.add_argument("--base-url",      default="",      help="Orchestrator base URL (overrides UIPATH_BASE_URL)")
    parser.add_argument("--token-url",     default="",      help="Token endpoint URL (overrides UIPATH_TOKEN_URL)")
    args = parser.parse_args()

    load_env(args.env_file)
    client_id     = os.environ.get("UIPATH_CLIENT_ID")
    client_secret = os.environ.get("UIPATH_CLIENT_SECRET")
    base_url      = args.base_url or os.environ.get("UIPATH_BASE_URL", "")
    token_url     = args.token_url or os.environ.get("UIPATH_TOKEN_URL",
                        "https://cloud.uipath.com/identity_/connect/token")

    missing = []
    if not client_id:     missing.append("UIPATH_CLIENT_ID")
    if not client_secret: missing.append("UIPATH_CLIENT_SECRET")
    if not base_url:      missing.append("UIPATH_BASE_URL (or --base-url)")
    if missing:
        print(f"ERROR: Missing required values: {', '.join(missing)}")
        print("  Set them in .env or as environment variables.")
        sys.exit(1)

    folder_paths = [p.strip() for p in args.folders.split(",") if p.strip()]
    project_name = args.project_name or folder_paths[0].rstrip("/").split("/")[-1]
    output_path  = Path(args.output)

    print(f"\nscanning: {project_name}")
    print(f"base url: {base_url}")
    print(f"folders:  {folder_paths}\n")

    print("authenticating...")
    token = get_token(token_url, client_id, client_secret)
    print("  OK\n")

    results = []
    for path in folder_paths:
        data = scan_folder(base_url, token, path)
        if data:
            results.append(data)

    if not results:
        print("\nERROR: No folders resolved. Check folder paths and try again.")
        print("  Paths are case-sensitive and must match exactly.")
        sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(generate_delta(project_name, results), encoding="utf-8")

    print(f"\nwrote: {output_path.resolve()}")
    print(f"  {len(results)} folder(s)  |  "
          f"{sum(len(f['queues']) for f in results)} queues  |  "
          f"{sum(len(f['buckets']) for f in results)} buckets  |  "
          f"{sum(len(f['assets']) for f in results)} assets  |  "
          f"{sum(len(f['processes']) for f in results)} processes\n")


if __name__ == "__main__":
    main()
