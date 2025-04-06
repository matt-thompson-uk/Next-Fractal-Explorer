#!/usr/bin/python3

# This file - pcd.py - is part of Next Fractal Explorer

# Next Fractal Explorer is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or #FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#REM You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/

import argparse, os, subprocess

def line_num_str (line_no):
  lns = str(line_no)
  while len(lns) <4:
    lns = ' ' + lns
  return lns

# specifiy the size of the generated palette

num_colors=256

parser=argparse.ArgumentParser(description='Generates an RGB3 palette from a specified image file, for use on the ZX Spectrum Next computer. The output of this program is a BASIC program which can be transferred and run on the Next.')
parser.add_argument('source', help='The image file')
# number of colours are now fixed at 256
#parser.add_argument('colors', help='The number of colors in the palette', type=int, choices=[8,16,32,64,128,256])
parser.add_argument('name', help='The name of the pallette - without spaces.')

args=parser.parse_args()

if not os.path.isfile (args.source):
  print ('Could not find image file : ', args.source)
  exit()

# prepare things for the output file

# two byte arrays needed - one for the file header header, another for the palette
# now we write a PLUSDOS3 file. First the 128 byte header ...

outfile = './' + args.name + str(num_colors)+'.pal'
bp = open(outfile, 'wb')
ba1 = b'PLUS3DOS\x1a\x01\x00'
#bp.write (ba1) # 10 bytes
file_size = ((num_colors+1)*2)+128 # +256 #2 bytes per color, plus 2 bytes for num of colors, 128 bytes for the file header, +256 for good luck???

ba2=file_size.to_bytes(4,'little')

#7 bytes of Basic header now...
ba3 =b'\x03' # type is CODE
ba3 += (file_size-128).to_bytes(2,'little')+b'\x00\x00\x00\x00\x00' # bp.write(b'\x03') #  # BASIC file size, which doesn't include the file

#bp.write((file_size-128).to_bytes(2))  # BASIC file size doesn't include the file header'
ba4 =bytearray(104) # reserved

#final byte of the header is the checksum, so calculate it ...
checksum = 0
for i in ba1:
  checksum += i

for i in ba2:
  checksum += i

for i in ba3:
  checksum += i

for i in ba4:
  checksum += i

# print (checksum = ',checksum, " ",(checksum),"\n")

checksum = checksum & 255
#print ('checksum reduced  = ',checksum, " ",(checksum),"\n")
ba5 = bytes(checksum.to_bytes(1))

full_header=ba1+ba2+ba3+ba4+ba5
bp.write(full_header)

# Noe generate the palette
print ("Generating palette")

# pylette does the hard work for us
result=subprocess.run(["pylette", "--filename", args.source,"--mode", "MC", "--n", "256", "--sort-by", "luminance"], capture_output=True, text=True)
cols=result.stdout.splitlines()
cols.reverse()

first_color=True

# write the number of colors in the pallete
bp.write(num_colors.to_bytes(2,'little'))

i=0
for color in cols:
  print ("doing it")
  if first_color is True:
      first_color=False
      r=g=b=0; # first color is always black...
  else:
    rgbvals = eval(color)
    r=int (rgbvals[0])
    g=int (rgbvals[1])
    b=int (rgbvals[2])


  r3g3b3 = (r//32)*64 + (g//32)*8+(b//32)
  cludge=str(r3g3b3)
  r3g3b3=int(cludge)

  bp.write(r3g3b3.to_bytes(2,'little'))
  i+=1

bp.close()
print ("Pallet has been written to",os.path.abspath(outfile))
exit()

