'' VECTORJET v1.0
'' (C)2020 IRQsome Software
'' TV output code (External ASM version)
''*****************************
''*  TV Driver v1.0           *
''*  (C) 2004 Parallax, Inc.  *
''*****************************

CON

  paramcount    = 8

 SCANLINE_BUFFER = $7800
 NUM_LINES = 238
 NUM_HGROUPS = 256/4                   
 request_scanline       = SCANLINE_BUFFER-2      'address of scanline buffer for TV driver
 border_color           = SCANLINE_BUFFER-8 'border color
VAR

  long  cogon, cog


PUB start(tvptr,asmptr) : okay

'' Start TV driver - starts a cog
'' returns false if no cog available
''
''   tvptr = pointer to TV parameters

  stop                 
  okay := cogon := (cog := cognew(asmptr,tvptr)) > 0


PUB stop

'' Stop TV driver - frees a cog

  if cogon~
    cogstop(cog)

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    TERMS OF USE: Parallax Object Exchange License                                            │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}