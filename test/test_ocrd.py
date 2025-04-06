# pylint: disable=import-error

import os
import json
import logging
from PIL import Image
import numpy as np
import pytest
import subprocess

from ocrd import run_processor
from ocrd_utils import MIMETYPE_PAGE, config
from ocrd_models.constants import NAMESPACES as NS
from ocrd_modelfactory import page_from_file

from ocrd_olena.processor import ScriboProcessor

def test_image(processor_kwargs, subtests, caplog):
    caplog.set_level(logging.INFO)
    def only_scribo(logrec):
        return logrec.name == 'ocrd.processor.ScriboProcessor'
    ws = processor_kwargs['workspace']
    page_id = processor_kwargs['page_id']
    if ws.name != 'scribo-test':
        pytest.skip() # only for test_pagexml
    pages = page_id.split(',')
    def page_order(file_):
        return pages.index(file_.pageId)
    page1 = pages[0]
    input_file_grp = 'OCR-D-IMG'
    for algo in ["sauvola", "sauvola-ms-fg", "sauvola-ms", "sauvola-ms-split"]:
        output_file_grp = "TEST-OCR-D-PRE-BIN-%s" % algo.upper()
        # get input files in order of pages
        inputs = list(sorted(ws.find_files(file_grp=input_file_grp,
                                           mimetype="//^image/.*",
                                           page_id=page_id),
                             key=page_order))
        with subtests.test(
                msg="on image input",
                algorithm=algo):
            with caplog.filtering(only_scribo):
                run_processor(
                    ScriboProcessor,
                    input_file_grp=input_file_grp,
                    output_file_grp=output_file_grp,
                    parameter={"impl": algo},
                    **processor_kwargs,
                )
            for logrec in caplog.records:
                assert logrec.levelno <= logging.INFO
            caplog.clear()
            ws.save_mets()
            assert os.path.isdir(os.path.join(ws.directory, output_file_grp))
            results = list(sorted(ws.find_files(file_grp=output_file_grp,
                                                mimetype=MIMETYPE_PAGE,
                                                page_id=page_id),
                                  key=page_order))
            assert len(results), "found no output PAGE files"
            assert len(results) == len(pages)
            # results are in TEST-OCR-D-PRE-BIN-...
            # ref images are in OCR-D-PRE-BIN-...
            references = list(sorted(ws.find_files(file_grp=output_file_grp[5:],
                                                   mimetype="//^image/.*",
                                                   page_id=page_id),
                                     key=page_order))
            assert len(references) == len(pages)
            for input_, result, reference in zip(inputs, results, references):
                assert os.path.exists(result.local_filename), "PAGE result not found in filesystem"
                result_tree = page_from_file(result).etree
                org_filename = input_.local_filename
                ref_filename = reference.local_filename
                bin_image = result_tree.xpath(
                    "//page:Page/page:AlternativeImage[@comments='binarized']", namespaces=NS)
                assert len(bin_image), "no AlternativeImage annotated in PAGE result"
                bin_filename = bin_image[0].get('filename')
                assert os.path.exists(bin_filename), "image result not found in filesystem"
                assert any(ws.find_files(file_grp=output_file_grp,
                                         mimetype='//^image/.*',
                                         page_id=result.pageId,
                                         local_filename=bin_filename)), "image result not referenced in METS"
                with Image.open(org_filename) as org_img:
                    org_size = org_img.size
                with Image.open(bin_filename) as bin_img:
                    bin_size = bin_img.size
                assert org_size == bin_size
                # compare images to precomputed reference images
                args = ["compare", "-metric", "mae"]
                args.append(bin_filename)
                args.append(ref_filename)
                args.append("/dev/null") # do not generate diff image
                compare = subprocess.run(args, shell=False, text=True, capture_output=True, encoding="utf-8")
                if compare.stdout:
                   print(compare.stdout)
                if compare.stderr:
                    print(compare.stderr)
                assert compare.returncode == 0, "images differ"


def test_pagexml(processor_kwargs, subtests, caplog):
    caplog.set_level(logging.INFO)
    def only_scribo(logrec):
        return logrec.name == 'ocrd.processor.ScriboProcessor'
    ws = processor_kwargs['workspace']
    page_id = processor_kwargs['page_id']
    if ws.name == 'scribo-test':
        pytest.skip() # only for test_image
    pages = page_id.split(',')
    def page_order(file_):
        return pages.index(file_.pageId)
    page1 = pages[0]
    input_file_grp = 'OCR-D-GT-PAGE'
    for algo in ["sauvola", "sauvola-ms-split", "wolf", "singh"]:
        output_file_grp = "TEST-OCR-D-PRE-BIN-%s" % algo.upper()
        for level in ["page", "region", "line"]:
            config.OCRD_EXISTING_OUTPUT = 'OVERWRITE'
            # get input files in order of pages
            inputs = list(sorted(ws.find_files(file_grp=input_file_grp,
                                               mimetype=MIMETYPE_PAGE,
                                               page_id=page_id),
                                 key=page_order))
            with subtests.test(
                    msg="on PAGE input",
                    oplevel=level,
                    algorithm=algo):
                with caplog.filtering(only_scribo):
                    run_processor(
                        ScriboProcessor,
                        input_file_grp=input_file_grp,
                        output_file_grp=output_file_grp,
                        parameter={"impl": algo,
                                   "level-of-operation": level},
                        **processor_kwargs,
                    )
                for logrec in caplog.records:
                    assert logrec.levelno <= logging.INFO
                caplog.clear()
                ws.save_mets()
                assert os.path.isdir(os.path.join(ws.directory, output_file_grp))
                results = list(sorted(ws.find_files(file_grp=output_file_grp,
                                                    mimetype=MIMETYPE_PAGE,
                                                    page_id=page_id),
                                      key=page_order))
                assert len(results), "found no output PAGE files"
                assert len(results) == len(pages)
                for input_, result in zip(inputs, results):
                    assert os.path.exists(result.local_filename), "PAGE result not found in filesystem"
                    input__tree = page_from_file(input_).etree
                    result_tree = page_from_file(result).etree
                    if level == 'page':
                        org_image = input__tree.xpath("//page:Page", namespaces=NS)
                        org_filename = org_image[0].get('imageFilename')
                        bin_image = result_tree.xpath(
                            "//page:Page/page:AlternativeImage[contains(@comments,'cropped,binarized')]", namespaces=NS)
                        assert len(bin_image), "no AlternativeImage annotated in PAGE result"
                        bin_filename = bin_image[0].get('filename')
                        assert os.path.exists(bin_filename), "image result not found in filesystem"
                        assert any(ws.find_files(file_grp=output_file_grp,
                                                 mimetype='//^image/.*',
                                                 page_id=result.pageId,
                                                 local_filename=bin_filename)), "image result not referenced in METS"
                        # do not compare image sizes (GT contains Border, so image will be cropped, anyway)
                        continue
                    if level == 'region':
                        elem = "page:TextRegion"
                    elif level == 'line':
                        elem = "page:TextLine"
                    bin_images = result_tree.xpath(
                        "//%s/page:AlternativeImage[@comments='binarized']" % elem, namespaces=NS)
                    assert len(bin_images) > 0
                    for bin_image in bin_images:
                        bin_filename = bin_image.get('filename')
                        assert os.path.exists(bin_filename), "image result not found in filesystem"
                        assert any(ws.find_files(file_grp=output_file_grp,
                                                 mimetype='//^image/.*',
                                                 page_id=result.pageId,
                                                 local_filename=bin_filename)), "image result not referenced in METS"

