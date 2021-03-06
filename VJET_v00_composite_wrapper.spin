'' VECTORJET v0.0
'' (C)2020 IRQsome Software
'' Spin Glue code
CON

' constants
 SCANLINE_BUFFER = $7800
 NUM_LINES = gfx#NUM_LINES
 WIDTH = 256
 HEIGHT = NUM_LINES                             
 request_scanline       = SCANLINE_BUFFER-2      'address of scanline buffer for TV driver
 unused1                = SCANLINE_BUFFER-4     
 border_color           = SCANLINE_BUFFER-8 'border color                 
 displaylist_adr        = SCANLINE_BUFFER-10 'address of display list
 displaylist_in_use     = SCANLINE_BUFFER-12

 MEMORY_END = displaylist_in_use


OBJ
  tv    : "VJET_v00_composite.spin"             ' tv driver 256 pixel scanline
  gfx   : "VJET_v00_rendering.spin"    ' graphics engine

VAR


PUB tv_start(NorP)
  set_mode(NorP) ''NTSC or PAL60
  tv.start(@tvparams)

PUB tv_stop
   tv.stop
   
PUB start(video_pins,cogs,NorP)          | i, ready
                                                
  long[@tvparams+8]:=video_pins ''map pins for video out

  
  ' Boot requested number of rendering cogs:
  ' this must be 4, because bit magic 
  ready~
  repeat i from 0 to cogs-1
    gfx.start(i,cogs,@ready)
  ready~~
  word[border_color]:=$04 ''default border color
  longfill(SCANLINE_BUFFER,$02_02_02_02,256*8)
  'start tv driver
  tv_start(NorP)

PUB set_mode(NorP)
  long[@tvparams+12]:=NorP

PUB Wait_Vsync ''wait until frame is done drawing
    repeat while tv_vblank
    repeat until tv_vblank
PUB Set_Border_Color(bcolor) | i ''set the color for border around screen
    long[border_color]:=bcolor
          
DAT
tvparams
tv_vblank               long    0               'status
tv_enable               long    1               'enable
tv_pins                 long    %011_0000       'pins ' PROTO/DEMO BOARD = %001_0101 ' HYDRA = %011_0000
tv_mode                 long    0               'mode - default to NTSC
tv_ho                   long    -32             'ho
tv_vo                   long    0               'vo
tv_broadcast            long    50_000_000'_xinfreq<<4  'broadcast
tv_auralcog             long    0               'auralcog


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