#!/usr/bin/env python3
"""
AST identifier extractor for standards checking.
Returns class names, method names, properties, arguments as structured JSON.
Used by standards-checker agent to verify naming conventions on actual code nodes
rather than grepping raw text (which fires on comments and string literals).

Usage: python3 ast-extract.py <file_path>
Output: {"classes": [...], "methods": [...], "functions": [...], "properties": [...], "arguments": [...], "constants": [...]}
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


def extract_python(filepath: str) -> dict:
    import ast

    source = Path(filepath).read_text(encoding="utf-8")
    tree = ast.parse(source, filename=filepath)

    result: dict = {"classes": [], "methods": [], "functions": [], "properties": [], "arguments": [], "constants": []}

    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef):
            result["classes"].append({"name": node.name, "line": node.lineno})
            for item in node.body:
                if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    result["methods"].append({"name": item.name, "line": item.lineno, "class": node.name})
                    for arg in item.args.args:
                        if arg.arg not in ("self", "cls"):
                            result["arguments"].append({"name": arg.arg, "line": item.lineno, "context": item.name})

        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.col_offset == 0:
                result["functions"].append({"name": node.name, "line": node.lineno})
                for arg in node.args.args:
                    result["arguments"].append({"name": arg.arg, "line": node.lineno, "context": node.name})

        elif isinstance(node, ast.Assign) and node.col_offset == 0:
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id.isupper():
                    result["constants"].append({"name": target.id, "line": node.lineno})

    return result


def extract_treesitter(filepath: str, language: str) -> dict:
    from tree_sitter_languages import get_parser

    source = Path(filepath).read_bytes()
    parser = get_parser(language)
    tree = parser.parse(source)

    result: dict = {"classes": [], "methods": [], "functions": [], "properties": [], "arguments": [], "constants": []}

    def text(node) -> str:
        return source[node.start_byte:node.end_byte].decode("utf-8", errors="replace")

    def line(node) -> int:
        return node.start_point[0] + 1

    def walk(node) -> None:
        if node.type == "class_declaration":
            name = node.child_by_field_name("name")
            if name:
                result["classes"].append({"name": text(name), "line": line(node)})

        elif node.type == "method_declaration":
            name = node.child_by_field_name("name")
            if name:
                result["methods"].append({"name": text(name), "line": line(node)})

        elif node.type == "property_declaration":
            name = node.child_by_field_name("name")
            if name:
                result["properties"].append({"name": text(name), "line": line(node)})

        elif node.type == "parameter":
            name = node.child_by_field_name("name")
            if name:
                result["arguments"].append({"name": text(name), "line": line(node)})

        elif node.type == "function_declaration":
            name = node.child_by_field_name("name")
            if name:
                result["functions"].append({"name": text(name), "line": line(node)})

        elif node.type == "method_definition":
            name = node.child_by_field_name("name")
            if name:
                result["methods"].append({"name": text(name), "line": line(node)})

        for child in node.children:
            walk(child)

    walk(tree.root_node)
    return result


def main() -> None:
    if len(sys.argv) < 2:
        print(json.dumps({"error": "usage: ast-extract.py <file_path>"}))
        sys.exit(1)

    filepath = Path(sys.argv[1])
    if not filepath.exists():
        print(json.dumps({"error": f"file not found: {filepath}"}))
        sys.exit(1)

    ext = filepath.suffix.lower()

    if ext == ".py":
        try:
            print(json.dumps(extract_python(str(filepath))))
        except SyntaxError as e:
            print(json.dumps({"error": str(e)}))
            sys.exit(1)
        return

    language = LANG_MAP.get(ext)
    if not language:
        print(json.dumps({"error": f"unsupported extension: {ext}"}))
        sys.exit(1)

    try:
        print(json.dumps(extract_treesitter(str(filepath), language)))
    except ImportError:
        print(json.dumps({"error": "tree-sitter not installed — run: pip install tree-sitter tree-sitter-languages"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
