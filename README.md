# ocrd_olena

> Binarize with Olena/scribo

[![CircleCI](https://circleci.com/gh/OCR-D/ocrd_olena.svg?style=svg)](https://circleci.com/gh/OCR-D/ocrd_olena)
[![Docker Automated build](https://img.shields.io/docker/automated/ocrd/core.svg)](https://hub.docker.com/r/ocrd/olena/tags/)

## Requirements

    make deps-ubuntu

...will try to install the required packages on Ubuntu.

## Installation

    make build-olena

...will download, patch and build Olena/scribo from source,
and install its standalone CLI `scribo-cli` (see [below](#command-line-interface-scribo-cli))
locally (in `$VIRTUAL_ENV` or in `$PREFIX` if given).

    make install

...will run `build-olena`, if necessary, and install the Python
package `ocrd_olena` with the [OCR-D](https://ocr-d.de) [CLI](https://ocr-d.de/en/spec/cli)
`ocrd-binarize-olena` (see [below](#ocr-d-processor-interface-ocrd-olena-binarize)).

## Testing

    make test

...will clone the assets repository from Github, make a workspace copy, and run checksum tests
for binarization on them.

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

    scribo-cli sauvola-ms path/to/input.tif path/to/output.png --enable-negate-output

This can also be used with the general-purpose image preprocessing OCR-D wrapper [ocrd-preprocess-image](https://github.com/bertsky/ocrd_wrap#ocr-d-processor-interface-ocrd-preprocess-image) to get the power of Olena's binarization to all structural levels of the PAGE segment hierarchy. (See [this parameter preset](https://github.com/bertsky/ocrd_wrap/blob/master/ocrd_wrap/param_scribo-cli-binarize-sauvola-ms-split.json) for an usage example.)

### [OCR-D processor](https://ocr-d.de/en/spec/cli) interface `ocrd-olena-binarize`

To be used with [PageXML](https://github.com/PRImA-Research-Lab/PAGE-XML) documents in
an [OCR-D](https://ocr-d.de) annotation workflow. Input could be any valid workspace
with source images available. Covers PAGE hierarchy levels `page`, `table`, `region` and
`line`.

Uses either (the last) `AlternativeImage/@filename` (if any), or `Page/@imageFilename`
(otherwise, cropping to `Border` if necessary). Adds an `AlternativeImage` with the
result of binarization for every segment.

```
Usage: ocrd-olena-binarize [worker|server] [OPTIONS]

  popular binarization algorithms implemented by Olena/SCRIBO, wrapped for OCR-D (on page level only)

  > binarization with Scribo from Olena suite

  > For each page, open and deserialize PAGE input file (from existing
  > PAGE file in the input fileGrp, or generated from image file).
  > Retrieve its respective image  at the requested `level-of-operation`
  > (ignoring annotation that already added `binarized`).

  > Passes the image file to the Olena suite's scribo binarization
  > program for the selected algorithm `impl` and its parameters.

  > If binarization returns with a failure, skip that segment with an
  > approriate error message. Otherwise, put the resulting PNG image
  > file into the output fileGrp, and reference it in the METS using a
  > file ID with suffix ``.IMG-BIN``. Reference it as AlternativeImage
  > in the page, adding ``binarized`` to its @comments.

  > Produce a new PAGE output file by serialising the resulting
  > hierarchy.

Subcommands:
    worker      Start a processing worker rather than do local processing
    server      Start a processor server rather than do local processing

Options for processing:
  -m, --mets URL-PATH             URL or file path of METS to process [./mets.xml]
  -w, --working-dir PATH          Working directory of local workspace [dirname(URL-PATH)]
  -I, --input-file-grp USE        File group(s) used as input
  -O, --output-file-grp USE       File group(s) used as output
  -g, --page-id ID                Physical page ID(s) to process instead of full document []
  --overwrite                     Remove existing output pages/images
                                  (with "--page-id", remove only those).
                                  Short-hand for OCRD_EXISTING_OUTPUT=OVERWRITE
  --debug                         Abort on any errors with full stack trace.
                                  Short-hand for OCRD_MISSING_OUTPUT=ABORT
  --profile                       Enable profiling
  --profile-file PROF-PATH        Write cProfile stats to PROF-PATH. Implies "--profile"
  -p, --parameter JSON-PATH       Parameters, either verbatim JSON string
                                  or JSON file path
  -P, --param-override KEY VAL    Override a single JSON object key-value pair,
                                  taking precedence over --parameter
  -U, --mets-server-url URL       URL of a METS Server for parallel incremental access to METS
                                  If URL starts with http:// start an HTTP server there,
                                  otherwise URL is a path to an on-demand-created unix socket
  -l, --log-level [OFF|ERROR|WARN|INFO|DEBUG|TRACE]
                                  Override log level globally [INFO]
  --log-filename LOG-PATH         File to redirect stderr logging to (overriding ocrd_logging.conf).

Options for information:
  -C, --show-resource RESNAME     Dump the content of processor resource RESNAME
  -L, --list-resources            List names of processor resources
  -J, --dump-json                 Dump tool description as JSON
  -D, --dump-module-dir           Show the 'module' resource location path for this processor
  -h, --help                      Show this message
  -V, --version                   Show version

Parameters:
   "level-of-operation" [string - "page"]
    PAGE XML segment hierarchy level to annotate images for
    Possible values: ["page", "table", "region", "line"]
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
    The (odd) window size in pixels; when zero (default), set to DPI (or
    301); for Otsu, does not apply
   "dpi" [number - 0]
    pixel density in dots per inch (overrides any meta-data in the
    images); disabled when zero
```

## License

Copyright 2018-2023 Project OCR-D

ocrd_olena is released under the GNU General Public Licence.  See the file
``LICENSE`` (at the root of the source tree) for details.
