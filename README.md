# ocrd_olena

> Binarize with Olena/scribo

[![Build Status](https://travis-ci.org/OCR-D/ocrd_olena.svg?branch=master)](https://travis-ci.org/OCR-D/ocrd_olena)
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

### [OCR-D processor](https://ocr-d.github.com/cli) interface `ocrd-olena-binarize`

To be used with [PageXML](https://github.com/PRImA-Research-Lab/PAGE-XML) documents in an [OCR-D](https://ocr-d.github.io) annotation workflow. Input could be any valid workspace with source images available. Currently covers the `Page` hierarchy level only. Uses either (the last) `AlternativeImage`, if any, or `imageFilename`, otherwise. Adds an `AlternativeImage` with the result of binarization for every page.

```json
    "ocrd-olena-binarize": {
      "executable": "ocrd-olena-binarize",
      "description": "OLENA's binarization algos for OCR-D (on page-level)",
      "categories": [
        "Image preprocessing"
      ],
      "steps": [
        "preprocessing/optimization/binarization"
      ],
      "input_file_grp": [
        "OCR-D-SEG-BLOCK",
        "OCR-D-SEG-LINE",
        "OCR-D-SEG-WORD",
        "OCR-D-IMG"
      ],
      "output_file_grp": [
        "OCR-D-SEG-BLOCK",
        "OCR-D-SEG-LINE",
        "OCR-D-SEG-WORD"
      ],
      "parameters": {
        "impl": {
          "description": "The name of the actual binarization algorithm",
          "type": "string",
          "required": true,
          "enum": ["sauvola", "sauvola-ms", "sauvola-ms-fg", "sauvola-ms-split", "kim", "wolf", "niblack", "singh", "otsu"]
        },
        "win-size": {
          "description": "Window size",
          "type": "number",
          "format": "integer",
          "default": 101
        },
        "k": {
          "description": "Sauvola's formulae parameter (foreground weight decreases with k); for Multiscale, multiplied to yield default 0.2/0.3/0.5; for Singh, multiplied to yield default 0.06; for Niblack, multiplied to yield default -0.2; for Wolf/Kim, used directly; for Otsu, does not apply",
          "format": "float",
          "type": "number",
          "default": 0.34
        }
      }
    }
```

## License

Copyright 2018-2020 Project OCR-D

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
