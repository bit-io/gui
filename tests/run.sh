#!/bin/bash
# Buduje i uruchamia zestaw testow headless.
# Wymaga: hackerc 0.5 w PATH (lub HACKERC=...), HACKERSCRIPT_LIBS wskazujacego libs/ z repozytorium HackerScript, cargo (Rust >= 1.86).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
GUI_ROOT="$(dirname "$HERE")"
HACKERC="${HACKERC:-hackerc}"
: "${HACKERSCRIPT_LIBS:?ustaw HACKERSCRIPT_LIBS na katalog libs/ z repozytorium HackerScript}"
WORK="$(mktemp -d)"
mkdir -p "$WORK/libs" && ln -s "$GUI_ROOT" "$WORK/libs/gui"
export BIT_LIBS="$WORK/libs"
"$HACKERC" build "$HERE/cases/suite.hcs" -o "$WORK/out" --crate-name gui_suite --libs-root "$HACKERSCRIPT_LIBS"
( cd "$WORK/out" && cargo build --release )
GUI_BACKEND=headless "$WORK/out/target/release/gui_suite"
