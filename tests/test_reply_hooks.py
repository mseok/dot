#!/usr/bin/env python3
"""Checks for the two reply hooks. Usage: test_reply_hooks.py [PATH_TO_reply-path-check [PATH_TO_reply-language-hint]]
Without arguments it tests the scripts in ../bin next to this file.
Each case is one recorded false alarm or one behavior that must stay. Prints one line per case."""
import importlib.machinery
import importlib.util
import os
import sys
import tempfile


def load(path, name):
    loader = importlib.machinery.SourceFileLoader(name, path)
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def problems(mod, text, hosts=()):
    if hasattr(mod, "find_problems"):
        return mod.find_problems(text, hosts)
    out = []  # the pre-fix script has no function: reproduce its main loop
    for match in mod.PATH_RE.findall(text):
        candidate = os.path.expanduser(match.rstrip(".,;:"))
        if not os.path.exists(candidate):
            out.append(f"missing: {candidate}")
    for match in mod.REL_RE.findall(text):
        out.append(f"relative (give an absolute path): {match}")
    return out


def main():
    bin_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bin")
    args = sys.argv[1:] or [os.path.join(bin_dir, "reply-path-check"), os.path.join(bin_dir, "reply-language-hint")]
    rpc = load(args[0], "rpc")
    home = os.path.realpath(tempfile.mkdtemp(dir=os.path.expanduser("~"), prefix=".rpc-test-"))
    spaced = os.path.join(home, "My Notes", "deck v2.md")
    os.makedirs(os.path.dirname(spaced))
    open(spaced, "w").close()
    plain = os.path.join(home, "report.md")
    open(plain, "w").close()
    missing = os.path.join(home, "nope.md")
    cases = [
        ("angle-bracket link with spaces", f"See [deck](<{spaced}>).", 0),
        ("backtick path with spaces", f"Saved to `{spaced}`.", 0),
        ("bare path with spaces", f"Saved to {spaced} on this host.", 0),
        ("existing path in parentheses", f"Done ({plain}).", 0),
        ("glob pattern", f"All files match {home}/*.md and {home}/part-??.txt.", 0),
        ("fenced command block", f"Run:\n```\ncat {missing}\npython3 scripts/build.py\n```\n", 0),
        ("inline command snippet", f"Use `rsync -a {missing} host:` to copy.", 0),
        ("path on another OS family", "On the server it is /home/user/run/out.csv." if sys.platform == "darwin" else "On the Mac it is /Users/user/out.csv.", 0),
        ("line naming another host", f"exists on MacBook: {home}/only-there.md", 0),
        ("truly missing absolute path", f"Saved to {missing}.", 1),
        ("missing path in an angle link", f"See [x](<{home}/No Such/file.md>).", 1),
        ("relative deliverable path", "The table is in findings/summary.tsv.", 1),
    ]
    failed = 0
    for name, text, want in cases:
        got = problems(rpc, text, ("MacBook",))
        ok = (len(got) == want) if want == 0 else (len(got) >= 1)
        failed += not ok
        print(("pass" if ok else "FAIL"), "-", name, "- problems:", len(got))
    os.remove(spaced); os.remove(plain); os.rmdir(os.path.dirname(spaced)); os.rmdir(home)
    if len(args) > 1:
        hint = load(args[1], "hint")
        lang_cases = [("Korean message gets the hint", "이거 다시 확인해줘", True), ("English message gets none", "please check this again", False),
                      ("Korean asking for an English answer gets none", "이건 영어로 답해줘", False), ("one Hangul letter is not enough", "ㅇㅇ ok 가", False),
                      ("mixed Korean and paths gets the hint", "/Users/x/a.py 여기 버그 고쳐줘", True)]
        for name, prompt, want in lang_cases:
            ok = bool(hint.hint_for(prompt)) == want
            failed += not ok
            print(("pass" if ok else "FAIL"), "-", name)
    print("failed:", failed)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
