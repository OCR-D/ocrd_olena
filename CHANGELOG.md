Change Log
==========
Versioned according to [Semantic Versioning](http://semver.org/).

## Unreleased

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
[1.1.1]: ../../compare/v1.1.0...v1.1.1
[1.1.0]: ../../compare/v1.0.0...v1.1.0
[1.0.0]: ../../compare/v0.0.2...v1.0.0
[0.0.2]: ../../compare/HEAD...v0.0.2
