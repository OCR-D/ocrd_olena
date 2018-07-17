#!/bin/bash
export PATH="$PWD/..:$PWD/../local/bin:$PATH"
export assets="$PWD/assets"
export workspace_dir="/tmp/test-ocrd-olena-binarize"

# Init workspace
rm -rf "$workspace_dir"
ocrd workspace init "$workspace_dir"
ocrd workspace -d "$workspace_dir" add -G OCR-D-IMG -i orig -m image/png "$assets/scribo-test/orig.png"

declare -a algos=(sauvola sauvola-ms-fg sauvola-ms sauvola-ms-split)
for algo in "${algos[@]}";do
    echo >&2 "# Generating $algo"
    ocrd-olena-binarize \
        -m "$workspace_dir"/mets.xml \
        -I OCR-D-IMG \
        -O "OCR-D-IMG-BIN-${algo}" \
        -p <(echo '{"impl": "'$algo'"}')
done

for algo in "${algos[@]}";do
    echo >&2 "# Diffing $algo"
    should=$(wc -c "$workspace_dir"/*/*$algo.png | grep -o '^[0-9]*')
    actual=$(wc -c "$assets/scribo-test/orig.${algo}.png" | grep -o '^[0-9]*')
    if [[ $should != $actual ]];then
        echo "not ok - $algo: Expected $should but is $actual"
    else
        echo "ok - $algo: Matches $should == $actual"
    fi
done
