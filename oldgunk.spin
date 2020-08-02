
{lefti := righti := topi  
leftx := rightx := long[polyptr+(topi<<3)]
leftslope~ ' recycle slope variable to hold iteration count
repeat
  leftslope++ 
  if --lefti<0
    lefti+=vcount
  if (tmp:=long[polyptr+(lefti<<3)]) <> leftx
    leftx:=tmp
    quit
  if lefti == bottomi
    leftx:=tmp
    quit

repeat   
  if ++righti=>vcount
    righti-=vcount
  if (tmp:=long[polyptr+(righti<<3)]) <> rightx
    rightx:=tmp
    quit
  if righti == bottomi
    rightx:=tmp
    quit
ccw := (( ( leftx > rightx ) ^ (leftslope=>((vcount+1)>>1)) )<< 1)+1 
}



{
PUB polygon(polyptr,vcount,colors) |tmp,i2,left,right,stepy,ytop,ybottom,topid,bottid,prevy,leftslope,rightslope,lefty,righty,topleft,topright,leftbehind,rightbehind,topptr

poly_ysort(polyptr,vcount)'' sorting magic
 
ytop := long[polyptr][1]~>16
ybottom:= long[polyptr][(vcount<<1)-1]~>16
topid :=  long[polyptr][1]&$FFFF ' original ID of top-most vertex  
bottid := long[polyptr][(vcount<<1)-1]&$FFFF ' original ID of bottom-most vertex

{
if true
  tmp:=bottid
  bottid:=topid
  topid:=tmp
} 
if ytop == ybottom
  return

 
putlink
putword(ytop) ' start line
putword(ybottom+1) ' end line
putword(-1) ' init sync to -1
putbyte(1) ' type
putbyte(0) ' unused
putword(0) ' unused

repeat 2
  putlong(0) ' scratch space


'' find top of stack
i2:=0
lefty:=righty:=prevy:=ytop
topleft:=posx
topright:=negx
repeat while (long[polyptr][i2+1]~>16) == ytop
  tmp:=long[polyptr][i2]
  topleft  <#=tmp
  topright #>=tmp 
  i2+=2
'' consumed all top vertices

'' initialize top edges - slopes will be added on later
topptr:=head
putlong(topleft)
putlong(topright)

'putword(ybottom-ytop+1)
'putword(colors)
'putlong(0)
'putlong(0)



leftslope:=rightslope:=negx

'' run through all that is left 
leftbehind~
rightbehind~
repeat
  if i2 == vcount<<1
    quit
  stepy:= long[polyptr][i2+1]~>16                         
  left:=posx
  right:=negx
  repeat while (long[polyptr][i2+1]~>16) == stepy ' find all vertices on this y
    tmp:=long[polyptr][i2+1]&$FFFF
    if stepy == ybottom
      left <#= long[polyptr][i2]
      right #>= long[polyptr][i2]  
    elseif  tmp>= bottid or tmp<topid ' left side?
      left <#= long[polyptr][i2]
    else ' right side?
      right #>= long[polyptr][i2]
    i2+=2

  '' debug section
  if left == posx AND stepy == ybottom
    'left:=topleft
  if right == negx AND stepy == ybottom
    'right:=topright
    
       
  if left <> posx
    tmp := leftslope == negx 
    leftslope := slopeCalc2(left,topleft,stepy,lefty)
    if tmp
      long[topptr] += leftslope
    topleft := left
    lefty:=stepy 
    tmp := head-8 ' previous left slope field
    repeat leftbehind~
      long[tmp]:=leftslope
      tmp -= 12  
  else
    leftbehind++
    
  if right <> negx
    tmp := rightslope == negx
    rightslope := slopeCalc2(right,topright,stepy,righty)
    if tmp
      long[topptr][1] += rightslope
    topright := right
    righty:=stepy
    tmp := head-4 ' previous right slope field
    repeat rightbehind~
      long[tmp]:=rightslope
      tmp -= 12 
  else
    rightbehind++    
  putword(stepy-prevy + ((stepy==ybottom)&1))
  putword(colors)
  putlong(leftslope)
  putlong(rightslope)

  prevy := stepy
}

{
PRI poly_ysort(arr,length) : i | j,i2,zone,arrend,k,realsize,subsize,sizze,temp[2]

  repeat i from 0 to length-1 '' insert original vertex ID into low word of Y
    word[arr+(i<<3)][2] := i 


  '' Non-recursive in-place sorting algorithm
  '' As relayed to me by a friendly Discord user
  '' (ported to spin and optimized by me)
  subsize := 8
  length *= 8
  arrend := arr+length
  repeat while subsize < length
    sizze := subsize<<1
    repeat i from arr to arrend-8 step sizze
      j := i+subsize
      realsize := sizze <# (arrend-i)
      i2 := i
      repeat k from 0 to realsize-8 step 8
        if j => (i+realsize) or i2 => j
          'pass
        elseif long[i2][1] =< long[j][1]'compareNames(arr+i2,arr+j) =< 0
          i2 += 8
        else 
          zone := j
          repeat           
            if (zone+8) == (i+realsize) or long[(zone+8)][1] =< long[i2][1]'compareNames(arr+(zone+8),arr+i2) > 0
              longmove(@temp, i2,2)
              longmove(i2,j,2)
              longmove(j,j+8,(zone-j)>>2)
              longmove(zone,@temp,2)
              if j == zone
                i2 += 8
              else
                k -= 8
              quit   
            zone += 8
    subsize := sizze

    }
'CON POLY_MAXV = 16