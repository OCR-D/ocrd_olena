# ocrd_olena

> Bundle olena as an OCR-D tool

[![Build Status](https://travis-ci.org/OCR-D/ocrd_olena.svg?branch=master)](https://travis-ci.org/OCR-D/ocrd_olena)

## Requirements

```
make deps-ubuntu
```

...will try to install the required packages on Ubuntu.

## Installation

```
make install
```

...will download, patch and build olena/scribo from source, and install locally (in a path relative to the CWD).

## Testing

```
make test
```

...will clone the assets repository from Github, make a workspace copy, and run checksum tests for binarization on them.

## Usage

This package has the following user interfaces:

### [OCR-D processor](https://github.com/OCR-D/core) interface `ocrd-olena-binarize`

To be used with [PageXML](https://www.primaresearch.org/tools/PAGELibraries) documents in an [OCR-D](https://github.com/OCR-D/spec/) annotation workflow. Input could be any valid workspace with source images available. Currently covers the `Page` hierarchy level only. Uses either (the last) `AlternativeImage`, if any, or `imageFilename`, otherwise. Adds an `AlternativeImage` with the result of binarization for every page.

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
          "description": "Sauvola's formulae parameter",
          "format": "float",
          "type": "number",
          "default": 0.34
        }
      }
    }
```
