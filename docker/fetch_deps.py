#!/usr/bin/env python3
"""Download the GitHub source repositories declared by install.py."""
import argparse
import ast
import importlib.util
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


def repositories():
    # Importing install.py does not run its installation entry point.
    spec = importlib.util.spec_from_file_location("bridge_install", ROOT / "install.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    urls = module.ThirdParty("github")
    tree = ast.parse((ROOT / "install.py").read_text(encoding="utf-8"))
    calls = sorted(
        (node for node in ast.walk(tree)
         if isinstance(node, ast.Call)
         and isinstance(node.func, ast.Attribute)
         and isinstance(node.func.value, ast.Name)
         and node.func.value.id == "self"
         and node.func.attr == "_clone_repo"),
        key=lambda node: node.lineno,
    )
    seen = set()
    for call in calls:
        name, *options = [ast.literal_eval(arg) for arg in call.args]
        if name in seen:
            raise ValueError("Duplicate dependency declaration: " + name)
        seen.add(name)
        yield name, urls.get_repo_url(name), options


def fetch(name, url, options, destination, attempts=3):
    target = destination / name
    if target.exists():
        # Do not overwrite existing sources or silently accept an incomplete clone.
        if not (target / ".git").exists():
            raise ValueError("Existing directory is not a Git clone: " + str(target))
        origin = subprocess.check_output(
            ["git", "-C", str(target), "remote", "get-url", "origin"], text=True
        ).strip()
        if origin != url:
            raise ValueError("Existing clone has a different origin: " + str(target))
        for option in options:
            if option.startswith("--branch="):
                ref = option.split("=", 1)[1]
                head = subprocess.check_output(
                    ["git", "-C", str(target), "rev-parse", "HEAD"], text=True
                ).strip()
                expected = subprocess.check_output(
                    ["git", "-C", str(target), "rev-parse", ref + "^{commit}"], text=True
                ).strip()
                if head != expected:
                    raise ValueError("Existing clone is at a different revision: " + str(target))
        print("Skip existing clone: " + str(target), flush=True)
        return
    # A failed clone never leaves a directory that a later run could mistake for success.
    for attempt in range(1, attempts + 1):
        try:
            with tempfile.TemporaryDirectory(prefix=".fetch-", dir=destination) as temp:
                checkout = Path(temp) / name
                subprocess.run(["git", "clone", *options, url, str(checkout)], check=True)
                checkout.rename(target)
            return
        except subprocess.CalledProcessError:
            if attempt == attempts:
                raise
            delay = min(2 ** attempt, 10)
            print(f"Clone failed ({attempt}/{attempts}); retrying {name} in {delay}s...", flush=True)
            time.sleep(delay)


def positive_int(value):
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return number


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dest", type=Path, default=ROOT / "docker/deps")
    parser.add_argument("--dry-run", action="store_true", help="print commands without downloading")
    parser.add_argument("--attempts", type=positive_int, default=3, help="clone attempts per repository (default: 3)")
    args = parser.parse_args()
    destination = args.dest.expanduser().resolve()
    if not args.dry_run:
        if shutil.which("git") is None:
            parser.error("git is required")
        destination.mkdir(parents=True, exist_ok=True)
    for name, url, options in repositories():
        print(shlex.join(["git", "clone", *options, url, str(destination / name)]), flush=True)
        if not args.dry_run:
            fetch(name, url, options, destination, args.attempts)
    print("Commands listed." if args.dry_run else "All dependency repositories are ready.")


if __name__ == "__main__":
    try:
        main()
    except (subprocess.SubprocessError, OSError, ValueError) as error:
        raise SystemExit("Dependency download failed: " + str(error))
