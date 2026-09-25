#!/bin/bash
# Runs playtest scenarios headless and compares screenshots, state dumps and saved files to a baseline.
#   tests/run.sh [--update] [scenario...]
# Requires love (11.x) and xvfb-run. Screenshots end up in tests/out/<scenario>/.
set -u
cd "$(dirname "$0")/.."
ROOT=$(pwd)
UPDATE=0
if [ "${1:-}" = "--update" ]; then UPDATE=1; shift; fi
SCENARIOS=("$@")
if [ ${#SCENARIOS[@]} -eq 0 ]; then
	SCENARIOS=($(ls tests/scenarios | sed 's/\.lua$//'))
fi

run_one() {
	local name=$1
	local work=$ROOT/tests/out/$name
	rm -rf "$work" && mkdir -p "$work/game" "$work/data"
	for f in "$ROOT"/*; do
		case $(basename "$f") in tests) ;; *) cp -r "$f" "$work/game/" ;; esac
	done
	cp -r tests/harness.lua tests/scenarios "$work/game/"
	printf '\nrequire "harness"\n' >> "$work/game/main.lua"
	ALSOFT_DRIVERS=null SDL_AUDIODRIVER=dummy XDG_DATA_HOME=$work/data NT_SCENARIO=$name \
		timeout 600 xvfb-run -a -s "-screen 0 1280x1024x24" love "$work/game" \
		> "$work/log.txt" 2>&1
	local code=$?
	mkdir -p "$work/shots"
	cp "$work"/data/love/not_tetris_2/*.png "$work"/data/love/not_tetris_2/*.txt "$work/shots/" 2>/dev/null
	(cd "$work/shots" && md5sum *.png *.txt 2>/dev/null) > "$work/hashes.txt"
	rm -rf "$work/game" "$work/data"
	if [ $code -ne 0 ]; then
		echo "FAIL $name (exit $code)"; grep -A12 "ERROR\|TIMEOUT" "$work/log.txt" | head -20
		return 1
	fi
	local expected=tests/expected/$name.txt
	if [ $UPDATE -eq 1 ]; then
		cp "$work/hashes.txt" "$expected"; echo "UPDATED $name"
	elif [ ! -f "$expected" ]; then
		echo "NO BASELINE $name"
	elif diff -q "$expected" "$work/hashes.txt" > /dev/null; then
		echo "PASS $name"
	else
		echo "DIFF $name"; diff "$expected" "$work/hashes.txt" | grep '^[<>]'
		return 1
	fi
}

mkdir -p tests/out
status=0
pids=()
for s in "${SCENARIOS[@]}"; do
	run_one "$s" > "tests/out/.$s.result" 2>&1 &
	pids+=($!)
done
for i in "${!pids[@]}"; do
	wait "${pids[$i]}" || status=1
	cat "tests/out/.${SCENARIOS[$i]}.result"
done
exit $status
