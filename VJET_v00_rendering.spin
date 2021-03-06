'' VECTORJET v0.0
'' (C)2020 IRQsome Software
'' Rendering Cog code          
CON
  SCANLINE_BUFFER = $7800
  NUM_LINES = 238
  WIDTH = 256                          
  Last_Scanline = NUM_LINES-1 ''final scanline for a frame


  Sfield = 0
  DField = 9


''   Display list format - shape header  (9 bytes)
'' WORD pointer to next shape or null
'' WORD start scanline
'' WORD end scanline
'' WORD renderer sync line
'' BYTE shape type

'' Shape type 1 header - trapezoid stack (19 bytes)
'' BYTE unused/padding
'' WORD unused/padding
'' LONG current left edge
'' LONG current right edge 
'' LONG initial left edge
'' LONG initial right edge

'' One trapezoid  (12 bytes)
'' WORD height
'' WORD colors
'' LONG left slope
'' LONG right slope

'' Shape type 2 header - box (7 bytes)
'' BYTE unused/padding
'' WORD left edge
'' WORD right edge
'' WORD colors 

'' Shape type 3 header - text (11 bytes)
'' BYTE scale: bits 0..4 : Y scale (log2), bits 5..6 X scale
'' WORD font pointer
'' WORD string pointer
'' WORD colors
'' WORD left x
'' WORD unused/padding
 
#1,SHP_TRAPSTACK,SHP_BOX,SHP_TEXT

PUB start(cognum,totalcogs,readyptr)
'' Start Rendering Engine
  long[@cognumber] := cognum
  long[@total_cogs] := totalcogs
  cognew(@Entry, readyptr)
  repeat 10000 'wait for cog to boot...

PUB Return_Address ''used to get address where assembly code is so we can re-purpose space
    return(@Entry)

DAT
        org
Entry
cognumber               long -1 ''which COG this rendering COG is
total_cogs              long -1 ''how many rendering COGs there are on total

''Note: Init code gets reuses as variables, thus the labels
a0      mov a0, Par  ''read parameter
d0      rdbyte currentscanline, a0 wz''is ready?
d1 if_z jmp #d0 'if not, repeat
        
        
'        rdlong Tiles_Adr, tile_adr ''read address of where tiles are at

''Main loop for renderer
new_frame
        neg prevline,#1
''wait until we hit scanline 0 so we can start with a fresh frame
:waitloop
        rdword currentrequest, request_scanline wz
if_nz   jmp #:waitloop

        mov currentscanline, cognumber ''reset current scanline for COG

        rdword dlist_base, dlist_ptr_adr  '' read adress of display list
        wrword dlist_base, dlist_in_use

'' fixup shapes clipped by top edge of screen (negative ystart)
        mov init_share,cognumber ' we only handle every Nth fixup
        mov dlist_next,dlist_base
        jmp #:nextshape        
        
:shapeloop
        mov dlist_ptr,dlist_next
        rdword dlist_next,dlist_ptr
        add dlist_ptr,#2

        rdword poly_top,dlist_ptr ' get start line
        shl poly_top,#16 ' sign extend
        cmps poly_top,#0 wc,wz ' negative start?
if_ae   jmp #:nextshape
        sar poly_top,#16 'continue sign extend
        sub init_share,#1 wc ' should this cog handle this line?
if_nc   jmp #:nextshape
        mov init_share,#0
           
        add dlist_ptr,#4
        mov poly_syncptr,dlist_ptr
        add dlist_ptr,#2
       
        rdbyte shape_type,dlist_ptr
        '' could read the unused fields here        
        add dlist_ptr,#4

        cmp shape_type,#SHP_TRAPSTACK wz ' other shape types don't need fixup
if_ne   jmp #:nextshape_sync


        ' read initial edges
        mov poly_edgebuf,dlist_ptr
        add dlist_ptr,#8
        rdlong poly_left,dlist_ptr
        add dlist_ptr,#4
        rdlong poly_right,dlist_ptr
        add dlist_ptr,#4

        neg init_lines,poly_top

        ' iterate through trapezoids above Y0
        ' and premultiply
        
:traplp rdword trap_lines,dlist_ptr

        add dlist_ptr,#4 ' skip over colors 
        
        rdlong v1,dlist_ptr 'get left slope
        add dlist_ptr,#4
        mov v2,trap_lines
        max v2,init_lines
        call #newmult
        adds poly_left,vRes        

        
        rdlong v1,dlist_ptr 'get right slope
        add dlist_ptr,#4
        mov v2,trap_lines
        max v2,init_lines
        call #newmult
        adds poly_right,vRes  

        sub init_lines,trap_lines wc
if_nc   jmp #:traplp
            

        ' write back edges
        wrlong poly_left,poly_edgebuf
        add poly_edgebuf,#4
        wrlong poly_right,poly_edgebuf
:nextshape_sync
        ' write sync
        wrword zero,poly_syncptr
:nextshape
        tjnz dlist_next,#:shapeloop             

setup_line
        mov display_base,scanlines ' Calculate start of hub buffer for this scanline
        mov d0,currentscanline
        and d0,#7
        'mov line_n_7,d0 'preserve (scanline&7) for later
        shl d0,#8
        add display_base,d0

        mov pixel_ptr,display_base


        mov pixel_iter,#WIDTH/4
:loop   wrlong black,pixel_ptr
        add pixel_ptr,#4
        djnz pixel_iter,#:loop

        mov dlist_next,dlist_base
        jmp #:nextshape        
        
:shapeloop
        mov dlist_ptr,dlist_next
        rdword dlist_next,dlist_ptr
        add dlist_ptr,#4
        
        rdword poly_bottom,dlist_ptr ' get end line (no need to sign extend)
        cmp poly_bottom,currentscanline wc,wz
if_be   jmp #:nextshape
        sub dlist_ptr,#2

        rdword poly_top,dlist_ptr ' get start line
        shl poly_top,#16 ' sign extend
        sar poly_top,#16 ' ^^
        cmps poly_top,currentscanline wc,wz
if_a    jmp #:nextshape
        add dlist_ptr,#4

        'wait for shape sync
        mov poly_syncptr,dlist_ptr
if_e    jmp #:synced ' not if first line
        mov d1,sync_timeout
:syncloop
        rdword d0,poly_syncptr
        cmp d0,currentscanline wz
if_nz   djnz d1,#:syncloop ' if we don't get shape sync in a reasonable timeframe, render anyways
:synced

        add dlist_ptr,#2        
        rdbyte shape_type,dlist_ptr

        cmp shape_type,#SHP_TRAPSTACK wz 'TODO: implement other shape types
if_ne   jmp #:othershapes

        '' could read the unused fields here        
        add dlist_ptr,#4

        ' is first line of shape?
        cmp poly_top,currentscanline wz

        ' read edges
        mov poly_edgebuf,dlist_ptr
if_e    add dlist_ptr,#8
        rdlong poly_left,dlist_ptr
        add dlist_ptr,#4
        rdlong poly_right,dlist_ptr
        add dlist_ptr,#4
if_ne   add dlist_ptr,#8

        mov trap_lines,currentscanline
        sub trap_lines,poly_top

        ' find current trapezoid
:traplp rdword d0,dlist_ptr
        cmpsub trap_lines,d0 wc,wz
if_c    add dlist_ptr,#3*4
if_c    jmp #:traplp
:trapfound

        add dlist_ptr,#2
        rdword poly_colors,dlist_ptr
        add dlist_ptr,#2
        rdlong slope_left,dlist_ptr
        add dlist_ptr,#4
        rdlong slope_right,dlist_ptr


        call #draw_span
        adds poly_left,slope_left         
        adds poly_right,slope_right
                     

        ' write back edges
        wrlong poly_left,poly_edgebuf
        add poly_edgebuf,#4
        wrlong poly_right,poly_edgebuf
:nextshape_sync
        ' write sync
        mov d0,currentscanline
        add d0,#1
        cmp poly_bottom,d0 wz
if_e    neg d0,#1
        wrword d0,poly_syncptr
    
 
:nextshape
        tjnz dlist_next,#:shapeloop        
        
        'uncomment to enable diagonal line that aids in debugging
        {
        mov d0,currentscanline
        and d0,#255
        add d0,display_base
        wrbyte white,d0
        } 
        
        jmp #scanline_finished


:othershapes
        cmp shape_type,#SHP_TEXT wz ' text?
if_e    jmp #:textshape
        cmp shape_type,#SHP_BOX wz
if_ne   jmp #:nextshape_sync
:boxshape
        '' BOX DRAWING
        ' get stuff from display list
        add dlist_ptr,#2 ' skip over unused byte
        rdword poly_left,dlist_ptr
        add dlist_ptr,#2
        shl poly_left,#16
        rdword poly_right,dlist_ptr
        add dlist_ptr,#2
        shl poly_right,#16
        rdword poly_colors,dlist_ptr

        call #draw_span
        jmp #:nextshape_sync
        
        
        

:textshape
        '' TEXT DRAWING
        ' get stuff from display list and precalc
        add dlist_ptr,#1
        
        rdbyte text_scale,dlist_ptr
        add dlist_ptr,#1
        mov text_y,currentscanline

        rdword fontptr,dlist_ptr
        add dlist_ptr,#2
        
        sub text_y,poly_top 
         
        rdword strptr,dlist_ptr
        add dlist_ptr,#2
        
        shr text_y,text_scale

        rdword poly_colors,dlist_ptr
        add dlist_ptr,#2
        
        and text_y,#%111
        '' setup pixel width (1,2, or 4)
        mov text_pxwidth,#1
        test text_scale,#%01_00000 wc
        test text_scale,#%10_00000 wz
if_nz_and_c  jmp #:nextshape_sync ' illegal
        
        rdword poly_left,dlist_ptr
        shl poly_left,#16 ' sign extend
        sar poly_left,#16

if_c    shl text_pxwidth,#1
if_nz   shl text_pxwidth,#2
if_c    andn poly_left,#%01 ' force alignment
if_nz   andn poly_left,#%10
        muxc :thewr1,opc_bit0
        muxnz :thewr1,opc_bit1
        mov :thewr2,:thewr1
        mov text_pxperchr,text_pxwidth ' calc width per character (8+1)*pxwidth
        shl text_pxwidth,#3
        add text_pxperchr,text_pxwidth
        shr text_pxwidth,#3

        call #prepare_color

:chrloop
        rdbyte d0,strptr wz
        cmps poly_left,#WIDTH wc
if_z_or_nc jmp #:nextshape_sync
        add strptr,#1
        cmps poly_left,#0 wc,wz
if_b    jmp #:chrdone

        ' get font byte
        sub d0,#32
        shl d0,#1
        add d0,fontptr
        rdword d0,d0
        add d0,text_y
        rdbyte d0,d0
        
        mov pixel_ptr,display_base
        add pixel_ptr,poly_left
        
:tplp
        shr d0,#1 wc,wz
:thewr1
if_c    wrbyte span_color,pixel_ptr
        add pixel_ptr,text_pxwidth
        shr d0,#1 wc,wz
:thewr2
if_c    wrbyte span_color,pixel_ptr
        add pixel_ptr,text_pxwidth
if_nz   jmp #:tplp
:chrdone
        add poly_left,text_pxperchr

        jmp #:chrloop
        
            


draw_span
        ' range check edges
        
        mov span_right,poly_right 
        sar span_right,#16
        cmps span_right,#0 wc,wz
if_be   jmp draw_span_ret
        maxs span_right,#WIDTH
        mov span_left,poly_left
        sar span_left,#16
        cmps span_left,#WIDTH wc,wz
if_ae   jmp draw_span_ret
        mins span_left,#0 

        mov span_length,span_right
        sub span_length,span_left wc,wz
if_c_or_z jmp draw_span_ret ' return if span length/width =< 0 

        'maxs span_length,#64 'TODO: delete this
        'cmp span_length,#256 wc,wz  'TODO: delete this
        'if_a jmp #$  'TODO: delete this

        call #prepare_color


        ' debug draw
        {
        add span_left,display_base
        wrbyte red,span_left
        add span_right,display_base
        sub span_right,#1
        wrbyte green,span_right

        tjz span_length,draw_span_ret
:aaaaaaa
        wrbyte span_color,span_left
        add span_left,#1
        djnz span_length,#:aaaaaaa
        }

        '{
        ' draw span
        add span_left,display_base
        
        ' super edge case: super short span
        cmp span_length,#8 wc,wz ' TODO: what is the optimal threshold here? (6 is the minimum for correct execution)
if_be   jmp #:shortspan

        ' handle left edge cases

        test span_left,#%11 wc,wz
if_z    jmp #:leftaligned

        test span_left,#%01 wz
if_nz   wrbyte span_color,span_left
if_nz   add span_left,#1
if_nz   sub span_length,#1


if_c    wrword span_color,span_left
if_c    add span_left,#2
if_c    sub span_length,#2
:leftaligned


        ' handle right edge cases
        mov d0,span_left
        add d0,span_length
        
        test span_length,#%01 wc
if_c    sub d0,#1 
if_c    wrbyte span_color,d0

        test span_length,#%10 wc
if_c    sub d0,#2
if_c    wrword span_color,d0

        ' draw longs
        shr span_length,#2 wz
if_z    jmp draw_span_ret

:spnlp
        wrlong span_color,span_left
        add span_left,#4
        djnz span_length,#:spnlp
        jmp draw_span_ret        

:shortspan
        tjz span_length,draw_span_ret
:sspnlp
        wrbyte span_color,span_left
        add span_left,#1
        djnz span_length,#:sspnlp
        '}
  
draw_span_ret
              ret

prepare_color
        ' prepare color
        ' select byte 0 or 1 from poly_colors  
        mov d0,poly_colors
        test currentscanline,#1 wc ' scanline odd/even into C
if_c    shr d0,#8
        ' put that byte into all 4 of span_color
        and d0,#255
        mov span_color,d0
        shl d0,#8
        or  span_color,d0
        mov d0,span_color
        shl d0,#16
        or  span_color,d0
prepare_color_ret
        ret

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''scanline rendering is finished, wait for request from TV driver
scanline_finished
'       cmp currentscanline, #Last_Scanline-4 wc, wz 'last scanline? (4= number of cogs)
'if_a   jmp #new_frame
        
                 
'' wait until TV requests the scanline we rendered
linewait
        rdword currentrequest, request_scanline wz
        cmp currentscanline,#16 wc
if_z_and_nc jmp #new_frame
        cmps currentrequest, prevline wz, wc
waitjmp
if_be   jmp #linewait
        
                                                                             
scanlinedone
        mov prevline,currentscanline
        ' Line is done, increment to the next one this cog will handle                        
        add currentscanline, total_cogs 'add number of cogs = 4
        ' The screen is completed, jump back to main loop a wait for next frame
        cmp currentscanline,#Last_Scanline wc,wz
if_be   jmp #setup_line
        jmp #new_frame
        
'' See: https://forums.parallax.com/discussion/160804/slightly-faster-integer-multiplication-in-pasm
newmult       ' setup
              mov       vRes, #0      ' Primary accumulator (and final result)
              abs       v1,v1  wc
              muxnc     zero,#1 nr,wz ' C to Z
              mov       tmp1, v1      ' Both my secondary accumulator,
              shl       tmp1, #16     ' and the lower 16 bits of v1.
              'mov       tmp2, v2      ' This is the upper 16 bits of v2,
              'shr       tmp2, #16     ' which will sum into my 2nd accumulator.
              mov       tmp2,#0 'haxx
              mov       muli, #16        ' Instead of 4 instructions 32x, do 6 instructions 16x.          
:loop         ' v1_hi_lo * v2_lo
              shr       v2, #1 wc     ' get the low bit of v2          
        if_c  add       vRes, v1      ' (conditionally) sum v1 into my 1st accumulator
              shl       v1, #1        ' bit align v1 for the next pass 
              ' v1_lo * v2_hi
              shl       tmp1, #1 wc   ' get the high bit of v1_lo, *AND* shift my 2nd accumulator
       ' if_c  add       tmp1, tmp2    ' (conditionally) add v2_hi into the 2nd accumulator
              ' repeat 16x
              djnz      muli, #:loop     ' I can't think of a way to early exit this
              ' finalize
              shl       tmp1, #16     ' align my 2nd accumulator
              add       vRes, tmp1    ' and add its contribution
              negz      vRes,vRes          
newmult_ret   ret
           


''===========
''DATA STUFF
''===========
scanlines            long SCANLINE_BUFFER    ''scanline address
scanlines_end        long $8000
request_scanline        long SCANLINE_BUFFER-2      ''next scanline to render
border_color           long SCANLINE_BUFFER-8 ''border color
buffer_attribs_ptr      long SCANLINE_BUFFER-20 'array of 8 bytes

dlist_ptr_adr     long SCANLINE_BUFFER-10   ''address of where sprite attribs are stored
dlist_in_use      long SCANLINE_BUFFER-12  

Dfield_1  long 1<<Dfield

opc_bit0 long 1<<26
opc_bit1 long 2<<26

con8080   long $8080                                             

junkcolor long $05_05
junkslope long $0001_8431
junkslope2 long $0000_8431 

white long $07 * $01010101
black long $02 * $01010101
red   long $CC * $01010101
green long $4C * $01010101

sync_timeout long 5000

zero long 0

tmp1 res 1
tmp2 res 1
muli res 1
v1 res 1
v2 res 1
vRes res 1

init_share res 1

init_lines res 1
text_y 'alias
trap_lines res 1
pixel_iter res 1

text_pxwidth ' alias
slope_left res 1
text_pxperchr 'alias
slope_right res 1

pixel_ptr   res 1
pixel_ptr_stride res 1

dlist_base res 1
dlist_ptr  res 1
dlist_next res 1               

currentrequest res 1

currentscanline res      1 ''current scanline that TV driver is rendering
prevline       res       1
tile_line     res        1
display_base res         1


span_left     res 1
span_right    res 1
span_length   res 1
span_color    res 1
shape_type    res 1
poly_top      res 1
poly_bottom   res 1
poly_left     res 1
poly_right    res 1
poly_colors   res 1
poly_edgebuf  res 1
poly_syncptr  res 1

text_scale    res 1
fontptr       res 1
strptr        res 1

'kak res 1

fit  496

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