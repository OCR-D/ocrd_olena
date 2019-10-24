#/bin/bash

function errexit {
    echo >&2 "$1"
    exit $2
}

# delegate if Python futurize is not installed in our environment:
if which futurize &>/dev/null; then
    # behave like /usr/bin/install, i.e. expect parameters:
    # any number of files, followed by target directory
    target="${*:(-1)}"
    [ -d "$target" ] || errexit "Not a directory: '$target'" 1
    # on all but last parameter:
    for file in "${@:1:$#}"; do
        # ignore non-Python files:
        [[ "$file" != *.py ]] && continue
        # make compatible with Python 2/3, and copy to target:
        futurize --no-diffs -0wn -o "$target" "$file"
        chmod 644 "$target"/$(basename "$file")
    done
else
    install -c -m 644 "$@"
fi
