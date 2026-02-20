#!/usr/bin/env python3

import argparse
import re
import sys
from pathlib import Path


def normalize_category_name(raw: str) -> str:
    name = raw.strip()
    if not name:
        raise ValueError("Category name is empty")

    if name.startswith("[[") and name.endswith("]]"):
        name = name[2:-2].strip()

    if name.lower().endswith(".md"):
        name = name[:-3]
    if name.lower().endswith(".base"):
        name = name[:-5]

    name = name.replace("_", " ")
    if " " not in name and "-" in name:
        name = name.replace("-", " ")

    name = re.sub(r"\s+", " ", name).strip()

    if not name:
        raise ValueError("Category name is empty after normalization")

    if "/" in name or "\\" in name:
        raise ValueError("Category name cannot contain path separators")

    if all(ch.islower() or ch.isspace() for ch in name):
        name = " ".join(part.capitalize() for part in name.split(" "))

    return name


def build_category_note(category: str) -> str:
    return f"---\ntags:\n- categories\n---\n![[{category}.base]]\n"


def build_base_file(category: str) -> str:
    return (
        "views:\n"
        "  - type: table\n"
        f"    name: \"All {category}\"\n"
        "    filters:\n"
        "      and:\n"
        f"        - categories.contains(link(\"{category}\"))\n"
        "        - '!file.name.endsWith(\"Template\")'\n"
        "    order:\n"
        "      - file.name\n"
        "    sort:\n"
        "      - property: file.name\n"
        "        direction: ASC\n"
    )


def write_file(path: Path, content: str, force: bool, dry_run: bool) -> str:
    if path.exists() and not force:
        return "skipped"

    action = "updated" if path.exists() else "created"
    if not dry_run:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")
    return action


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Create Obsidian category note and base file in one step."
    )
    parser.add_argument(
        "category",
        nargs="+",
        help="Category name. Example: Papers or \"Paper Notes\"",
    )
    parser.add_argument(
        "--vault",
        default=".",
        help="Vault root path (default: current directory)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview actions without writing files",
    )

    args = parser.parse_args()

    raw_category = " ".join(args.category)
    try:
        category = normalize_category_name(raw_category)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    vault_root = Path(args.vault).expanduser().resolve()
    if not vault_root.exists() or not vault_root.is_dir():
        print(f"ERROR: Vault path is not a directory: {vault_root}", file=sys.stderr)
        return 2

    category_path = vault_root / "Categories" / f"{category}.md"
    base_path = vault_root / "Templates" / "Bases" / f"{category}.base"

    note_status = write_file(
        category_path,
        build_category_note(category),
        force=args.force,
        dry_run=args.dry_run,
    )
    base_status = write_file(
        base_path,
        build_base_file(category),
        force=args.force,
        dry_run=args.dry_run,
    )

    mode = "DRY RUN" if args.dry_run else "APPLY"
    print(f"[{mode}] category: {category}")
    print(f"[NOTE] {note_status}: {category_path}")
    print(f"[BASE] {base_status}: {base_path}")

    if note_status == "skipped" or base_status == "skipped":
        print("Hint: use --force to overwrite existing files.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
