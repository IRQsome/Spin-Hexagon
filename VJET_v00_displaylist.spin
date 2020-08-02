'' VECTORJET v0.0
'' (C)2020 IRQsome Software
'' Display list helper


#1,SHP_TRAPSTACK,SHP_BOX,SHP_TEXT

VAR
  long head ' current write position
  long spaceleft ' how much space left
  long link ' last list link word
  long topclip,bottomclip,leftclip,rightclip
  long prevlink ' previous link 
PUB set_clip(t,b,l,r)
  longmove(@topclip,@t,4)
PUB start(ptr,size)
head := ptr
spaceleft := size
link:=prevlink:= $8080
longfill(ptr,0,3) 'invalidate first shape

PUB done
if result:=spaceleft<#0 ' check for overflow 
  word[prevlink] := 0 ' prevent display list from reaching invalid shape
  word[link] := 0

PUB putlink
  putword(0)
  word[link] := head-2
  prevlink := link
  link := head-2

PUB putlong(x)
if (spaceleft -= 4) < 0
  abort 1
'if head & 3
  'abort 2
long[head] := x
head += 4

PUB putword(x)
if (spaceleft -= 2) < 0
  abort 3
'if head & 1
  'abort 4
word[head] := x
head += 2

PUB putbyte(x)
if (--spaceleft) < 0
  abort 5
byte[head++] := x

PUB skipspace(x)
head+=x
spaceleft -= x
PUB getpos
  return head
PUB slopeCalc(x1,x2,y1,y2)

  return ((x1-x2))/((y1~>16)-(y2~>16)+1)
  
PUB slopeCalc2(x1,x2,y1,y2)

  return ((x1-x2))/(y1-y2+1)


PUB point(x,y,colors)

box(x,y,x+1,y+1,colors)

PUB line(x1,y1,x2,y2,colors) : ihead | tmp '' TODO: Add dedicated line shape type?
if y1 > y2
  tmp := y1
  y1 := y2
  y2 := tmp
  
  tmp := x1
  x1 := x2
  x2 := tmp

if y2<topclip or y1=>bottomclip
  return 

putlink
if (spaceleft -= constant(3*2)) < 0
  abort 12
ihead:=head

word[ihead]:=(y1.word[1]) ' start line
ihead+=2
word[ihead]:=(y2.word[1]+1) ' end line
ihead+=2
word[ihead]:=(-1) ' init sync to -1 
ihead+=2
if y2.word[1] == y1.word[1] ' horizontal line
  if (spaceleft -= constant(3*2 + 2)) < 0
    abort 13
  byte[ihead++]:=(SHP_BOX)
  ihead++ ' unused byte
  
  if x1 < x2
    word[ihead]:=(x1~>16)
    ihead+=2
    word[ihead]:=(x2~>16)
  else
    word[ihead]:=(x2~>16)
    ihead+=2
    word[ihead]:=(x1~>16)
  ihead+=2
  word[ihead]:=(colors)
  ihead+=2
else
  if (spaceleft -= constant(2*4 + 4*4 + 2*2 + 4)) < 0
    abort 14
  byte[ihead++]:=(SHP_TRAPSTACK) ' type
  ihead+= constant(3 + 2*4) ' unused fields + scratch
  tmp := slopeCalc(x2,x1,y2,y1) 
  if x1 =< x2
    long[ihead]:=(x1)
    ihead+=4
    long[ihead]:=(x1+tmp+$10000)
  else
    long[ihead]:=(x1+tmp-$10000)
    ihead+=4
    long[ihead]:=(x1) 
  ihead+=4
   
  word[ihead]:=((y2.word[1])-(y1.word[1])+1)
  ihead+=2
  word[ihead]:=(colors)
  ihead+=2
   
  long[ihead]:=(tmp)
  ihead+=4
  long[ihead]:=(tmp)
  ihead+=4

head:=ihead





PUB line_triangle(x1,y1,x2,y2,x3,y3,colors)
  line(x1,y1,x2,y2,colors)
  line(x1,y1,x3,y3,colors)
  line(x2,y2,x3,y3,colors)

PUB line_polygon(polyptr,vcount,colors) | i,px,py

  px := long[polyptr][(vcount<<1)-2]
  py := long[polyptr][(vcount<<1)-1]  
  repeat i from 0 to vcount-1
    line(px,py,px := long[polyptr][(i<<1)],py := long[polyptr][(i<<1)+1],colors) 

PUB box(x1,y1,x2,y2,colors) : ihead

if y2<(topclip~>16) or y1=>(bottomclip~>16) or x2<(leftclip~>16) or x1=>(rightclip~>16)
  return

putlink
if (spaceleft -= constant(6*2 + 2)) < 0
  abort 11
ihead:=head
word[ihead]:=(y1) ' start line
ihead+=2
word[ihead]:=(y2) ' end line
ihead+=2
word[ihead]:=(-1) ' init sync to -1
ihead+=2
byte[ihead++]:=(SHP_BOX) ' type
ihead++ ' skip unused byte
word[ihead]:=(x1)
ihead+=2
word[ihead]:=(x2)
ihead+=2
word[ihead]:=(colors)
head:=(ihead+=2)


PUB triangle(x1,y1,x2,y2,x3,y3,colors) : ihead | tmp,tmp2,tmp3

if y1 > y2
  tmp := y1
  y1 := y2
  y2 := tmp
  
  tmp := x1
  x1 := x2
  x2 := tmp
  
if y1 > y3
  tmp := y1
  y1 := y3
  y3 := tmp
  
  tmp := x1
  x1 := x3
  x3 := tmp
  
if y2 > y3
  tmp := y2
  y2 := y3
  y3 := tmp
  
  tmp := x2
  x2 := x3
  x3 := tmp

if y3<topclip OR y1=>bottomclip OR (y2.word[1] == y1.word[1] AND y2.word[1] == y3.word[1])
  return 'reject offscreen/degenerate triangle 



putlink
if (spaceleft -= constant(4 + 3*2 + 2*4)) < 0
  abort 7
ihead:=head
word[ihead]:=(y1.word[1]) ' start line
ihead+=2
word[ihead]:=(y3.word[1]+1) ' end line
ihead+=2
word[ihead]:=(-1) ' init sync to -1
ihead+=2
byte[ihead++]:=(SHP_TRAPSTACK) ' type
ihead+=(constant(3 + 2*4)) ' unused fields + scratch
'head:=ihead

if y2.word[1] == y3.word[1] ' bottom flat?

  if (spaceleft -= constant(4*4 + 2*2)) < 0
    abort 8 
  'pst.str(string("bottom flat",13)) 
  tmp := slopeCalc(x3,x1,y3,y1)
  tmp2:= slopeCalc(x2,x1,y2,y1)
  if x2 > x3    
    long[ihead]:=(x1+(tmp<#0))
    ihead+=4
    long[ihead]:=(x1+(tmp2#>0))
  else    
    long[ihead]:=(x1+(tmp2<#0))
    ihead+=4
    long[ihead]:=(x1+(tmp#>0))
  ihead+=4

  word[ihead]:=((y3.word[1])-(y1.word[1])+1)
  ihead+=2
  word[ihead]:=(colors)
  ihead+=2
  
  if x2 > x3
    long[ihead]:=(tmp)
    ihead+=4
    long[ihead]:=(tmp2)
  else                                          
    long[ihead]:=(tmp2)
    ihead+=4
    long[ihead]:=(tmp) 

elseif y1.word[1] == y2.word[1] ' top flat?
  if (spaceleft -= constant(4*4 + 2*2)) < 0
    abort 9
  'pst.str(string("top flat",13)) 
  tmp := slopeCalc(x3,x2,y3,y2)
  tmp2:= slopeCalc(x3,x1,y3,y1)
  if x1 > x2
    long[ihead]:=(x2+(tmp<#0))
    ihead+=4
    long[ihead]:=(x1+(tmp2#>0))
  else
    long[ihead]:=(x1+(tmp2<#0))
    ihead+=4
    long[ihead]:=(x2+(tmp#>0))
  ihead+=4
    
  word[ihead]:=((y3.word[1])-(y1.word[1])+1)
  ihead+=2 
  word[ihead]:=(colors)
  ihead+=2 
  

  if x1 > x2
    long[ihead]:=(tmp)
    ihead+=4
    long[ihead]:=(tmp2)
  else
    long[ihead]:=(tmp2)
    ihead+=4
    long[ihead]:=(tmp)

else
  if (spaceleft -= constant(6*4 + 4*2)) < 0
    abort 10
  'pst.str(string("other",13))
  
  tmp := slopeCalc(x3,x1,y3,y1) ' long slope
  tmp2 := slopeCalc(x2,x1,y2,y1)' short slope
  if tmp2 > tmp
    long[ihead]:=(x1+(tmp<#0))
    ihead+=4
    long[ihead]:=(x1+(tmp2#>0))
    ihead+=4
    
    word[ihead]:=((y2.word[1])-(y1.word[1]))
    ihead+=2
    'putword($CCCC)
    word[ihead]:=(colors)
    ihead+=2
    
    long[ihead]:=(tmp)
    ihead+=4
    long[ihead]:=(tmp2)   
  else
    long[ihead]:=(x1+(tmp2<#0))
    ihead+=4
    long[ihead]:=(x1+(tmp#>0))
    ihead+=4
    
    word[ihead]:=((y2.word[1])-(y1.word[1]))
    ihead+=2
    'putword($CCCC)
    word[ihead]:=(colors)
    ihead+=2
    
    long[ihead]:=(tmp2)
    ihead+=4
    long[ihead]:=(tmp)
  ihead+=4 
  
  word[ihead]:=((y3.word[1])-(y2.word[1])+1)
  ihead+=2
  'putword($4C4C)
  word[ihead]:=(colors)
  ihead+=2

  tmp3 := slopeCalc(x3,x2,y3,y2) 
  if tmp2 > tmp
    long[ihead]:=(tmp)
    ihead+=4
    long[ihead]:=(tmp3)
  else
    long[ihead]:=(tmp3)
    ihead+=4
    long[ihead]:=(tmp)
   
head:=(ihead+=4)

                                     
PUB polygon(polyptr,vcount,colors) : ihead | ccw,tmp,lefti,righti,ybottom,ytop,topi,bottomi,leftx,rightx,lefty,righty,topleftx,toprightx,toplefty,toprighty,leftslope,rightslope,topptr,stepy

if vcount < 3
  return -2 ' degenerate poly

ytop := posx
ybottom:=negx
topi := 0
'' find topmost vertex
repeat lefti from 0 to vcount-1
  if (tmp:=long[polyptr+(lefti<<3)][1]~>16) < ytop
    ytop := tmp
    topi := lefti
    topleftx:=toprightx:= long[polyptr+(lefti<<3)]
  elseif tmp == ytop
    tmp:=long[polyptr+(lefti<<3)]
    topleftx <#=tmp
    toprightx#>=tmp
    
'' find bottommost vertex         
lefti:=topi
repeat vcount
  if ++lefti=>vcount
    lefti-=vcount
  if (tmp:=long[polyptr+(lefti<<3)][1]~>16) => ybottom
    ybottom := tmp                       
    bottomi := lefti

if ytop =>bottomclip~>16 OR ybottom < topclip~>16
  return -3 ' clip
if ytop == ybottom
  return -4' degenerate poly


'' figure out chain direction (CW or CCW) and set ccw to 1 or -1 accordingly
'' we do this by looking at the slopes coming off the topmost vertex
lefti := righti := topi 
if --lefti<0
  lefti+=vcount
if ++righti=>vcount
  righti-=vcount  
leftslope := slopeCalc2(long[polyptr+(lefti<<3)],long[polyptr+(topi<<3)],long[polyptr+(lefti<<3)][1]~>16,ytop)
rightslope := slopeCalc2(long[polyptr+(righti<<3)],long[polyptr+(topi<<3)],long[polyptr+(righti<<3)][1]~>16,ytop)
ccw := (( ( leftslope > rightslope ) )<< 1)+1 




putlink
if (spaceleft -= constant(2+2+2+1+(3 + 2*4)+4+4)) < 0
  abort 20
ihead:=head
word[ihead]:=(ytop) ' start line
ihead+=2
word[ihead]:=(ybottom+1) ' end line
ihead+=2
word[ihead]:=(-1) ' init sync to -1
ihead+=2
byte[ihead++]:=(SHP_TRAPSTACK) ' type
ihead+=(constant(3 + 2*4)) ' unused fields + scratch

'' initialize top edges - slopes will be added on later
topptr:=ihead
long[ihead]:=(topleftx)
ihead+=4
long[ihead]:=(toprightx)
ihead+=4
                   

'' find first left vertex
lefti := topi
repeat
  lefti-=ccw
  if lefti<0
    lefti+=vcount
  elseif lefti => vcount
    lefti-=vcount
  lefty:=long[polyptr+(lefti<<3)][1]~>16
  if lefty <> ytop
   quit
'' find first right vertex
righti := topi
repeat
  righti+=ccw
  if righti<0
    righti+=vcount
  elseif righti => vcount
    righti-=vcount
  righty:=long[polyptr+(righti<<3)][1]~>16
  if righty <> ytop
   quit


' build trapezoid stack
toplefty := toprighty := ytop
leftslope:=rightslope:=negx
repeat
  leftx := posx
  rightx:= negx
    
  if lefti<0
    lefti+=vcount
  elseif lefti => vcount
    lefti-=vcount
  if righti<0
    righti+=vcount
  elseif righti => vcount
    righti-=vcount
        
  '' find left vertex
  if leftslope==negx
    repeat
      leftx<#=long[polyptr+(lefti<<3)]
      lefty:=long[polyptr+(lefti<<3)][1]~>16
      if lefty == ybottom
        quit
      ' take all vertices on the same Y
      tmp := lefti-ccw
      if tmp<0
        tmp+=vcount
      elseif tmp => vcount
        tmp-=vcount
      if long[polyptr+(tmp<<3)][1]~>16 <> lefty
        quit 
      lefti:=tmp
  if rightslope==negx    
  '' find right vertex
    repeat
      rightx#>=long[polyptr+(righti<<3)]
      righty:=long[polyptr+(righti<<3)][1]~>16
      if righty == ybottom
        quit
      ' take all vertices on the same Y
      tmp := righti+ccw
      if tmp<0
        tmp+=vcount
      elseif tmp => vcount
        tmp-=vcount
      if long[polyptr+(tmp<<3)][1]~>16 <> righty
        quit         
      righti:=tmp

  'return lefti
  stepy:=lefty <# righty
  'putword($FFF)
  if (spaceleft -= constant(2+2+4+4)) < 0
    abort 20  
  word[ihead]:=(stepy-(toplefty <# toprighty)+((tmp := (stepy==ybottom))>>31)) ' trapezoid height
  ihead+=2
  word[ihead]:=(colors)
  ihead+=2
  
  '' re-calculate slopes if neccessary
  if leftslope == negx 
    leftslope:=slopeCalc2(leftx,topleftx,lefty+(toplefty<>ytop AND toplefty<>ybottom),toplefty)
    topleftx:=leftx
    toplefty:=lefty
  if rightslope == negx
    rightslope:=slopeCalc2(rightx,toprightx,righty+(toprighty<>ytop AND toprighty<>ybottom),toprighty)
    toprightx:=rightx
    toprighty:=righty

  long[ihead]:=(leftslope)
  ihead+=4
  long[ihead]:=(rightslope)
  ihead+=4
  if topptr
    long[topptr]+=leftslope<#0
    long[topptr~][1]+=rightslope#>0 ' note the post-clear
    
  if lefty=<righty
    lefti-=ccw
    leftslope:=negx
  else
    righti+=ccw
    rightslope:=negx
until tmp
head:=ihead      

PUB text(x,y,xscale,yscale,str,font,colors) : ihead |ystop

ystop :=y+(8<<yscale)

if ystop > topclip~>16 AND y < bottomclip~>16

  putlink
  if (spaceleft -= constant(2+2+2+ 1+1+ 2+2+2+2+2)) < 0
    abort 16
  ihead:=head
  word[ihead]:=(y) ' start line
  ihead+=2
  word[ihead]:=(ystop) ' end line
  ihead+=2
  word[ihead]:=(-1) ' init sync to -1
  ihead+=2
  byte[ihead++]:=(SHP_TEXT) ' type
  byte[ihead++]:=(xscale<<5+(yscale&31)) ' scale
  word[ihead]:=(font)
  ihead+=2
  word[ihead]:=(str)
  ihead+=2
  word[ihead]:=(colors)
  ihead+=2
  word[ihead]:=(x)
  ihead+=2
  word[ihead]:=(0) 'unused
  head:=(ihead+=2)

PUB text_centered(x,y,xscale,yscale,str,font,colors)
return text(x-((strsize(str)*9)<<xscale)>>1,y,xscale,yscale,str,font,colors)

PUB text_ljust(x,y,xscale,yscale,str,font,colors)
return text(x-((strsize(str)*9)<<xscale),y,xscale,yscale,str,font,colors)

PUB text_inline(x,y,xscale,yscale,str,font,colors) | len,tmp
          
len := (strsize(str)+4)&!3 ' include zero terminator and align to long size
if (spaceleft -= len) < 0
  abort 6
tmp := head
bytemove(head,str,len)
head+=len
return text(x,y,xscale,yscale,tmp,font,colors)




   