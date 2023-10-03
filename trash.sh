#!/usr/bin/env bash

# MIT License
#
# Copyright (c) 2023 saihon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

func-usage() {
	cat << HELP

Usage: $NAME [options] [files or directories]

Options:
  -a, --all         Show all items in Trash including hidden.
  -e, --empty       Permanently delete items in Trash.
  -c, --confirm     Confirm before delete items in Trash.
  -l, --list        Show items in the Trash in long format.
  -h, --help        Display this help and exit.
  -v, --version     Output version information and exit.

HELP
	exit 2
}

func-version() {
	echo "$NAME: $VERSION"
	exit 2
}

func-error() {
	echo "Error: $1." 1>&2
	exit 1
}

func-validation() {
	if [[ "$1" =~ ^-([^-]+|$) ]] && [[ "$1" =~ ^-(.*[^$PATTERN_SHORT]+.*|)$ ]]; then
		func-error "$1 is invalid as option"
	fi
	if [[ "$1" =~ ^-{2,} ]] && [[ ! "$1" =~ ^-{2}($PATTERN_LONG)$ ]]; then
		func-error "$1 is invalid as option"
	fi
}

func-parse() {
	O_ALL=false
	O_CONFIRM=false
	O_EMPTY=false
	O_LIST=false

	local PATTERN_SHORT="acel"
	local PATTERN_LONG="all|confirm|empty|list"

	while (($# > 0)); do
		case "$1" in
			-h | --help)
				func-usage
				;;
			-v | --version)
				func-version
				;;
			-*)
				func-validation "$1"

				if [[ "$1" =~ ^(-[^-]*a|--all$) ]]; then O_ALL=true; fi
				if [[ "$1" =~ ^(-[^-]*c|--confirm$) ]]; then O_CONFIRM=true; fi
				if [[ "$1" =~ ^(-[^-]*e|--empty$) ]]; then O_EMPTY=true; fi
				if [[ "$1" =~ ^(-[^-]*l|--list$) ]]; then O_LIST=true; fi

				shift
				;;
			*)
				((++argc))
				argv+=("$1")
				shift
				;;
		esac
	done
}

func-list() {
	local c='ls --color=auto'
	"${O_ALL}" && c="$c -A"
	"${O_LIST}" && c="$c -l"
	$c "$TRASH_FILES"
}

func-delete() {
	if "${O_CONFIRM}"; then
		read -r -p "total $(ls -A -U1 "$TRASH_FILES" | wc -l), Empties Trash? (y/N): " INPUT
		case "$INPUT" in
			y | Y | yes | Yes) ;;
			*) exit 0 ;;
		esac
	fi

	while IFS= read -r -d '' v; do
		sh -c "rm -rf '$v'"
		[ ! -d "$v" ] && mkdir "$v" && chown "$(logname):$(logname)" "$v"
	done < <(find "${TRASH_ROOT:?}/"* -maxdepth 0 -type d -print0)
}

func-move() {
	for v in "${argv[@]}"; do
		sh -c "mv -f '$v' $TRASH_FILES"
	done
}

func-main() {
	NAME=$(basename "$0")
	readonly NAME

	VERSION="v0.1"
	readonly VERSION

	local -i argc=0
	local -a argv=()

	func-parse "$@"

	# logname command does not change the user name
	# to root even if elevated privileges.
	# So use this instead of whoami, $HOME or $USER.
	TRASH_ROOT="/home/$(logname)/.local/share/Trash"
	readonly TRASH_ROOT

	TRASH_FILES="$TRASH_ROOT/files"
	readonly TRASH_FILES

	if [ "$argc" -gt 0 ]; then
		func-move
		exit "$?"
	fi

	"${O_LIST}" || "${O_ALL}" && func-list
	"${O_EMPTY}" || "${O_CONFIRM}" && func-delete
}

func-main "$@"