#!/usr/bin/env python3
"""Create a temporary TeX report project under /tmp."""

from __future__ import annotations

import argparse
import datetime as dt
import re
from pathlib import Path


TEX_TEMPLATE = r"""\documentclass[10pt,a4paper]{article}
\usepackage[margin=0.82in]{geometry}
\usepackage{fontspec}
\usepackage{xeCJK}
\setmainfont{Apple SD Gothic Neo}
\setsansfont{Apple SD Gothic Neo}
\setmonofont{Menlo}
\setCJKmainfont{Apple SD Gothic Neo}
\setCJKsansfont{Apple SD Gothic Neo}
\setCJKmonofont{Apple SD Gothic Neo}
\usepackage{microtype}
\usepackage{xcolor}
\definecolor{accent}{HTML}{235789}
\definecolor{softgray}{HTML}{F5F7FA}
\definecolor{rulegray}{HTML}{D8DEE9}
\usepackage{graphicx}
\usepackage{booktabs}
\usepackage{tabularx}
\usepackage{array}
\usepackage{siunitx}
\usepackage{caption}
\usepackage{subcaption}
\usepackage{enumitem}
\usepackage{hyperref}
\usepackage[most]{tcolorbox}
\usepackage{tikz}
\usepackage{pgfplots}
\pgfplotsset{compat=1.18}
\usetikzlibrary{arrows.meta,positioning,shapes.geometric,fit}

\hypersetup{colorlinks=true,linkcolor=accent,urlcolor=accent,citecolor=accent}
\setlength{\parindent}{0pt}
\setlength{\parskip}{0.55em}
\setlist[itemize]{leftmargin=1.4em,itemsep=0.2em,topsep=0.25em}
\setlist[enumerate]{leftmargin=1.6em,itemsep=0.2em,topsep=0.25em}
\captionsetup{font=small,labelfont=bf}

\newtcolorbox{callout}[1][]{
  colback=softgray,
  colframe=rulegray,
  boxrule=0.4pt,
  arc=1.2mm,
  left=1.2mm,
  right=1.2mm,
  top=1mm,
  bottom=1mm,
  #1
}

\newcommand{\code}[1]{\texttt{\detokenize{#1}}}
\newcolumntype{Y}{>{\raggedright\arraybackslash}X}

\title{\vspace{-2.0em}{\Large\bfseries __TITLE__}\\[-0.1em]
{\normalsize Technical provenance report}}
\author{}
\date{__DATE__}

\begin{document}
\maketitle
\vspace{-2.0em}

\begin{callout}
Replace this scaffold with the report body. Keep evidence labels explicit: Confirmed, Recorded, Inferred, Unverified.
\end{callout}

\section*{Executive Summary}

Write the high-signal summary first.

\section*{Evidence Table}

\begin{tabularx}{\linewidth}{@{}lY@{}}
\toprule
Item & Value \\
\midrule
Source & TBD \\
Build directory & \code{__PROJECT_DIR__} \\
\bottomrule
\end{tabularx}

\section*{Figure Placeholder}

\begin{figure}[h]
\centering
\begin{tikzpicture}[node distance=9mm, every node/.style={font=\small}]
\node[draw, rounded corners, fill=softgray, minimum width=30mm, minimum height=8mm] (a) {Source};
\node[draw, rounded corners, fill=softgray, minimum width=30mm, minimum height=8mm, right=of a] (b) {Transform};
\node[draw, rounded corners, fill=softgray, minimum width=30mm, minimum height=8mm, right=of b] (c) {PDF};
\draw[-{Latex[length=2mm]}] (a) -- (b);
\draw[-{Latex[length=2mm]}] (b) -- (c);
\end{tikzpicture}
\caption{Replace with a task-specific pipeline or plot.}
\end{figure}

\end{document}
"""


MAKEFILE_TEMPLATE = r"""PDF=main.pdf

.PHONY: all clean

all: $(PDF)

$(PDF): main.tex
	latexmk -xelatex -interaction=nonstopmode -halt-on-error main.tex

clean:
	latexmk -C
	rm -f *.bbl *.run.xml
"""


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-+", "-", value).strip("-")
    return value or "tex-report"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--slug", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--root", default="/tmp")
    args = parser.parse_args()

    slug = slugify(args.slug)
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    project = Path(args.root).expanduser().resolve() / f"{slug}-{stamp}"
    project.mkdir(parents=True, exist_ok=False)

    for subdir in ["figures", "tables", "data", "build"]:
        (project / subdir).mkdir()

    tex = TEX_TEMPLATE.replace("__TITLE__", args.title)
    tex = tex.replace("__DATE__", dt.date.today().isoformat())
    tex = tex.replace("__PROJECT_DIR__", str(project))
    (project / "main.tex").write_text(tex, encoding="utf-8")
    (project / "Makefile").write_text(MAKEFILE_TEMPLATE, encoding="utf-8")

    print(project)


if __name__ == "__main__":
    main()
