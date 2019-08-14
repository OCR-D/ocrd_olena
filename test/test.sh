#!/bin/bash
set -e
export PATH="$PWD/..:$PWD/../local/bin:$PATH"
export assets="$PWD/assets"
export workspace_dir="/tmp/test-ocrd-olena-binarize"

# Init workspace
rm -rf "$workspace_dir"
ocrd workspace clone -a "$assets/scribo-test/data/mets.xml" "$workspace_dir"
cp -rt "$workspace_dir" "$assets/scribo-test/data/OCR-D-IMG" 

declare -a algos=(sauvola sauvola-ms-fg sauvola-ms sauvola-ms-split)
for algo in "${algos[@]}";do
    echo >&2 "# Generating $algo"
    ocrd-olena-binarize \
        -m "$workspace_dir"/mets.xml \
        -I OCR-D-IMG \
        -O "OCR-D-SEG-NONE-${algo},OCR-D-IMG-BIN-${algo}" \
        -p <(echo '{"impl": "'$algo'"}')
done

for algo in "${algos[@]}";do
    echo >&2 "# Diffing $algo"
    should=$(wc -c "$workspace_dir"/OCR-D-IMG-BIN-${algo}/*.png | grep -o '^[0-9]*')
    actual=$(wc -c "$assets"/scribo-test/data/OCR-D-IMG-BIN-${algo^^}/* | grep -o '^[0-9]*')
    if [[ $should != $actual ]];then
        echo "not ok - $algo: Expected $should but is $actual"
    else
        echo "ok - $algo: Matches $should == $actual"
    fi
done
