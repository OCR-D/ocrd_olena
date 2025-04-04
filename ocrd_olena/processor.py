from __future__ import absolute_import

from typing import Optional
from tempfile import TemporaryDirectory
from PIL import Image
import os
import subprocess


from ocrd import Processor, OcrdPageResult, OcrdPageResultImage
from ocrd_models.ocrd_page import (
    AlternativeImageType,
    PageType,
    OcrdPage,
)

class ScriboProcessor(Processor):

    @property
    def executable(self):
        return 'ocrd-olena-binarize'

    def process_page_pcgts(self, *input_pcgts: Optional[OcrdPage], page_id: Optional[str] = None) -> OcrdPageResult:
        """
        binarization with Scribo from Olena suite

        For each page, open and deserialize PAGE input file (from existing
        PAGE file in the input fileGrp, or generated from image file).
        Retrieve its respective image at the requested `level-of-operation`
        (ignoring annotation that already added `binarized`).

        Passes the image file to the Olena suite's scribo binarization program
        for the selected algorithm `impl` and its parameters.

        If binarization returns with a failure, skip that segment with an
        approriate error message. Otherwise, put the resulting PNG image file
        into the output fileGrp, and reference it in the METS using a file ID
        with suffix ``.IMG-BIN``. Reference it as AlternativeImage in the page,
        adding ``binarized`` to its @comments.

        Produce a new PAGE output file by serialising the resulting hierarchy.
        """
        pcgts = input_pcgts[0]
        result = OcrdPageResult(pcgts)
        oplevel = self.parameter['level-of-operation']
        page = pcgts.get_Page()
        page_image, page_coords, page_image_info = self.workspace.image_from_page(
            page, page_id, feature_filter='binarized')
        if self.parameter['dpi'] > 0:
            dpi = self.parameter['dpi']
            self.logger.info("Page '%s' images will use %d DPI from parameter override", page_id, dpi)
        elif page_image_info.resolution != 1:
            dpi = page_image_info.resolution
            if page_image_info.resolutionUnit == 'cm':
                dpi = round(dpi * 2.54)
            self.logger.info("Page '%s' images will use %d DPI from image meta-data", page_id, dpi)
        else:
            dpi = 300
            self.logger.info("Page '%s' images will use 300 DPI from fall-back", page_id)

        if oplevel == 'page':
            try:
                result.images.append(
                    self._process_segment(
                        page, page_image, page_coords, "page '%s'" % page_id, dpi=dpi))
            except Exception:
                    raise
            return result

        regions = page.get_AllRegions(classes=['Table' if oplevel == 'table' else 'Text'])
        if not regions:
            self.logger.warning("Page '%s' contains no %s regions", page_id,
                                "table" if oplevel == "table" else "text")
        for region in regions:
            region_image, region_coords = self.workspace.image_from_segment(
                region, page_image, page_coords, feature_filter='binarized')
            if oplevel in ['region', 'table']:
                try:
                    result.images.append(
                        self._process_segment(
                            region, region_image, region_coords, oplevel + " '%s'" % segment.id, dpi=dpi))
                except Exception:
                    self.logger.exception("skipping " + oplevel + " '%s'" % region.id)
                continue

            lines = region.get_TextLine()
            if not lines:
                self.logger.warning("Region '%s' contains no text lines", region.id)
            for line in lines:
                line_image, line_coords = self.workspace.image_from_segment(
                    line, region_image, region_coords, feature_filter='binarized')
                if oplevel == 'line':
                    try:
                        result.images.append(
                            self._process_segment(line, line_image, line_coords, oplevel + " '%s'" % line.id, dpi=dpi))
                    except Exception:
                        self.logger.exception("skipping " + oplevel + " '%s'" % line.id)
                    continue

        return result


    def _process_segment(self, segment, image, coords, where, dpi=300) -> Optional[OcrdPageResultImage]:
        features = coords['features'] or '' # features already applied to image
        if features:
            features += ','
        features += 'binarized'
        with TemporaryDirectory(suffix=segment.id) as tmpdir:
            in_path = os.path.join(tmpdir, "in.png")
            out_path = os.path.join(tmpdir, "out.png")
            # save retrieved segment image to temporary file
            with open(in_path, 'wb') as in_file:
                image.save(in_file, format='PNG')
            # choose algorithm command
            scribo_options = [
                self.parameter['impl'],
                in_path, out_path,
                '--enable-negate-output'
            ]
            # normalize threshold parameter
            if self.parameter['impl'] == 'otsu':
                pass # has no options whatsoever
            elif self.parameter['impl'] == 'niblack':
                scribo_options.append('--disable-negate-input')
                # has default -0.2 not 0.34
                scribo_options.extend(['--k', str(self.parameter['k'] / -1.7)])
            elif self.parameter['impl'] in ['sauvola', 'kim', 'wolf']:
                scribo_options.extend(['--k', str(self.parameter['k'])])
            elif self.parameter['impl'] == 'singh':
                # has default 0.06 not 0.34
                scribo_options.extend(['--k', str(self.parameter['k'] * 0.1765)])
            elif self.parameter['impl'].startswith('sauvola-ms'):
                scribo_options.extend(['--k2', str(self.parameter['k'] / 0.34 * 0.2),
                                       '--k3', str(self.parameter['k'] / 0.34 * 0.3),
                                       '--k4', str(self.parameter['k'] / 0.34 * 0.5)])
            if self.parameter['impl'] != 'otsu':
                if self.parameter['win-size']:
                    # manual choice
                    size = self.parameter['win-size']
                else:
                    # auto-detect window size via DPI (and rule of thumb)
                    if self.parameter['impl'].startswith('sauvola'):
                        size = dpi
                    else:
                        size = dpi / 6
                    # Convert to odd integer
                    size = int(size) + int((size + 1) % 2)
                    self.logger.debug("Using %d DPI-derived window size %d for %s", dpi, size, where)
                scribo_options.extend(['--win-size', str(size)])
            # execute command pattern
            args = ['scribo-cli'] + scribo_options
            self.logger.debug("Running command: '%s'", str(args))
            # pylint: disable=subprocess-run-check
            result = subprocess.run(args, shell=False, text=True, capture_output=True, encoding="utf-8")
            if result.stdout:
                self.logger.debug("scribo-cli for %s stdout: %s", where, result.stdout)
            if result.stderr:
                self.logger.warning("scribo-cli for %s stderr: %s", where, result.stderr)
            if result.returncode != 0:
                self.logger.error("Command for %s failed: ", where)
                raise Exception(result)
            with Image.open(out_path) as image2:
                # check resulting image
                if image.size != image2.size:
                    self.logger.error("scribo-cli for %s produced image of different size (%s vs %s)",
                                      where, str(image.size), str(image2.size))
                    raise Exception(result)
                # update PAGE (reference the image file):
                image_ref = AlternativeImageType(comments=features)
                segment.add_AlternativeImage(image_ref)
                suffix = '' if isinstance(segment, PageType) else segment.id
                suffix += '.IMG-BIN'
                return OcrdPageResultImage(image2.copy(), suffix, image_ref)
