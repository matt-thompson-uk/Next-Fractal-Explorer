' This file - io.bas - is part of Next Fractal Explorer
''
' Next Fractal Explorer is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
' 
' REM This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/



'!ORG=40960
'
' memory area for nextbasic to pass plot parameters to this code starts at @xmin_string
' #A97B - 43387'
' IMPORTANT: if the value of xmin_string ever changes, nfe.bas must be updated
' to poke to the new addresses
'
'floating point numbers format = sign, digit, decimal point, up to 9 decimal places
'eg : "-1.4002341 ", "0.90479812  " so each is 12 bytes in length
 

#define NEX
#include <keys.bas>
#include <nextlib.bas>

code_start:
goto realstart

xmin_string:    
asm 
  ; the values below are not important
  ;  they are placeholders to make sure that the correct number of bytes are allocated
  db "-0.275390620"  
end asm

xmax_string:
asm
  db " 0.062109376"
end asm

ymin_string: 
asm
  db " 0.773435750" 
end asm

ymax_string:
  asm
  db " 1.110935750"
end asm

maxiter_b:
asm
  db 255      ; maxiter 
end asm

plotsize_b:
  asm
    db 1        ;  0=256x192, 1=320x256
end asm 
realstart:
asm
    NextReg TURBO_CONTROL_NR_07,3                  ; 28Mhz
end asm


rem declare variables  
dim xmin as float = -2.1 
dim xmax as float = 0.6
dim ymax as float = 1.35
dim ymin as float = -1.35

const lrplotwidth as UByte = 255
const lrplotheight as UByte = 191
const hrplotwidth as UInteger = 319
const hrplotheight as UByte = 255
dim plotsize as ubyte
dim x as UInteger
dim y as UByte
dim hr_y as UInteger ' y coord in hi-res mode
dim dx as float
dim dy as float 
dim wx,wy,tx,ty as float
dim maxiter as UByte = 255
dim m as float = 4.0
dim jx, jy as float
dim k as UByte
dim r as float

SetPlotParams()

if plotsize = 0 then
  dx = (xmax - xmin) / lrplotwidth 
  dy = (ymax - ymin) / lrplotheight

  rem Do th actual plotting - the code below adapated from
  rem https://rosettagit.org/drafts/mandelbrot-set/#basic256
  for x = 0 to lrplotwidth
  	jx = xmin + x * dx
  	for y = 0 to lrplotheight
      PlotL2(x, y, 255)
		  jy = ymin + y * dy
      k = 0 : wx = 0.0 : wy = 0.0
		  do
			  tx = wx * wx - wy * wy + jx
			  ty = 2.0 * wx * wy + jy
			  wx = tx
			  wy = ty
			  r = wx * wx + wy * wy
			  k = k + 1
		  loop until r > m or k = maxiter
		
		if k = maxiter then k = 0 
  
    PlotL2(x,y,k)
    next y
  next x
else
  dx = (xmax - xmin) / hrplotwidth 
  dy = (ymax - ymin) / hrplotheight
  
  dim ycoord as UByte
  dim hrx as UInteger:  rem don't change this to ubyte as it really should be - things go wrong.... 
  dim hry as UInteger
  for hrx = 0 to hrplotwidth 
    jx = xmin + hrx * dx
    for hry = 0 to hrplotheight
      ycoord = hry band $FF
      fplotL2(ycoord, hrx, 255)
      jy = ymin + hry * dy
      k = 0 : wx = 0.0 : wy = 0.0
      do
        tx = wx * wx - wy * wy + jx
        ty = 2.0 * wx * wy + jy
        wx = tx
        wy = ty
        r = wx * wx + wy * wy
        k = k + 1
      loop until r > m or k = maxiter

      if k = maxiter then  k = 0 
     
      FPlotL2(ycoord,hrx,k)
    next hry
  next hrx

end if


Function Str2fp (str_start as uinteger) as float
' convert a floating point number in string format to a float'
' the first character of this first string is at address xmin_string
' The string is a fixed size of twelve characters in length '
' because the Spectrum floating point format is only accurate to 9 characters,'
' plus 1 char for +/- sign, another for the decimal point, and another for luck...

    dim fpstr as string = ""
    dim newchar as string

    for i=0 to 11
         new_char$ = chr (peek (str_start + i))
         fpstr = fpstr +  new_char
      
    next i

    dim result as float
    result = val (fpstr)
	  return result
    
end Function

sub SetPlotParams()
    xmin = Str2fp (@xmin_string)    
    xmax = Str2fp (@xmax_string)
    ymin = Str2fp (@ymin_string)
    ymax = Str2fp (@ymax_string)   
    maxiter = peek (@maxiter_b)
    plotsize = peek (@plotsize_b)

return 
end sub  

sub SetScreenMode (ps aS uByte)    
   
if ps = 0 then
  
  asm  
    
    NextReg LAYER2_CONTROL_NR_70,%00000000			; L2 256x192
    NextReg $1c, 1
    NextReg $18, 0                                  ; REG $18 - set clipping region
    NextReg $18, 255
    NextReg $18, 0
    NextReg $18, 191
  end asm
else 
  rem 320x256 mode
  asm
    NextReg LAYER2_CONTROL_NR_70,%00010000      ; L2 320x256
    NextReg $1c, 1
    NextReg $18, 0                                  ; REG $18 - set clipping region
    NextReg $18, 159
    NextReg $18, 0
    NextReg $18, 255
  end asm
end if

end sub

