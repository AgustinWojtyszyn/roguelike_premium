#!/usr/bin/env python3
"""Read-only integrity check for Playground R8 installed into RPG PREMIUM. Python stdlib only."""
import hashlib,json,pathlib,struct,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]

def png_ihdr(file:pathlib.Path):
 with file.open('rb') as f:hdr=f.read(33)
 if hdr[:8]!=b'\x89PNG\r\n\x1a\n' or hdr[12:16]!=b'IHDR' or hdr[8:12]!=b'\x00\x00\x00\r':raise ValueError('invalid PNG IHDR')
 w,h,depth,color,comp,filtering,interlace=struct.unpack('>IIBBBBB',hdr[16:29])
 if w<1 or h<1 or color!=6 or depth!=8 or comp!=0 or filtering!=0:raise ValueError('non RGBA PNG')
 return w,h

class CheckPlaygroundR8(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.data=json.loads((ROOT/'assets/premium/playground_r8/PROVENANCE.json').read_text())
 def test_counts(self):
  self.assertEqual(len(self.data['actors']),12)
  self.assertEqual(len(self.data['reference']),36)
  self.assertEqual(sum(len(x['animations']) for x in self.data['actors'].values()),54)
  self.assertEqual(sum(s['frames'] for x in self.data['actors'].values() for s in x['animations'].values()),726)
 def test_actor_pngs(self):
  for actor,data in self.data['actors'].items():
   with self.subTest(actor=actor):
    self.assertIn('idle',data['animations'])
    for action,clip in data['animations'].items():
     file=ROOT/clip['path']
     self.assertEqual(hashlib.sha256(file.read_bytes()).hexdigest(),clip['sha256'])
     self.assertEqual(png_ihdr(file),(clip['frames']*data['runtime_cell'][0],data['runtime_cell'][1]))
 def test_reference_pngs(self):
  for name,rec in self.data['reference'].items():
   with self.subTest(name=name):
    f=ROOT/rec['path'];self.assertTrue(f.is_file())
    self.assertEqual(hashlib.sha256(f.read_bytes()).hexdigest(),rec['sha256'])
    self.assertTrue(png_ihdr(f)[0]>0)
 def test_license(self):
  self.assertIn('UNVERIFIED',self.data['source_licence'])

if __name__=='__main__':unittest.main(verbosity=1)
