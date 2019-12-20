Change Log
==========
Versioned according to [Semantic Versioning](http://semver.org/).

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
[1.0.0]: ../../compare/v0.0.2...v1.0.0
[0.0.2]: ../../compare/HEAD...v0.0.2
