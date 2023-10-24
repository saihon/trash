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

# set -eux

NAME=$(basename "$0")
readonly NAME

readonly VERSION="v0.0.3"

readonly TRASH_ROOT="/home/$USER/.local/share/Trash"
readonly TRASH_FILES="$TRASH_ROOT/files"

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

    readonly PATTERN_SHORT="acel"
    readonly PATTERN_LONG="all|confirm|empty|list"

    while (($# > 0)); do
        case "$1" in
        -h | --help)
            printf "\nUsage: %s [options] [files or directories]\n" "$NAME"
            printf "\nOptions:\n"
            printf "  -a, --all     Show all items in Trash including hidden.\n"
            printf "  -e, --empty   Permanently delete items in Trash.\n"
            printf "  -c, --confirm Prompt before remove items in Trash.\n"
            printf "  -l, --list    Show items in the Trash in long format.\n"
            printf "  -h, --help    Display this help and exit.\n"
            printf "  -v, --version Output version information and exit.\n"
            exit 0
            ;;
        -v | --version)
            echo "$NAME: $VERSION"
            exit 0
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
    local c='ls'
    "${O_ALL}" && c="$c -A"
    "${O_LIST}" && c="$c -l"
    command $c --color=auto "$TRASH_FILES"
}

func-remove() {
    if "${O_CONFIRM}"; then
        read -r -p "Items $(ls -A -U1 "$TRASH_FILES" | wc -l), Empty the trash? (y/N): " INPUT
        case "$INPUT" in
        y | Y | yes | Yes) ;;
        *) exit 0 ;;
        esac
    fi

    local v
    while IFS= read -r -d '' v; do
        local err
        if ! err="$(rm -rf "$v" 2>&1 >/dev/null)"; then
            if [[ "$err" == *'Permission denied'* ]]; then
                sudo rm -rf "$v"
            else
                echo "$err"
            fi
        fi
        [ ! -d "$v" ] && mkdir "$v"
    done < <(find "${TRASH_ROOT:?}/"* -maxdepth 0 -type d -print0)
}

func-move() {
    for v in "${argv[@]}"; do
        # Trim trailing slash
        v=${v%/}

        # Basename
        local name=${v##*/}

        # Avoid the same name.
        local suffix=''
        local -i i=1
        while [ -e "${TRASH_FILES}/${name}${suffix}" ]; do
            suffix=".${i}"
            ((i++))
        done

        local err
        if ! err="$(mv -f "$v" "${TRASH_FILES}/${name}${suffix}" 2>&1 >/dev/null)"; then
            if [[ "$err" == *'Permission denied'* ]]; then
                sudo mv -f "$v" "${TRASH_FILES}/${name}${suffix}"
            else
                echo "$err"
            fi
        fi
    done
}

func-main() {
    local -i argc=0
    local -a argv=()

    func-parse "$@"

    if [ "$argc" -gt 0 ]; then
        func-move
        exit $?
    fi
    if "${O_LIST}" || "${O_ALL}"; then
        func-list
    fi
    if "${O_EMPTY}" || "${O_CONFIRM}"; then
        func-remove
    fi
    exit $?
}

func-main "$@"
