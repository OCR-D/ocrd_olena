#!/usr/bin/env bash
set -ex
export assets="$PWD/assets/data"
export workspace_dir="/tmp/test-ocrd-olena-binarize"

echo >&2 "Testing image input / PAGE+image output"

# Init workspace
rm -rf "$workspace_dir"
ocrd workspace -d "$workspace_dir" clone -a "$assets/scribo-test/data/mets.xml"

declare -a algos=(sauvola sauvola-ms-fg sauvola-ms sauvola-ms-split)
for algo in "${algos[@]}";do
    echo >&2 "# Generating $algo"
    ocrd-olena-binarize \
        -m "$workspace_dir"/mets.xml \
        -I OCR-D-IMG \
        -O "TEST-OCR-D-PRE-BIN-${algo^^}" \
        -P impl "$algo"
done

for algo in "${algos[@]}";do
    echo >&2 "# Comparing $algo images"
    if ! compare -metric mae \
        "$workspace_dir"/TEST-OCR-D-PRE-BIN-${algo^^}/*.png \
        "$assets"/scribo-test/data/OCR-D-PRE-BIN-${algo^^}/*.png \
        /dev/null; then
        echo "not ok - $algo: Images differ"
        false
    else
        echo "ok - $algo: Images Match"
    fi
    echo >&2 "# Checking $algo PAGE result"
    # roughly check output fileGrp and comments:
    if grep -q "AlternativeImage filename=\"TEST-OCR-D-PRE-BIN-${algo^^}/[^\"]*\" comments=\"binarized\"" "$workspace_dir"/TEST-OCR-D-PRE-BIN-${algo^^}/*.xml; then
        echo "ok - $algo: binarized AlternativeImage in PAGE result"
    else
        echo "not ok - $algo: no binarized AlternativeImage in PAGE result"
        false
    fi
done

echo >&2 "Testing PAGE+image input / PAGE+image output"

# Init workspace
rm -rf "$workspace_dir"
mkdir "$workspace_dir" # circumvent core#330
ocrd workspace -d "$workspace_dir" clone -a "$assets/kant_aufklaerung_1784/data/mets.xml"

declare -a algos=(sauvola wolf)
for algo in "${algos[@]}";do
    echo >&2 "# Generating $algo"
    ocrd-olena-binarize \
        -m "$workspace_dir"/mets.xml \
        -I OCR-D-GT-PAGE \
        -O "TEST-OCR-D-PRE-BIN-${algo^^}" \
        -P impl "$algo"
done

for algo in "${algos[@]}";do
    declare -A original_images binarized_images binarized_pages
    while read pageId local_filename; do
        original_images[$pageId]="$local_filename"
    done < <(ocrd workspace -d "$workspace_dir" find -G OCR-D-IMG -k pageId -k local_filename)
    while read pageId local_filename; do
        binarized_pages[$pageId]="$local_filename"
    done < <(ocrd workspace -d "$workspace_dir" find -G TEST-OCR-D-PRE-BIN-${algo^^} -m application/vnd.prima.page+xml -k pageId -k local_filename)
    for pageId in ${!original_images[@]}; do
        original_image=${original_images[$pageId]}
        binarized_page=${binarized_pages[$pageId]}
        echo >&2 "# Checking $algo PAGE result"
        binarized_image=$(sed -ne "s|^.*AlternativeImage filename=\"\(TEST-OCR-D-PRE-BIN-${algo^^}/[^\"]*\)\" comments=\"cropped,binarized\".*$|\1|p" "$workspace_dir/$binarized_page")
        if [ -n "$binarized_image" ]; then
            echo "ok - $algo $pageId: cropped,binarized AlternativeImage in PAGE result"
        else
            echo "not ok - $algo $pageId: no cropped,binarized AlternativeImage in PAGE result"
            false
        fi
        echo >&2 "# Checking $algo image pixel size"
        original_info=($(identify "$workspace_dir/$original_image"))
        binarized_info=($(identify "$workspace_dir/$binarized_image"))
        original_geometry=${original_info[2]}
        binarized_geometry=${binarized_info[2]}
        original_width=${original_geometry%x*}
        original_height=${original_geometry#*x}
        binarized_width=${binarized_geometry%x*}
        binarized_height=${binarized_geometry#*x}
        if [ $original_width -gt $binarized_width -a $original_height -gt $binarized_height ];then
            echo "ok - $algo $pageId: Cropped $original_geometry to $binarized_geometry"
        else
            echo "not ok - $algo $pageId: Expected $original_geometry larger than $binarized_geometry"
            false
        fi
    done
done
