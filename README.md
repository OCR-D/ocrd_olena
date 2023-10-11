# ocrd_olena

> Binarize with Olena/scribo

[![CircleCI](https://circleci.com/gh/OCR-D/ocrd_olena.svg?style=svg)](https://circleci.com/gh/OCR-D/ocrd_olena)
[![Docker Automated build](https://img.shields.io/docker/automated/ocrd/core.svg)](https://hub.docker.com/r/ocrd/olena/tags/)

## Requirements

```
make deps-ubuntu
```

...will try to install the required packages on Ubuntu.

## Installation

```
make build-olena
```

...will download, patch and build Olena/scribo from source, and install locally (in VIRTUAL_ENV or in CWD/local).

```
make install
```

...will do that, but additionally install `ocrd-binarize-olena` (the OCR-D wrapper).

## Testing

```
make test
```

...will clone the assets repository from Github, make a workspace copy, and run checksum tests for binarization on them.

## Usage

This package has the following user interfaces:

### command line interface `scribo-cli`

Converts images in any format.

```
Usage: scribo-cli COMMAND [ARGS]

List of available COMMAND options:

  Full Toolchains
  ---------------


   * On documents

     doc-ppc	       Common preprocessing before looking for text.

     doc-ocr           Find and recognize text. Output: the actual text
     		       and its location.

     doc-dia           Analyse the document structure and extract the
     		       text. Output: an XML file with region and text
     		       information.



   * On pictures

     pic-loc           Try to localize text if there's any.

     pic-ocr           Localize and try to recognize text.



  Tools
  -----


     * xml2doc	       Convert the XML results of document toolchains
       		       into user documents (HTML, PDF...).


  Algorithms
  ----------


   * Binarization

     otsu              Otsu's (1979) global thresholding algorithm.

     niblack           Niblack's (1985) local thresholding algorithm.

     sauvola           Sauvola and Pietikainen's (2000) local/adpative algorithm.

     kim               Kim's (2004) algorithm.

     wolf              Wolf and Jolion's (2004) algorithm.

     sauvola-ms        Lazzara's (2013) multi-scale Sauvola algorithm.

     sauvola-ms-fg     Extract foreground objects and run multi-scale
                       Sauvola's algorithm.

     sauvola-ms-split  Run multi-scale Sauvola's algorithm on each color
                       component and merge results.

     singh             Singh's (2014) algorithm.


  Other
  -----

     version           Show version and exit

     help              Show this message and exit


For command arguments, see 'scribo-cli COMMAND --help' for more information
on each specific COMMAND.
```

For example:

```sh
scribo-cli sauvola-ms path/to/input.tif path/to/output.png --enable-negate-output
```

This can also be used with the general-purpose image preprocessing OCR-D wrapper [ocrd-preprocess-image](https://github.com/bertsky/ocrd_wrap#ocr-d-processor-interface-ocrd-preprocess-image) to get the power of Olena's binarization to all structural levels of the PAGE segment hierarchy. (See [this parameter preset](https://github.com/bertsky/ocrd_wrap/blob/master/ocrd_wrap/param_scribo-cli-binarize-sauvola-ms-split.json) for an usage example.)

### [OCR-D processor](https://ocr-d.de/en/spec/cli) interface `ocrd-olena-binarize`

To be used with [PageXML](https://github.com/PRImA-Research-Lab/PAGE-XML) documents in an [OCR-D](https://ocr-d.de) annotation workflow. Input could be any valid workspace with source images available. Currently covers the `Page` hierarchy level only. Uses either (the last) `AlternativeImage/@filename` (if any), or `Page/@imageFilename` (otherwise, cropping to `Border` if necessary). Adds an `AlternativeImage` with the result of binarization for every page.

```
Usage: ocrd-olena-binarize [OPTIONS]

  OLENA's binarization algos for OCR-D (on page-level)

Options:
  -I, --input-file-grp USE        File group(s) used as input
  -O, --output-file-grp USE       File group(s) used as output
  -g, --page-id ID                Physical page ID(s) to process
  --overwrite                     Remove existing output pages/images
                                  (with --page-id, remove only those)
  -p, --parameter JSON-PATH       Parameters, either verbatim JSON string
                                  or JSON file path
  -m, --mets URL-PATH             URL or file path of METS to process
  -w, --working-dir PATH          Working directory of local workspace
  -l, --log-level [OFF|ERROR|WARN|INFO|DEBUG|TRACE]
                                  Log level
  -J, --dump-json                 Dump tool description as JSON and exit
  -h, --help                      This help message
  -V, --version                   Show version

Parameters:
   "impl" [string - "sauvola-ms-split"]
    The name of the actual binarization algorithm
    Possible values: ["sauvola", "sauvola-ms", "sauvola-ms-fg", "sauvola-
    ms-split", "kim", "wolf", "niblack", "singh", "otsu"]
   "k" [number - 0.34]
    Sauvola's formulae parameter (foreground weight decreases with k);
    for Multiscale, multiplied to yield default 0.2/0.3/0.5; for Singh,
    multiplied to yield default 0.06; for Niblack, multiplied to yield
    default -0.2; for Wolf/Kim, used directly; for Otsu, does not apply
   "win-size" [number - 0]
    The (odd) window size in pixels; when zero (default), set to DPI; for
    Otsu, does not apply
   "dpi" [number - 0]
    pixel density in dots per inch (overrides any meta-data in the
    images); disabled when zero
```

## License

Copyright 2018-2023 Project OCR-D

ocrd_olena is released under the GNU General Public Licence.  See the file
``LICENSE`` (at the root of the source tree) for details.
