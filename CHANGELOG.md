Change Log
==========
Versioned according to [Semantic Versioning](http://semver.org/).

## Unreleased

## [1.3.0] - 2022-05-19

Changed:

  * Reduce `winsize` for non-Sauvola algorithms, #84, #85
  * Accumulate files to be added to the mets and use `ocrd workspace bulk-add`, #77, #85
  * Properly support METS not-named `mets.xml`

## [1.2.6] - 2021-12-08

Changed:

  - only mkdir output_file_grp if needed
  - simplify file iterator by delegating to bashlib input-files

## [1.2.5] - 2021-11-11

Changed:

   - on `make install`, check for existing `scribo-cli` in PATH
   - differentiate `make install` vs `make install-tools`

## [1.2.4] - 2021-09-22

Fixed:

   - Docker: skip autoremove (which kills needed rtlibs)

## [1.2.3] - 2020-10-13

Fixed:

   - pass correct `k` value for `niblack`
   - always build against ImageMagick 6 (not 7)
   
Changed:

   - also crop AlternativeImage to page border if not already
   - remove temporary images from cropping afterwards
   - use updated `ocrd workspace` CLI for tests
ocrd-olena-binarize: 
## [1.2.2] - 2020-09-30

Fixed:

   - typo in 1.2.1 error

## [1.2.1] - 2020-08-21

Fixed:

   - images may be mixed with PAGE-XML in `input_file_grp`, OCR-D/core#505 OCR-D/spec#164
   - `make install`: update pip and ocrd
   - CI setup

## [1.2.0] - 2020-07-31

Changed:

  - use `sauvola-ms-split` as default `impl` (method)
  - default to `win-size=0` which now equals odd DPI value of image
  - set `pcGtsId` in PAGE-XML, ht @mikegerber, #63
  - images are written to the same `output_file_grp` as the PAGE-XML, OCR-D/core#505

Added:

 - parameter `dpi` to override image meta-data DPI


## [1.1.10] - 2020-06-17

Changed:

  - Use `ocrd log` for logging
  - Implement `--overwrite`

## [1.1.9] - 2020-06-12

Fixed:

  * Check whether ImageMagick/GraphicsMagick and Boost are installed before compilation, #53

## [1.1.8] - 2020-06-12

Fixed:

  * Use explicit `-format` in `identify` call, #57

## [1.1.7] - 2020-05-27

Fixed:

  * Use install-time Python binary when needed

Changed:

  * Ignore `Page/PrintSpace` (as opposed to `Page/Border`)

## [1.1.6] - 2020-04-22

Fixed:

  * Quote all arguments in `scribo-cli` to allow file names with whitespace
  * Pass on different `k` values at each scale for `sauvola-ms*`

Changed:

  * Skip `AlternativeImage/@comments=binarized` in PAGE input
  * Update `repo/olena` to upstream master
  * Update `repo/assets` to upstream master

## [1.1.5] - 2020-03-19

Fixed:

  * ignore/pass `file://` prefixes in absolute pathnames
  * disable Qt when building Olena

## [1.1.4] - 2020-03-06

Changed:

  * Update `repo/olena` to upstream master
  * Update `repo/assets` to upstream master

Fixed:

  * ignore/pass `file://` prefixes in absolute pathnames
  * compensate for different `k` defaults for singh/niblack `impl`
  * pass on correct `k` values for sauvola-ms-{fg,split} `impl`

## [1.1.3] - 2019-02-25

Changed:

  * Update `repo/olena` to most recent upstream
  * `make build-olena` configured not to build documentation

## 1.1.2

  * Use bash from env instead of fixed shebang
  * Ensure minimum bash version

## 1.1.1

Changed:

  * Update olena upstream repo to include gitignore rules
  * Ensure ocrd-tool.json is reinstalled if changed, #26

## 1.1.0

Changed:

  * Remove the patches and use patched OCR-D fork as git submodule
  * Deployment to DockerHub as `ocrd/all:minimum`, `ocrd/all:medium`, `ocrd/all:maximum`

## 1.0.0

Fixed:

  * add namespace prefix to MetadataItem/Label(s), if any
  * use proper logging format, delegate to bashlib constants
  * pass input parameters to algorithms
  * respect -g option (page_id)
  * when AlternativeImage exists already, append after last
  * date: Use explicit formatting for iso8601 compliant date w/o TZ  (kba/fix-created-date)
  * much improved olena build process

Changed
  * negate and convert output images in scribo itself (without extra ImageMagick CLI)
  * improved docker support, 2 docker builds: pure scribo and OCR-D binarization wrapper
  * overwrite image file IDs if necessary  (bertsky/add-imagefile-force)

## 0.0.2

First release

<!-- link-labels -->
[1.3.0]: ../../compare/v1.2.6...v1.3.0
[1.2.6]: ../../compare/v1.2.5...v1.2.6
[1.2.5]: ../../compare/v1.2.4...v1.2.5
[1.2.4]: ../../compare/v1.2.3...v1.2.4
[1.2.3]: ../../compare/v1.2.2...v1.2.3
[1.2.2]: ../../compare/v1.2.1...v1.2.2
[1.2.1]: ../../compare/v1.2.0...v1.2.1
[1.2.0]: ../../compare/v1.1.10...v1.2.0
[1.1.10]: ../../compare/v1.1.9...v1.1.10
[1.1.9]: ../../compare/v1.1.8...v1.1.9
[1.1.8]: ../../compare/v1.1.7...v1.1.8
[1.1.7]: ../../compare/v1.1.6...v1.1.7
[1.1.6]: ../../compare/v1.1.5...v1.1.6
[1.1.5]: ../../compare/v1.1.4...v1.1.5
[1.1.4]: ../../compare/v1.1.3...v1.1.4
[1.1.3]: ../../compare/v1.1.2...v1.1.3
[1.1.2]: ../../compare/v1.1.1...v1.1.2
[1.1.1]: ../../compare/v1.1.0...v1.1.1
[1.1.0]: ../../compare/v1.0.0...v1.1.0
[1.0.0]: ../../compare/v0.0.2...v1.0.0
[0.0.2]: ../../compare/HEAD...v0.0.2
