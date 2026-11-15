import json
import tempfile
import unittest
from pathlib import Path
from PIL import Image
import importlib.util

HERE=Path(__file__).resolve().parent
script=HERE.parent/'scripts/tools/review_b01_assets.py'
spec=importlib.util.spec_from_file_location('b01_review',script)
mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)

class ReviewTests(unittest.TestCase):
    def test_plain_constant_tile_has_zero_seam(self):
        image=Image.new('RGBA',(128,128),(100,150,110,255))
        stats=mod.edge_stats(image)
        self.assertEqual(0,stats['left_right_rgba_mae'])
        self.assertEqual(0,stats['top_bottom_rgba_mae'])

    def test_edge_mismatch_is_detected(self):
        image=Image.new('RGBA',(128,128),(100,150,110,255))
        for y in range(128): image.putpixel((0,y),(255,0,0,255))
        self.assertGreater(mod.edge_stats(image)['left_right_rgba_mae'],6)

    def test_missing_modules_stay_review_required(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td)
            report=root/'report.json'
            result=mod.review(root,report)
            self.assertEqual('REVIEW_REQUIRED',result['status'])
            self.assertGreater(len(result['missing_revised_modules']),0)
            self.assertEqual('REVIEW_REQUIRED',json.loads(report.read_text())['status'])

if __name__=='__main__':unittest.main()
