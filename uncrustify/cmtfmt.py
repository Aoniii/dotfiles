#!/usr/bin/env python3
"""Reflow multi-line /* */ and /** */ comments (stdin -> stdout).

- every line starts with " * ", opener and closer on their own lines
- paragraphs are reflowed to WIDTH columns (tabs count as TAB)
- "@brief ..." is its own paragraph (title), followed by an empty " *" line
- other @tags (@param, @return...) each start a new paragraph
- empty lines between paragraphs are kept (at most one)
"""
import re
import sys

WIDTH = 80
TAB = 4

OPEN = re.compile(r"^([ \t]*)(/\*\*?)(.*)$")


def col(s):
    """Visual width of a prefix made of tabs/spaces/text."""
    c = 0
    for ch in s:
        c = (c // TAB + 1) * TAB if ch == "\t" else c + 1
    return c


def clean(line):
    """Strip leading ' * ' markers, including broken '* *' ones."""
    return re.sub(r"^[ \t]*(\*+[ \t]*)*", "", line).rstrip()


def paragraphs(lines):
    """Group text lines into paragraphs; None marks an empty line."""
    out, cur, brief = [], [], False

    def push():
        nonlocal cur
        if cur:
            out.append(" ".join(cur))
            cur = []

    for text in lines:
        if not text:
            push()
            if out and out[-1] is not None:
                out.append(None)
            brief = False
            continue
        if text.startswith("@"):
            push()
            brief = text.startswith("@brief")
        cur.append(text)
        # a brief ends with its sentence: the rest is description
        if brief and text.endswith((".", "!", "?", ":")):
            push()
            out.append(None)
            brief = False
    push()
    while out and out[-1] is None:
        out.pop()
    return out


def wrap(text, first_prefix, next_prefix):
    words, lines, cur = text.split(), [], ""
    for w in words:
        prefix = first_prefix if not lines else next_prefix
        cand = f"{cur} {w}" if cur else w
        if cur and col(prefix) + len(cand) > WIDTH:
            lines.append(cur)
            cur = w
        else:
            cur = cand
    if cur:
        lines.append(cur)
    return lines


def format_block(indent, opener, body):
    prefix = f"{indent} * "
    out = [f"{indent}{opener}"]
    for p in paragraphs([clean(l) for l in body]):
        if p is None:
            out.append(f"{indent} *")
            continue
        for l in wrap(p, prefix, prefix):
            out.append(f"{prefix}{l}")
    out.append(f"{indent} */")
    return out


def main():
    src = sys.stdin.read().split("\n")
    out, i = [], 0
    while i < len(src):
        line = src[i]
        m = OPEN.match(line)
        # multi-line comment starting on its own line
        if m and "*/" not in m.group(3):
            indent, opener, rest = m.groups()
            body = [rest] if rest.strip() else []
            j = i + 1
            while j < len(src) and "*/" not in src[j]:
                body.append(src[j])
                j += 1
            if j == len(src):  # unterminated: leave untouched
                out.extend(src[i:])
                break
            last = src[j].split("*/", 1)
            if last[1].strip():  # code after */ : leave untouched
                out.extend(src[i : j + 1])
            else:
                if last[0].strip(" \t*"):
                    body.append(last[0])
                out.extend(format_block(indent, opener, body))
            i = j + 1
            continue
        out.append(line)
        i += 1
    sys.stdout.write("\n".join(out))


if __name__ == "__main__":
    main()
