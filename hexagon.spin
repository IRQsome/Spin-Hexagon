CON
{{                                                                           
    #############   ###############   ###############   #############          
    #############   ###############   ###############   #############          
  ###############   ###############   ###############   ###############        
  ###############   ###############   ###############   ###############        
  ####              ####       ####         ###         ####       ####        
  ####              ####       ####         ###         ####       ####        
  ###############   ####       ####         ###         ####       ####        
  ###############   ###############         ###         ####       ####        
  ###############   ###############         ###         ####       ####        
             ####   #############           ###         ####       ####        
             ####   #############           ###         ####       ####        
  ###############   ####              ###############   ####       ####        
  ###############   ####              ###############   ####       ####        
  #############     ####              ###############   ####       ####        
  #############     ####              ###############   ####       ####        
                                                                               
                                                                               
                ##    ## ######## ##    ##  ####### ########  ####### #######  
                ##    ## ######## ##    ## ######## ######## ######## ######## 
                ##    ## ##       ##    ## ##    ## ##       ##    ## ##    ## 
                ######## ########  ######  ##    ## ##    ## ##    ## ##    ## 
                ######## ########  ######  ######## ##    ## ##    ## ##    ## 
                ##    ## ##       ##    ## ######## ##    ## ##    ## ##    ## 
                ##    ## ######## ##    ## ##    ## ######## ######## ##    ## 
                ##    ##  ####### ##    ## ##    ## #######  #######  ##    ## 

Release Candidate 4
                
2020 IRQsome Software
Distributed under permission from Terry Cavanagh

Original by Terry Cavanagh
Music by Chipzel
Voice by Jenn Frank

}}                                                                               








_clkmode = xtal1 + pll16x
_xinfreq = 5_000_000
_stack   = 200



CHEATZ = 0 ' 0 for no cheats, 1 for minor cheats, 2 for noclip






 SCANLINE_BUFFER = gfx#SCANLINE_BUFFER
  NUM_LINES = gfx#NUM_LINES
                                               
 border_color                   = gfx#border_color ' border color
 displaylist_adr                = gfx#displaylist_adr 'pointer to display list
 displaylist_in_use             = gfx#displaylist_in_use 'display list adress feedback

 END_OF_DRIVER_RESERVED = gfx#MEMORY_END

 DLIST_SIZE = 640 ' longs

 _free    = ($8000-END_OF_DRIVER_RESERVED+3)/4   

OBJ

gfx : "VJET_v00_composite_wrapper_xasm.spin"
kb  : "Keyboard_xasm.spin"
pst: "DummyPST"'}"Parallax Serial Terminal"
gl  : "VJET_v00_displaylist.spin" 
font: "hexfont.spin"
sdda: "hexagon_sdda.spin"
plat: "platform.spin"

DAT '' pretend this is a VAR (non-zero-initialized variables and some byte/word wide ones go here to help make fastspin happy)
org
random long 42

color1 word $0202
color2 word $0202 
color3 word $0202

sector_angles word 0*(8192/SECTORS),1*(8192/SECTORS),2*(8192/SECTORS),3*(8192/SECTORS),4*(8192/SECTORS),5*(8192/SECTORS)

stage byte 0
state byte TITLE

safe_colors byte false ' change to true when using S-Video (disables $x8 colors)

firstplay_flag byte 0
current_music byte -1

strbuf_hi byte 0[8] ' current stage hiscore string buffer

strbuf_frames byte 0[4] ' current timer string buffers  
strbuf_secs byte 0[4]

strbuf2_frames byte 0[4]
strbuf2_secs byte 0[4] ' misc.

DAT '' some lookup tables and strings

leveltimetbl word
word  0*60 ' Point
word 10*60 ' Line
word 20*60 ' Triangle
word 30*60 ' Square
word 45*60 ' Pentagon
word 60*60 ' Hexagon
word 0 ' convenient zero

levelstringtbl word 
word @point_str
word @line_str
word @triangle_str
word @square_str
word @pentagon_str
word @hexagon_str

stagestringtbl word 
word @hexagon_str
word @hexagoner_str
word @hexagonest_str
word @hexagon_str
word @hexagoner_str
word @hexagonest_str
word @blackwhite_str

stagedifficultytbl word 
word @hard_str
word @harder_str
word @hardest_str
word @hardester_str
word @hardestest_str
word @hardestestest_str
word @hexagon_str

stage2effstage_tbl byte
byte EFF_HEXAGON1,EFF_HEXAGONER1,EFF_HEXAGONEST1,EFF_HEXAGON2,EFF_HEXAGONER2,EFF_HEXAGONEST2,EFF_BLACKWHITE

new_record_str byte "NEW "
record_str byte "RECORD!",0
hyper_str byte "HYPER",0

DAT
long
org
save_space
stage_records long 0[STAGE_COUNT]
long 0[sdda#SAVE_SIZE-STAGE_COUNT] 'reserve some data

org
dlist_space '' Display lists overwrite cog PASM
render_asm file "VJET_v00_rendering.dat"
tv_asm file "VJET_v00_composite.dat"
sdda_asm file "tinySDDA.dat"
keyboard_asm file "Keyboard.dat"

long $00[DLIST_SIZE*2-$]
    
VAR       

long state_timer, game_timer
word script_timer ' the wait times are limited to 15 bits, anyways

long view_scale_y,center_x,center_y
word player_angle 
long playfield_speed
word playfield_rotation

byte effectivestage
byte hitflag
byte playfield_colorswap
byte player_sector
byte colorswap_timer            

long wall_phase
byte wall_spawnpos

word wall_speed,player_speed
long speed_target ' for playfield_speed


word fontptr,subcodeptr

long next_pattern
word patternlist

word script_pc  

byte overflow_flag,commit_record_flag,gameover_newrecord_flag

long framecount
long snes_prev

long polybuf[SECTORS*2*4]
long sector_vx[SECTORS],sector_vy[SECTORS]

'long sector_walls[SECTORS*WALLBUFFER_SIZE]
'long walls_low[SECTORS],walls_high[SECTORS]
byte _dummy,wallbitmap[WALLBUFFER_SIZE]


word dlist1ptr,dlist2ptr


'long dlist1[DLIST_SIZE],dlist2[DLIST_SIZE]

CON '' Enumerations
 #0,HEXAGON,HEXAGONER,HEXAGONEST,HYPER_HEXAGON,HYPER_HEXAGONER,HYPER_HEXAGONEST,BLACKWHITE,STAGE_COUNT 

 #0,EFF_TITLE,EFF_HEXAGON1,EFF_HEXAGON2,EFF_HEXAGON3,EFF_HEXAGONER1,EFF_HEXAGONER2,EFF_HEXAGONER3,EFF_HEXAGONEST1,EFF_HEXAGONEST2,EFF_BLACKWHITE

 #0,TITLE,LEVELSELECT,PLAY,GAMEOVER


PUB main

init
repeat     
  do_frame
  
PRI do_frame | tmp

  gfx.Wait_Vsync
  if overflow_flag~
    tmp:=$CC
  else
    tmp:=$2D
  word[border_color]:=tmp
  ifnot framecount&1
    word[displaylist_adr] := dlist1ptr
    gl.start(dlist2ptr,constant(DLIST_SIZE*4)) 
  else
    word[displaylist_adr] := dlist2ptr
    gl.start(dlist1ptr,constant(DLIST_SIZE*4))
  framecount++
  'framecount &= $1f
  'longmove(current_dlist,@testdlist,128) 
  
  update
  if tmp := \draw
    pst.str(string("ABORT "))
    pst.dec(tmp)
    pst.newline

  if tmp:=gl.done
    overflow_flag~~
    pst.str(string("DLIST OVRFLOW: "))
    pst.dec(tmp)
    pst.newline
   
  
  'pst.str(string("onek "))
  'pst.hex(framecount,8)
  'pst.newline
  word[border_color]:=$04
  'word[@testdlist][1] := 50+(sin(framecount*63)/2048)
  'word[@testdlist][2] := word[@testdlist][1]+20

PRI init
pst.start(115_200)

if sdda.unstash
  subcodeptr:= sdda.sdda_start(@sdda_asm)
else
  subcodeptr:= $8080

' try loading the saved records - remains zero-initialized otherwise
sdda.readsavedata(@save_space)


kb.startx(plat#PS2_DATA,plat#PS2_CLOCK,%0_111_001, %11_11111,@keyboard_asm)
 
word[displaylist_adr] := $8080
''set up graphics driver
gfx.start(plat#TV_PINGROUP,4,@render_asm,@tv_asm) 'start graphics driver

dlist1ptr := @dlist_space
dlist2ptr := @dlist_space+constant(DLIST_SIZE*4)
longfill(@dlist_space,0,constant(DLIST_SIZE*2)) ' this is neccessary to make sure the graphics cogs don't go off the deep end

gl.set_clip(0,gfx#HEIGHT<<16,0,gfx#WIDTH<<16)

fontptr := font.get

clearwalls
  
CON

  PRESCALE_SHL = 6
  PRESCALE = |<PRESCALE_SHL

  PIXEL_ASPECT = 35.5/28.0 '' Aspect ratio of a pixel - empircal measurement
  VIRTUAL_WIDTH = float(gfx#WIDTH)*PIXEL_ASPECT
  VIRTUAL_HEIGHT = float(gfx#HEIGHT)
  PIXEL_ASPECT_FIX  = round(float(posx)/PIXEL_ASPECT)
  
  SECTORS = 6
  WALLBUFFER_SIZE = 48

  WALL_PARKED = negx/2

  PLAYFIELD_RADIUS = 1024


  PATTERN_UNIT = 16

  PATTERN_PTR_MASK = $F_FFFF ' P2 ready!
  PATTERN_CW       = 0
  PATTERN_CCW      = |<31
  PATTERN_OFFSET_SHIFT = 28
  PATTERN_OFFSET_MASK = $7
  PATTERN_WEIGHT_SHIFT = 20
  PATTERN_WEIGHT_MASK = $FF
  OFFSET_RANDOMIZE  = 6
  OFFSET_RANDOMIZE2 = 7 'also randomize direction

  SPEED_SMOOTHING = 6
  
  
  HEXAGON1_RADIUS_UNSCALED = 22 ' measured
  HEXAGON1_RADIUS = HEXAGON1_RADIUS_UNSCALED * PRESCALE 
  PLAYER_RADIUS_UNSCALED = 28 ' measured
  PLAYER_RADIUS = PLAYER_RADIUS_UNSCALED * PRESCALE
  PLAYER_RADIUS_WALLSPACE = $10000*(PLAYER_RADIUS_UNSCALED-HEXAGON1_RADIUS_UNSCALED)/WALL_UNIT_UNSCALED 
  WALL_UNIT_UNSCALED = 16
  WALL_UNIT = WALL_UNIT_UNSCALED * PRESCALE 
  TEST1_RADIUS = 64 * PRESCALE

  PLAYER_RADIUS_INNER = float(PLAYER_RADIUS_UNSCALED)*((^^3.0)/2.0)
  WALLDRAW_RADIUS = trunc(^^((VIRTUAL_WIDTH*VIRTUAL_WIDTH+VIRTUAL_HEIGHT*VIRTUAL_HEIGHT)/4.0)-PLAYER_RADIUS_INNER+float(PLAYER_RADIUS_UNSCALED))'200
  WALLDRAW_MAX = WALLDRAW_RADIUS/WALL_UNIT_UNSCALED+2

  WALLSPAWN_MAX = 15 ' should be larger than WALLDRAW_MAX to avoid pop-in
   
PRI clearwalls
'longfill(@sector_walls,WALL_PARKED,SECTORS*WALLBUFFER_SIZE)
'wall_phase := $D0000

'longfill(@walls_low,0,constant(SECTORS*2)) ' fill both walls_low and walls_high
bytefill(@wallbitmap,0,WALLBUFFER_SIZE)
wall_phase := 0
wall_spawnpos := WALLSPAWN_MAX

{PRI testwalls | i
clearwalls
repeat i from 0 to constant(WALLBUFFER_SIZE-1)
  'wallbitmap[i] |= ($99 << (i&1))&$1F
   wallbitmap[i] := $49249249 >> i

}

PRI try_spawn_pattern |i,tmp,wptr,offset,ccw,size

'pst.str(string(13,"Attempting spawn... "))
'pst.dec(wall_spawnpos)
'pst.char(" ")
'pst.hex(next_pattern,4)
'pst.char(" ")

if wall_spawnpos => WALLSPAWN_MAX ' don't spawn too far ahead
  return
wptr := next_pattern'&PATTERN_PTR_MASK
'pst.str(string("okay... "))
if (size:=byte[wptr++]) + wall_spawnpos => WALLBUFFER_SIZE ' check if there are enough free slots
  return
'pst.str(string("WE'RE IN! "))
' prepare
offset := (next_pattern>>PATTERN_OFFSET_SHIFT)&PATTERN_OFFSET_MASK
ccw:=next_pattern & PATTERN_CCW

if offset => OFFSET_RANDOMIZE
  if offset => OFFSET_RANDOMIZE2
    if (random?)&4
      NOT ccw
  offset := (random?&posx)//SECTORS

pst.dec(offset)

if ccw ' Adjust offset for CCW so sector 0 stays sector 0
  if (offset+=1) => SECTORS
    offset:=0 
  

'' actually perform spawning
repeat i from wall_spawnpos to wall_spawnpos+size-1
  tmp := byte[wptr++]
  if ccw
    tmp ><= SECTORS
  wallbitmap[i] := (tmp<<offset + tmp>>(SECTORS-offset))&constant((|<SECTORS)-1)

wall_spawnpos += byte[wptr] ' spacing

{pst.str(string("spacing: "))
pst.dec(byte[wptr])
pst.newline }
next_pattern~
 
PRI select_pattern(pattern_list) : pat | i,weight

'' sum total weight
i~
weight~
repeat while pat:=long[pattern_list][i++]
  weight+= (pat>>PATTERN_WEIGHT_SHIFT)&PATTERN_WEIGHT_MASK

weight := (random?&posx) // weight

i~
repeat
  pat:=long[pattern_list][i++]
  if (weight -= (pat>>PATTERN_WEIGHT_SHIFT)&PATTERN_WEIGHT_MASK)<0
    quit

CON

HUECALC_LEFTSAR = 16+3-4
HUECALC_RIGHTSAR = HUECALC_LEFTSAR - 8 -1

PRI huecalc(angl,swing,center) | tmp
tmp := sin(angl)
tmp += tmp~>14
'result := ((tmp~+constant(14-4))&$F0) + (((tmp+$10000)~>constant(14-(4+8)))&$F000)
result := ((((tmp+$0000)*swing)~>HUECALC_LEFTSAR) & $F0) + ((((((tmp+$0000)*swing)~>HUECALC_RIGHTSAR)+$800)~>1) & $F000)
result += center
result &= $F0F0

PRI update | i,j,tmp,tmp2,snes,sectorchange_flag,oldsector,clip_angle,huetmp,lkey,rkey,snes_trigger

'pst.str(string("update!",13))

if plat#SNES_PLAYER1 =>0
  snes := SNES_Read_Gamepad
else
  snes~
snes_trigger:=snes&!snes_prev

lkey := kb.keystate($C0) OR snes&constant(SNES_LEFT|SNES_L)
rkey := kb.keystate($C1) OR snes&constant(SNES_RIGHT|SNES_R)

random? ' RNG dummy tick

{ '' Old code - ressurect this if you want to add pentagon/square playfield
sector_angles[0]:=0 ' first sector is always zero to make life easier
repeat i from 1 to constant(SECTORS-1)
  sector_angles[i] := i*constant(8192/SECTORS)
}

center_x := constant(128<<16)
center_y := constant(119<<16)
view_scale_y:= constant( negx >> ((PRESCALE_SHL-1)) )

{
pst.str(string("Time: ")) 
pst.dec(game_timer/60)
pst.char(":")  
pst.dec(game_timer//60)
pst.newline}

time2dualstr(game_timer,@strbuf_frames) 
              
case state
  PLAY:
    
    if state_timer == 1 ' safe to update strbuf_hi
      update_strbuf_hi
      sdda.play_sfx(sdda#SFX_BEGIN)
     
    if state_timer<15
      view_scale_y:=(view_scale_y ** (((15+1)-game_timer)*trunc(float(posx)/10.0*5.0/128.0))) << 8
    else
      view_scale_y+=byte[subcodeptr]<<17

    ifnot game_timer
      player_angle:=constant((8192/(SECTORS*2))/3)

    '' stage script interpreter
    '' see explanation further down
    repeat
      case tmp2:=word[script_pc]
        $0000..$1FFF: '' SCRIPT_SPIN
          speed_target := (tmp2<<19)~>19
        $2000..$3FFF: '' SCRIPT_POS
          playfield_rotation := tmp2&8191
        $4000..$FFEF: '' SCRIPT_WAIT
          if script_timer < tmp2-$4000
            quit
        $FFF0..$FFFF: '' special commands
          tmp := word[script_pc+=2]
          case tmp2&$F
            $0: '' SCRIPT_CMD_JMP
              script_pc:=@@tmp-2
              script_timer~
            $1: '' SCRIPT_CMD_EFFSTAGE
              effectivestage := tmp
            $2: '' SCRIPT_CMD_PATTERNS
              patternlist := @@tmp
            $3: '' SCRIPT_CMD_WALLSPEED
              wall_speed := tmp
            $4: '' SCRIPT_CMD_PLAYERSPEED
              player_speed := tmp
            $5: '' SCRIPT_CMD_MUSIC
              '' TODO: evaluate firstplay_flag
              if tmp <> current_music
                sdda.play_music(current_music:=tmp)
      script_pc+=2
    script_timer++
     
    '' find player's sector
    player_sector~
    repeat i from 0 to constant(SECTORS-1)
       if sector_angles[i] =< player_angle
          player_sector := i
     
    '' move player
    if lkey
      player_angle -= player_speed
    if rkey
      player_angle += player_speed
    player_angle&=8191
     
    {
    pst.str(string("before: "))
    pst.dec(player_sector)
    pst.newline
    }
    '' check for sector change
    sectorchange_flag~                            
    oldsector := player_sector
    if player_sector == 0 AND player_angle => sector_angles[constant(SECTORS-1)] ' special case
        player_sector := constant(SECTORS-1)
        clip_angle := 0
        sectorchange_flag~~
    elseif player_sector == constant(SECTORS-1) AND player_angle < sector_angles[1] ' special case
      player_sector := 0
      clip_angle := 8191
      sectorchange_flag~~
    elseif player_sector <> 0 AND player_angle < sector_angles[player_sector]
      clip_angle:=sector_angles[player_sector]
      player_sector--
      sectorchange_flag~~
    elseif player_sector <> constant(SECTORS-1) AND player_angle => sector_angles[player_sector+1]
      player_sector++
      clip_angle := sector_angles[player_sector]-1
      sectorchange_flag~~ 
    {
    pst.str(string("after: "))
    pst.dec(player_sector)
    pst.newline
     
    pst.str(string("flag: "))
    pst.dec(sectorchange_flag)
    pst.newline
    }
    '' check for walls in new sector (to clip when moving sideways into a wall)
    if sectorchange_flag
      if wallbitmap[1] & |<player_sector
        player_sector := oldsector
        player_angle := clip_angle
     
      
     
     
     
     
    '' Move walls closer and kill player
    wall_phase -= wall_speed
    if wall_phase < 0
      tmp:= ((-wall_phase)>>16) <# constant(WALLBUFFER_SIZE-1)
      bytemove(@wallbitmap,@wallbitmap+tmp,WALLBUFFER_SIZE-tmp)
      bytefill(@wallbitmap+WALLBUFFER_SIZE-tmp,0,tmp)
      wall_phase += tmp<<16
      wall_spawnpos -= tmp
      if CHEATZ < 2
        hitflag OR= wallbitmap[1] & |<player_sector

    {
    pst.str(string("phase: "))
    pst.hex(wall_phase,8)
    pst.newline
    pst.str(string("next: "))
    pst.hex(next_pattern,8)
    pst.str(string("list: "))
    pst.hex(patternlist,4)
    pst.newline
    }
    
    'patternlist := @whirlpool2_only''DEBUG!
     
    '' select next pattern
    if (NOT next_pattern) AND patternlist
      next_pattern := @@0+select_pattern(patternlist)        
     
    '' try spawning next pattern
    if next_pattern
      try_spawn_pattern 

    '' Handle timer-related SFX
    if game_timer==stage_records[stage]+1 and game_timer<>1
      sdda.play_sfx(sdda#SFX_EXCELLENT)
    elseif tmp := time2level(game_timer)
      if leveltimetbl.word[tmp] == game_timer
        sdda.play_sfx(constant(sdda#SFX_LINE-1)+tmp)
    
    game_timer++
  GAMEOVER:
    ifnot state_timer
      time2dualstr(stage_records[stage],@strbuf2_frames) ' write best time string
      sdda.play_music(current_music:=-1)
      sdda.play_sfx(sdda#SFX_GAMEOVER)
    if state_timer => 60
      view_scale_y:=(view_scale_y ** (((state_timer<#constant(60+10))-56)*trunc(float(posx)/10.0*3.0/128.0))) << 8
      if state_timer < constant(60+10)
        wall_phase+=$8000
        speed_target:= -GAMEOVER_SPIN
    if state_timer == 69 'nice
      try_commit_record
  LEVELSELECT:
    firstplay_flag~~
    center_y := constant(188<<16)
    player_angle := -playfield_rotation+4096
    view_scale_y<<=1
    tmp:=constant(-8192/SECTORS)*stage + constant(8192/(SECTORS*2)*3)
    ifnot state_timer
      playfield_rotation:=tmp
    speed_target:=((tmp-playfield_rotation)<<19)~>19
    if ||speed_target < 64
      if lkey
        if stage-- == 0 ' Do this because stage is a byte
          stage:=HYPER_HEXAGONEST
      if rkey
        if ++stage > HYPER_HEXAGONEST
          stage:=0
      if lkey or rkey
        sdda.play_sfx(sdda#SFX_CHOOSE)
    if ||speed_target < 11
      speed_target:=playfield_speed:=0
      playfield_rotation:=tmp
    elseif speed_target < 0 
      speed_target:=-71
    else
      speed_target:=71
    tmp := stage2effstage_tbl.byte[stage]
    if is_current_locked
      tmp := EFF_TITLE
    effectivestage:=tmp
  TITLE:
    center_y := constant(238<<16)
    view_scale_y<<=2
    player_angle := -playfield_rotation ' moves player out of frame
    speed_target := -20 '' TODO
    effectivestage := EFF_TITLE
    if state_timer==60
      sdda.play_sfx(sdda#SFX_TITLE)
    

'' select colors
'effectivestage := EFF_HEXAGONER3 ''DEBUG!

tmp:=@effstage_color_tbl+effectivestage<<3 ' calc table base address
huetmp := word[tmp][3] ' get huecalc_center
if huetmp&$0100 ' colorswap flag? 
  if ++colorswap_timer => 45 ' measured
    colorswap_timer~
    NOT playfield_colorswap
else
  playfield_colorswap:=colorswap_timer:=0 

if tmp2:=(huetmp&$F)
  huetmp:= huecalc(framecount*huecalc_tbl.byte[tmp2<<1],huecalc_tbl.byte[tmp2<<1+1],huetmp&$F0F0)
else
  huetmp:= (framecount&$F0)+((framecount+$8)&$F0)<<8 '' Taste the rainbow

color1:=word[tmp][0]+huetmp
color2:=word[tmp][1]+huetmp
if NOT safe_colors AND effectivestage==EFF_HEXAGONER2
  color3:=$8888^huetmp
else
  color3:=word[tmp][2]+huetmp
    
'pst.hex(huetmp,8)
    'pst.newline



if speed_target==SPINSPEED_BW_SPECIAL ' special case
  playfield_speed := (((constant(-1*8192/2/SECTORS)-playfield_rotation)&8191)+31)>>5
else 'smooth out speed 
  tmp:=speed_target-playfield_speed
  if tmp<0
    playfield_speed += (tmp-constant(SPEED_SMOOTHING-1))/SPEED_SMOOTHING
  elseif tmp>0
    playfield_speed += (tmp+constant(SPEED_SMOOTHING-1))/SPEED_SMOOTHING
   
playfield_rotation += playfield_speed

state_timer++
      
   
repeat while kb.gotkey OR snes_trigger
  if snes_trigger
    tmp~
    case i:=(|<((>|snes_trigger)-1))
      SNES_A: tmp:=" "
      SNES_X: tmp:="n"
      SNES_Y: tmp:="b"
      SNES_SELECT: tmp:=$DC
      SNES_START: tmp:= $CB    
    
    snes_trigger &= !i     
  else
    tmp := kb.key
  pst.dec(tmp)
  pst.newline  
  case tmp
    $CB: ' Esc
      if state==PLAY
        hitflag~~
      elseif state==GAMEOVER
        try_commit_record
        clearwalls
        state_timer~
        state:=LEVELSELECT
        sdda.play_sfx(sdda#SFX_BACK)
      elseif state==LEVELSELECT
        state_timer~
        state:=TITLE         
        sdda.play_sfx(sdda#SFX_BACK)
    "t":
      if CHEATZ
        game_timer+= 60
        script_timer += 60
    " ": ' Space
      if state==TITLE
        state_timer~
        state:=LEVELSELECT
        sdda.play_sfx(sdda#SFX_SELECT)
      elseif (state==GAMEOVER AND state_timer => 60) OR (state==LEVELSELECT and NOT is_current_locked)
        try_commit_record
        if stage == HEXAGON AND NOT is_locked(BLACKWHITE) AND lkey AND rkey
          stage:=BLACKWHITE
        clearwalls
        game_timer~
        state_timer~
        script_timer~
        script_pc := @@script_init_tbl.word[stage]
        next_pattern~
        state:=PLAY
    $DC: ' printscreen
      gfx.toggle_mode
    $6C9: 'Ctrl-Alt-Del : Quit gracefully!
      if state == GAMEOVER
        try_commit_record
      reboot
    other: 'ignore
   
if hitflag~
  state := GAMEOVER
  state_timer~
  commit_record_flag~~
  gameover_newrecord_flag:= stage_records[stage] < game_timer 

  
snes_prev:=snes

PRI is_current_locked
return is_locked(stage)

PRI is_locked(which)
ifnot CHEATZ
  case which              
    HYPER_HEXAGON..HYPER_HEXAGONEST:result:= stage_records[which-3] < constant(60*60)
    BLACKWHITE: result:= stage_records[HYPER_HEXAGONEST] < constant(60*60)

DAT
org
effstage_color_tbl word
''   color1 color2 color3 huecalc_center+colorswap flag
word $0303, $0404, $0505, $0000 ' EFF_TITLE
word $0A0A, $0B0B, $0D0D, $9091 ' EFF_HEXAGON1
word $0A0A, $0B0B, $0D0D, $1021 ' EFF_HEXAGON2
word $0A0A, $0B0B, $0D0D, $C0D1 ' EFF_HEXAGON3
word $0202, $0B0B, $0E0E, $5162 ' EFF_HEXAGONER1
word $0707, $0E0E, $0C0C, $D1D2 ' EFF_HEXAGONER2 (see special case color3 for NOT safe_colors)
word $0B0B, $0D0D, $0707, $D1D2 ' EFF_HEXAGONER3
word $0B0B, $0C0C, $0E0E, $0100 ' EFF_HEXAGONEST1
word $0404, $0505, $0707, $0100 ' EFF_HEXAGONEST2
word $0202, $0202, $0707, $0000 ' EFF_BLACKWHITE

huecalc_tbl byte '' indexed by bottom bits of huecalc_center
''   speed,range
byte  0, 0
byte 35,10
byte 20,20


PRI try_commit_record

if commit_record_flag~
  stage_records[stage] #>= game_timer
  ifnot CHEATZ
    sdda.writesavedata(@save_space)


PRI draw

if state_timer < 5 ' Flash?
  gl.triangle(constant((gfx#WIDTH/2)<<16),constant(-gfx#HEIGHT<<16),constant(-gfx#WIDTH<<16),constant(gfx#HEIGHT<<16),constant(2*gfx#WIDTH<<16),constant(gfx#HEIGHT<<16),$0707)
else
  draw_game
  if state == PLAY OR (state == GAMEOVER AND state_timer < 60) 
    draw_hud
  elseif state == GAMEOVER AND state_timer=>70
    draw_gameover
  elseif state == LEVELSELECT
    draw_levelselect
  elseif state == TITLE
    draw_title
return 0 ' dont trigger ABORT handler

PRI draw_game : view_scale_x |i,i2,j,tmp,rad,ibuf,wallactive,adjflag,tmp2,rscl1x,rscl1y,rscl2x,rscl2y',polybuf[SECTORS*2]

view_scale_x := (view_scale_y ** PIXEL_ASPECT_FIX)<<1
'' update/draw playfield
repeat i from 0 to constant(SECTORS-1)
  tmp:=  sector_angles[i]+playfield_rotation
  sector_vx[i] := ((-sin(tmp))<<PRESCALE_SHL)**view_scale_x
  sector_vy[i] := (sin(tmp+2048)<<PRESCALE_SHL)**view_scale_y
 
'' background
repeat i from 0 to constant(SECTORS-1)
  if 0'i==player_sector
    tmp2:=$7D7D
  elseif (playfield_colorswap^i)&1
    tmp2 := color1
  else
    tmp2 := color2
  if (i2 := i+1) => SECTORS
    i2 -= SECTORS    
  gl.triangle(center_x,center_y,{
  }center_x+sector_vx[i]*PLAYFIELD_RADIUS,center_y+sector_vy[i]*PLAYFIELD_RADIUS,{
  }center_x+sector_vx[i2]*PLAYFIELD_RADIUS,center_y+sector_vy[i2]*PLAYFIELD_RADIUS,tmp2)
 
 
'' central hexagon                   
repeat i from 0 to constant(SECTORS-1)
  polybuf[i<<1] := center_x + sector_vx[i]*HEXAGON1_RADIUS_UNSCALED
  polybuf[i<<1+1] := center_y + sector_vy[i]*HEXAGON1_RADIUS_UNSCALED
gl.polygon(@polybuf,SECTORS,color1)
gl.line_polygon(@polybuf,SECTORS,color3)
 
'' walls
wallactive~
repeat j from WALLDRAW_MAX to -1
  tmp2:=wallbitmap[j]
  if (tmp := ((j)<<16)+wall_phase+PLAYER_RADIUS_WALLSPACE) < -$0_0000
    tmp2~
  ifnot (tmp2)^wallactive
    next
  rad:=HEXAGON1_RADIUS_UNSCALED + (tmp*WALL_UNIT_UNSCALED) ~>constant(16)
  adjflag~
  repeat i from 0 to constant(SECTORS-1)
    if (i2 := i+1) => SECTORS
        i2 -= SECTORS
    ibuf := @polybuf+i<<5      
    if tmp2 & |<i AND NOT (wallactive & |<i) ' wall starts, generate outer vertices
      
      ' outer 1
      if adjflag
        longmove(ibuf,adjflag,2)
      else
        long[ibuf][0] := center_x + sector_vx[i]*rad
        long[ibuf][1] := center_y + sector_vy[i]*rad
       
      ' outer 2
      long[ibuf][2] := center_x + sector_vx[i2]*rad
      long[ibuf][3] := center_y + sector_vy[i2]*rad
      adjflag:=ibuf+constant(2*4)
    elseif !tmp2 & |<i AND (wallactive & |<i) 'wall ends, generate inner vertices and submit
      ' inner vertices' X
      if adjflag
        longmove(ibuf+constant(6*4),adjflag,2)
      else
        long[ibuf][6] := center_x + sector_vx[i]* (rad#>HEXAGON1_RADIUS_UNSCALED)
      long[ibuf][4] := center_x + sector_vx[i2]*(rad#>HEXAGON1_RADIUS_UNSCALED)
       
      if (long[ibuf][6]#>long[ibuf][4]) < 0
        'pst.str(string("skip 1",13))
        adjflag~
        next ' perform X clipping because the GL doesn't, lol
      if (long[ibuf][6]<#long[ibuf][4]) => constant(gfx#WIDTH<<16)
        'pst.str(string("skip 2",13))
        adjflag~
        next ' perform X clipping because the GL doesn't, lol
      ' inner vertices' Y
      ifnot adjflag                                 
        long[ibuf][7] := center_y + sector_vy[i]* (rad#>HEXAGON1_RADIUS_UNSCALED)
      long[ibuf][5] := center_y + sector_vy[i2]*(rad#>HEXAGON1_RADIUS_UNSCALED)
      {pst.str(string("submitting poly... "))
      pst.dec(j)
      pst.char(" ")
      pst.dec(i)
      pst.char(" ")
      pst.dec(ibuf - @polybuf)
      pst.newline}         
      gl.polygon(ibuf,4,color3)
      adjflag:= ibuf+constant(4*4)
    else
      adjflag~
  wallactive:=tmp2

 
''player
tmp :=  (-sin(player_angle+playfield_rotation) << PRESCALE_SHL)**view_scale_x
tmp2 := (sin(player_angle+playfield_rotation+2048) << PRESCALE_SHL)**view_scale_y        
rscl1x := tmp*constant(PLAYER_RADIUS_UNSCALED-4)
rscl1y := tmp2*constant(PLAYER_RADIUS_UNSCALED-4)
rscl2x := tmp2*3
rscl2y := tmp*3                                             
gl.triangle(center_x + (tmp*PLAYER_RADIUS_UNSCALED),center_y + (tmp2*PLAYER_RADIUS_UNSCALED),{
           }center_x + rscl1x + rscl2x ,{            
           }center_y + rscl1y - rscl2y ,{
           }center_x + rscl1x - rscl2x ,{            
           }center_y + rscl1y + rscl2y ,color3)

PRI draw_hud : lev | tmp,tmp2,ttx,barleft,barright,blink 
'' HUD
if game_timer=>constant(100*60)
  tmp:=constant(4*8)
  ttx:=constant(142-18)
else
  tmp:=0
  ttx:=142
gl.polygon(@hud_topright_poly1+tmp,4,$0202)
gl.polygon(@hud_topright_poly2+tmp,4,$0202)
gl.polygon(@hud_topleft_poly,4,$0202)
 
gl.text_inline(224,constant(4+8),0,0,@strbuf_frames,fontptr,$0707)                                 
gl.text_inline(174,4,1,1,@strbuf_secs,fontptr,$0707)

tmp := string(" TIME") 
if stage => HYPER_HEXAGON
  tmp := @hyper_str

gl.text(ttx,4,0,0,tmp,fontptr,$0707) 

blink~

if (barright:=stage_records[stage]) => {1'}constant(60*60)
  barleft:=0
  tmp:=@strbuf_hi
  if (blink:=barright - game_timer) < 0
    tmp:=@record_str
                              
else 
  lev := time2level(game_timer)
  barleft:=leveltimetbl.word[lev]
  barright:=leveltimetbl.word[lev+1]
  if lev
    blink:=barleft-game_timer
  else
    blink:=1
  tmp:=@@levelstringtbl.word[lev]
'gl.text(10,4,0,0,tmp,fontptr,$0707)
if state_timer&8 AND (blink > -45 AND blink =< 0)
  tmp2:=$0505
else
  tmp2:=$0707
gl.text_centered(46,4,0,0,tmp,fontptr,tmp2)
  
  

if barright
  tmp := constant(10<<16)+(((game_timer-barleft)<<16)/(barright-barleft) <# $1_0000)*71
  gl.line(constant(10<<16),constant(14<<16),tmp,constant(14<<16),color3)
  gl.line(tmp,constant(14<<16),constant(81<<16),constant(14<<16),color2) 
else        
  gl.line(constant(10<<16),constant(14<<16),constant(81<<16),constant(14<<16),color3)

DAT
org
hud_topright_poly1
long 133<<16, -1<<16
long 260<<16, -1<<16 
long 260<<16, 15<<16
long 141<<16, 15<<16
hud_topright_poly1_big
long 115<<16, -1<<16
long 260<<16, -1<<16 
long 260<<16, 15<<16
long 123<<16, 15<<16

hud_topright_poly2
long 185<<16, 15<<16
long 260<<16, 15<<16  
long 260<<16, 23<<16
long 189<<16, 23<<16
hud_topright_poly2_big
long 167<<16, 15<<16
long 260<<16, 15<<16  
long 260<<16, 23<<16
long 171<<16, 23<<16
       
hud_topleft_poly
long  96<<16, -5<<16
long  -4<<16, -5<<16   
long  -4<<16, 15<<16
long  86<<16, 15<<16

PRI draw_gameover | lev,i,delta,angl,tmp,tmp2,fonttmp
fonttmp:=fontptr
gl.polygon(@gameover_last_poly1,4,$0202)
gl.polygon(@gameover_last_poly2,4,$0202)         
gl.text(116, 75,0,0,string("LAST"),fonttmp,$0707)

gl.text_inline(224,constant(76+8),0,0,@strbuf_frames,fonttmp,$0707)                                 
gl.text_inline(172,76,1,1,@strbuf_secs,fonttmp,$0707)  
gl.polygon(@gameover_best_poly1,4,$0202)  
if gameover_newrecord_flag
  gl.text(138,125,0,0,@new_record_str,fonttmp,$0707)
else
  gl.polygon(@gameover_best_poly2,4,$0202)
  gl.text(129,125,0,0,string("BEST"),fonttmp,$0707)
  gl.text(224,constant(126+8),0,0,@strbuf2_frames,fonttmp,$0707)                                 
  gl.text(172,126,1,1,@strbuf2_secs,fonttmp,$0707)

gl.polygon(@gameover_big_poly,4,$0202)      
lev := time2level(stage_records[stage])
tmp:=string("LEVEL N")
byte[tmp][6] := "1"+lev
gl.text_inline( 13, 75,0,0,tmp,fonttmp,$0707)
gl.text_ljust( 85, 84,0,0,@@levelstringtbl.word[lev],fonttmp,$0707)

'' draw regular polygon, lol

if lev <> 0
  tmp:=lev
  tmp2:=GAMEOVER_POLY_RADIUS
  angl:=playfield_rotation
else
  tmp:=3
  tmp2:=1
  angl:=0
delta:=8192/(tmp+1)
repeat i from 0 to tmp
  polybuf[i<<1]   := GAMEOVER_POLY_X+((-sin(angl)*tmp2)<<1)**PIXEL_ASPECT_FIX
  polybuf[i<<1+1] := GAMEOVER_POLY_Y+(sin(angl+2048)*tmp2)
  angl+=delta
     
gl.line_polygon(@polybuf,tmp+1,color3) 

CON

GAMEOVER_POLY_X = 54<<16
GAMEOVER_POLY_Y = 118<<16
GAMEOVER_POLY_RADIUS = 24

DAT
org
gameover_best_poly1 long
long 121<<16,121<<16
long 260<<16,121<<16 
long 260<<16,137<<16
long 129<<16,137<<16

gameover_best_poly2 long
long 167<<16,137<<16
long 260<<16,137<<16  
long 260<<16,145<<16
long 171<<16,145<<16

gameover_last_poly1 long
long 106<<16, 71<<16
long 260<<16, 71<<16 
long 260<<16, 87<<16
long 114<<16, 87<<16

gameover_last_poly2 long
long 167<<16, 87<<16
long 260<<16, 87<<16  
long 260<<16, 95<<16
long 171<<16, 95<<16

gameover_big_poly long
long  82<<16, 71<<16
long  -4<<16, 71<<16
long  -4<<16,145<<16
long 119<<16,145<<16

PRI draw_levelselect | fonttmp,stn,locked
fonttmp:=fontptr
if locked:=is_current_locked
  stn := string("LOCKED")  
else
  stn := @@stagestringtbl.word[stage]
gl.polygon(@levelselect_poly,4,$0202)
gl.text_centered(128,42,1,1,stn,fonttmp,color3)
ifnot locked
  if stage => HYPER_HEXAGON
    gl.polygon(@levelselect_poly_hyper,4,$0202)
    gl.text(200,31,0,0,@hyper_str,fonttmp,color3)
   
  gl.text(10,60,0,0,string("DIFFICULTY:"),fonttmp,$0505)
  gl.text(constant(10+12*9),60,0,0,@@stagedifficultytbl.word[stage],fonttmp,$0707)
  update_strbuf_hi
  gl.text(10,69,0,0,string("BEST TIME:"),fonttmp,$0505)
  gl.text_inline(constant(10+12*9),69,0,0,@strbuf_hi,fonttmp,$0707)
   
DAT
org
levelselect_poly long
long  -4<<16, 37<<16
long 260<<16, 37<<16 
long 260<<16,101<<16
long  -4<<16,101<<16

levelselect_poly_hyper long
long 186<<16, 29<<16
long 260<<16, 29<<16 
long 260<<16, 37<<16
long 190<<16, 37<<16

CON
LOGO_X = 52
LOGO_Y = 64
PRI draw_title | fonttmp
fonttmp:=fontptr
gl.text(LOGO_X,LOGO_Y,2,2,string("SPIN"),fonttmp,$0707)
gl.text(constant(LOGO_X+28),constant(LOGO_Y+34),1,1,string("HEXAGON"),fonttmp,$0707)
gl.text(12,216,0,0,string("V1.0 RC4"),fonttmp,$0707) 

PUB sin(angle) : s | c,z
              'angle: 0..8192 = 360°
  s := angle
  if angle & $800
    s := -s
  s |= $E000>>1
  s <<= 1
  s := word[s]
  if angle & $1000
    s := -s                    ' return sin = -$FFFF..+$FFFF 

PRI update_strbuf_hi | tmp,tmp2,spaces
spaces:=2
tmp2:=stage_records[stage]
tmp := tmp2//60
tmp2:= tmp2/60
strbuf_hi[4] := ":"
strbuf_hi[5] := "0"+tmp/10
strbuf_hi[6] := "0"+tmp//10
if tmp2 => 100 ' WTF?
  spaces:=1
  if tmp2 => 1000
    spaces:=0
    strbuf_hi[0] := "0"+tmp2/1000
    tmp2//=1000 
  strbuf_hi[1] := "0"+tmp2/100
  tmp2//=100 
strbuf_hi[2] := "0"+tmp2/10
strbuf_hi[3] := "0"+tmp2//10
strbuf_hi[7] := 0
bytemove(@strbuf_hi,@strbuf_hi+spaces,8-spaces)

PRI time2dualstr(time,bufptr) | frames,seconds
seconds:= time/60
frames := time//60
byte[bufptr][0] := ":"
byte[bufptr][1] := "0"+frames/10
byte[bufptr][2] := "0"+frames//10
byte[bufptr][3] := 0
 
if seconds > 99 
  byte[bufptr][4] := "0"+((seconds/100)<#9)
  seconds//=100
else
  byte[bufptr][4] := " "
byte[bufptr][5] := "0"+seconds/10
byte[bufptr][6] := "0"+seconds//10 
byte[bufptr][7] := 0 

PRI time2level(frames) | tmp
tmp:=frames
if (tmp-=constant(10*60)) < 0
  return 0   
elseif (tmp-=constant(10*60)) < 0
  return 1       
elseif (tmp-=constant(10*60)) < 0
  return 2      
elseif (tmp-=constant(15*60)) < 0
  return 3        
elseif (tmp-=constant(15*60)) < 0
  return 4
else
  return 5     


DAT
org

point_str    byte "POINT",0
line_str     byte "LINE",0
triangle_str byte "TRIANGLE",0
square_str   byte "SQUARE",0
pentagon_str byte "PENTAGON",0
blackwhite_str byte "FINAL "
hexagon_str  byte "HEXAGON",0
hexagoner_str  byte "HEXAGONER",0
hexagonest_str  byte "HEXAGONEST",0

hard_str byte "HARD",0
harder_str byte "HARDER",0
hardest_str byte "HARDEST",0
hardester_str byte "HARDESTER",0
hardestest_str byte "HARDESTEST",0
hardestestest_str byte "HARDESTESTEST",0

CON
{{
Script format:
word $XXXX where X is $0000..$1FFF : set spin speed to X (sign-extended)
word $XXXX where X is $2000..$3FFF : set spin position to X&8191
word $XXXX where X is $4000..$FFEF : wait until script_timer => (X-$4000)
word $FFFX : special command X

special command 0: clear script_timer and jump to X
word @X

special command 1: set effectivestage X
word X

special command 2: set pattern list X
word @X

special command 3: set wall speed
word X

special command 4: set player speed
word X

special command 5: set music
word sdda#MUSIC_X

}}
SCRIPT_SPIN = $0000
SCRIPT_SPINMASK = $1FFF
SCRIPT_POS  = $2000
SCRIPT_POSMASK  = $1FFF ' 8191
SCRIPT_WAIT = $4000
SCRIPT_CMD_JMP = $FFF0
SCRIPT_CMD_EFFSTAGE = $FFF1
SCRIPT_CMD_PATTERNS = $FFF2
SCRIPT_CMD_WALLSPEED = $FFF3
SCRIPT_CMD_PLAYERSPEED = $FFF4
SCRIPT_CMD_MUSIC = $FFF5

SPINSPEED_BW_SPECIAL = -4096

PLAYERSPEED_NORMAL = 8192/(SECTORS*8) ' measured
PLAYERSPEED_FAST   = 8192/(SECTORS*6) ' measured

SECTOR_ANGLE_F = 8192.0 / float(SECTORS)

GAMEOVER_SPIN = round(SECTOR_ANGLE_F/60.0)                     

HEXAGON_SPIN_SLOW = round(SECTOR_ANGLE_F/60.0)
HEXAGON_SPIN = round(SECTOR_ANGLE_F/30.0)

HYPER_HEXAGON_SPIN = round(SECTOR_ANGLE_F/20.0)

HEXAGONER_SPIN_SLOW = round(SECTOR_ANGLE_F/60.0)
HEXAGONER_SPIN = round(SECTOR_ANGLE_F/30.0)

HYPER_HEXAGONER_SPIN = round(SECTOR_ANGLE_F/20.0)

HEXAGONEST_SPIN_SLOW = round(SECTOR_ANGLE_F/30.0)
HEXAGONEST_SPIN = round(SECTOR_ANGLE_F/20.0)
HEXAGONEST_SPIN_FAST = round(SECTOR_ANGLE_F/8.0)

HYPER_HEXAGONEST_SPIN_SLOW = round(SECTOR_ANGLE_F/20.0)
HYPER_HEXAGONEST_SPIN = round(SECTOR_ANGLE_F/15.0)


DAT
org
script_init_tbl word
word @script_hexagon ' Hexagon
word @script_hexagoner ' Hexagoner
word @script_hexagonest ' Hexagonest
word @script_hyper_hexagon ' Hyper Hexagon
word @script_hyper_hexagoner ' Hyper Hexagoner
word @script_hyper_hexagonest ' Hyper Hexagonest
word @script_blackwhite ' BW


script_hexagon
word SCRIPT_CMD_EFFSTAGE, EFF_HEXAGON1
word SCRIPT_CMD_MUSIC, sdda#MUSIC_COURTESY
word SCRIPT_CMD_PATTERNS, @hexagon_patterns_simple
word SCRIPT_CMD_WALLSPEED, $1B00 'assumption?
word SCRIPT_CMD_PLAYERSPEED, PLAYERSPEED_NORMAL
word SCRIPT_SPIN+( +HEXAGON_SPIN_SLOW &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*7+30 ' Rough
word SCRIPT_SPIN+( -HEXAGON_SPIN_SLOW &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*10 ' Exact
word SCRIPT_SPIN+( +HEXAGON_SPIN &SCRIPT_SPINMASK)
word SCRIPT_CMD_PATTERNS, @hexagon_patterns

word SCRIPT_WAIT+60*15+12 ' Rough
word SCRIPT_SPIN+( -HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*24+30 ' Exact?
word SCRIPT_SPIN+( +HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*33+00 ' Exact
word SCRIPT_SPIN+( -HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*41+24 ' Rough
word SCRIPT_SPIN+( +HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*48+24 ' Rough
word SCRIPT_SPIN+( -HEXAGON_SPIN&SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*53+53 ' Rough
word SCRIPT_SPIN+( +HEXAGON_SPIN &SCRIPT_SPINMASK)


word SCRIPT_WAIT+60*60
word SCRIPT_CMD_JMP, @script_hyper_hexagon



script_hyper_hexagon
word SCRIPT_CMD_EFFSTAGE, EFF_HEXAGON2
word SCRIPT_CMD_MUSIC, sdda#MUSIC_COURTESY
word SCRIPT_CMD_PATTERNS, @hyper_hexagon_patterns
word SCRIPT_CMD_WALLSPEED, $2200 'assumption?
word SCRIPT_CMD_PLAYERSPEED, PLAYERSPEED_NORMAL
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*1+35 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*9+15 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*14+15 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*18+05 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*22+30 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*27+00 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*33+30 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*39+30 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*44+15 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*49+55 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*57+33 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*60
word SCRIPT_CMD_EFFSTAGE, EFF_HEXAGON3

word SCRIPT_WAIT+60*64+07 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*68+57 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*72+48 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*79+20 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*85+20 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*91+32 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*96+16 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*101+00 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*105+23 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*111+44 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*117+00 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*118+00 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*119+00 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGON_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*120
word SCRIPT_CMD_JMP, @script_hyper_hexagoner



script_hexagoner
word SCRIPT_CMD_EFFSTAGE, EFF_HEXAGONER1   
word SCRIPT_CMD_MUSIC, sdda#MUSIC_OTIS
word SCRIPT_CMD_PATTERNS, @hexagoner_patterns
word SCRIPT_CMD_WALLSPEED, $2000 'assumption?
word SCRIPT_CMD_PLAYERSPEED, PLAYERSPEED_NORMAL
word SCRIPT_SPIN+( +HEXAGONER_SPIN_SLOW &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*9+30 ' Rough
word SCRIPT_SPIN+( -HEXAGONER_SPIN_SLOW &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*12+10 ' Rough
word SCRIPT_SPIN+( +HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*21+15 ' Rough
word SCRIPT_SPIN+( -HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*26+06 ' Rough
word SCRIPT_SPIN+( +HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*34+53 ' Rough
word SCRIPT_SPIN+( -HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*38+40 ' Rough
word SCRIPT_SPIN+( +HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*44+45 ' Rough
word SCRIPT_SPIN+( -HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*49+15 ' Rough
word SCRIPT_SPIN+( +HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*58+43 ' Rough
word SCRIPT_SPIN+( -HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*60
word SCRIPT_CMD_JMP, @script_hyper_hexagoner

script_hyper_hexagoner
word SCRIPT_CMD_EFFSTAGE, EFF_HEXAGONER2      
word SCRIPT_CMD_MUSIC, sdda#MUSIC_OTIS
word SCRIPT_CMD_PATTERNS, @hyper_hexagoner_patterns
word SCRIPT_CMD_WALLSPEED, $2400 'assumption?
word SCRIPT_CMD_PLAYERSPEED, PLAYERSPEED_NORMAL
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*01+36 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*04+00 ' Manual
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*08+03 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*13+20 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*18+20 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*23+39 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*28+53 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*35+32 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*45+05 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*53+00 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*60
word SCRIPT_CMD_EFFSTAGE, EFF_HEXAGONER3

word SCRIPT_WAIT+60*62+35 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*70+51 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*78+55 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*83+57 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)
                     
word SCRIPT_WAIT+60*91+00 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*96+25 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*103+16 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*109+31 ' Rough
word SCRIPT_SPIN+( -HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*119+00 ' Rough
word SCRIPT_SPIN+( +HYPER_HEXAGONER_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*120
word SCRIPT_CMD_JMP, @script_hyper_hexagonest



script_hexagonest
word SCRIPT_CMD_EFFSTAGE, EFF_HEXAGONEST1      
word SCRIPT_CMD_MUSIC, sdda#MUSIC_FOCUS
word SCRIPT_CMD_PATTERNS, @hexagonest_patterns
word SCRIPT_CMD_WALLSPEED, $2666 'assumption?
word SCRIPT_CMD_PLAYERSPEED, PLAYERSPEED_FAST
word SCRIPT_SPIN+( +HEXAGONEST_SPIN_SLOW &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*05+11 ' Rough
word SCRIPT_SPIN+( -HEXAGONEST_SPIN_SLOW &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*06+50 ' Rough
word SCRIPT_SPIN+( +HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*10+30 ' Rough
word SCRIPT_SPIN+( -HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*10+45 ' Rough
word SCRIPT_SPIN+( -HEXAGONEST_SPIN_FAST &SCRIPT_SPINMASK)
word SCRIPT_WAIT+60*11+15 ' Rough
word SCRIPT_SPIN+( 0 &SCRIPT_SPINMASK)
word SCRIPT_WAIT+60*11+25 ' Rough
word SCRIPT_SPIN+( -HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*15+25 ' Rough
word SCRIPT_SPIN+( +HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*19+00 ' Exact
word SCRIPT_SPIN+( -HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*24+00 ' Exact
word SCRIPT_SPIN+( +HEXAGONEST_SPIN_FAST &SCRIPT_SPINMASK)
word SCRIPT_WAIT+60*24+40 ' Rough
word SCRIPT_SPIN+( 0 &SCRIPT_SPINMASK)
word SCRIPT_WAIT+60*24+50 ' Rough
word SCRIPT_SPIN+( +HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*29+50 ' Rough
word SCRIPT_SPIN+( -HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*37+45 ' Rough
word SCRIPT_SPIN+( +HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*42+53 ' Rough
word SCRIPT_SPIN+( -HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*46+30 ' Exact
word SCRIPT_SPIN+( +HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*53+21 ' Rough
word SCRIPT_SPIN+( -HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*56+00 ' Exact
word SCRIPT_SPIN+( -HEXAGONEST_SPIN_FAST &SCRIPT_SPINMASK)
word SCRIPT_WAIT+60*56+40 ' Rough
word SCRIPT_SPIN+( 0 &SCRIPT_SPINMASK)
word SCRIPT_WAIT+60*56+50 ' Rough
word SCRIPT_SPIN+( +HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*60
word SCRIPT_CMD_JMP, @script_hyper_hexagonest



script_hyper_hexagonest
word SCRIPT_CMD_EFFSTAGE, EFF_HEXAGONEST2    
word SCRIPT_CMD_MUSIC, sdda#MUSIC_FOCUS
word SCRIPT_CMD_PATTERNS, @hyper_hexagonest_patterns
word SCRIPT_CMD_WALLSPEED, $2B00 'assumption?
word SCRIPT_CMD_PLAYERSPEED, PLAYERSPEED_FAST
word SCRIPT_SPIN+( +HYPER_HEXAGONEST_SPIN_SLOW &SCRIPT_SPINMASK) '' TODO

word SCRIPT_WAIT+60*04+00 ' Manual
word SCRIPT_SPIN+( +HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*08+20 ' Manual
word SCRIPT_SPIN+( -HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*12+50 ' Manual
word SCRIPT_SPIN+( +HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*17+30 ' Manual
word SCRIPT_SPIN+( -HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*21+40 ' Manual
word SCRIPT_SPIN+( +HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*27+30 ' Manual
word SCRIPT_SPIN+( -HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*34+40 ' Manual
word SCRIPT_SPIN+( +HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*41+30 ' Manual
word SCRIPT_SPIN+( -HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*45+40 ' Manual
word SCRIPT_SPIN+( +HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*50+50 ' Manual
word SCRIPT_SPIN+( -HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*56+20 ' Manual
word SCRIPT_SPIN+( +HYPER_HEXAGONEST_SPIN &SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*60
word SCRIPT_CMD_JMP, @script_blackwhite



script_blackwhite
word SCRIPT_CMD_EFFSTAGE, EFF_BLACKWHITE        
word SCRIPT_CMD_MUSIC, sdda#MUSIC_BLACKWHITE
word SCRIPT_CMD_PATTERNS, @blackwhite_patterns
word SCRIPT_CMD_WALLSPEED, $2B00 'assumption?
word SCRIPT_CMD_PLAYERSPEED, PLAYERSPEED_FAST
word SCRIPT_SPIN+(SPINSPEED_BW_SPECIAL&SCRIPT_SPINMASK)

word SCRIPT_WAIT+60*10
word SCRIPT_POS+( -1 & SCRIPT_POSMASK)
word SCRIPT_CMD_JMP, @script_blackwhite
 

script_idle
word SCRIPT_WAIT+1
word SCRIPT_CMD_JMP, @script_idle



DAT
long
          {
long @pattern_solo1     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 10<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT

long @pattern_solo2     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2_opp +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT

long @pattern_solo3     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 7<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo3_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 6<<PATTERN_WEIGHT_SHIFT
 
long @pattern_solo4     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT

long @pattern_multic    +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT 
long @pattern_rain      +PATTERN_CW  + 0                <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT 

long @pattern_whirlpool +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT 
long @pattern_whirlpool2+PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 22<<PATTERN_WEIGHT_SHIFT

long @pattern_2spin     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT '}
'long @pattern_3spin    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
'long @pattern_4spin    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT

                                                                                                          {
long @pattern_321       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_bat       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_ladder    +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT '}
'long @pattern_stair1   +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
'long @pattern_stair2   +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
'}

whirlpool2_only
long @pattern_whirlpool2+PATTERN_CW  + 0<<PATTERN_OFFSET_SHIFT                  + 3<<PATTERN_WEIGHT_SHIFT
'long @pattern_2spin +PATTERN_CCW + 0 <<PATTERN_OFFSET_SHIFT                      + 3<<PATTERN_WEIGHT_SHIFT
long 0

hexagon_patterns
long @pattern_whirlpool +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_bat       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_ladder    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT

hexagon_patterns_simple 
long @pattern_solo1     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 10<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 6<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2_opp +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 7<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo3_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo4     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long 0 

hyper_hexagon_patterns
long @pattern_solo1     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 10<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 6<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2_opp +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo3_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT

long @pattern_whirlpool +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_bat       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_ladder    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_stair1   +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_321      +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long 0

hexagoner_patterns
long @pattern_solo1     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 9<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2_opp +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo3_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo4     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT

long @pattern_2spin     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_4spin     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_multic    +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT 
long @pattern_rain      +PATTERN_CW  + 0                <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_bat       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_ladder    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_321       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT 
long 0

hyper_hexagoner_patterns   
long @pattern_solo1     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  +10<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 6<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2_opp +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo3_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 6<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo4     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT     

long @pattern_whirlpool2+PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_3spin     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT 
long @pattern_rain      +PATTERN_CW  + 0                <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_bat       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_ladder    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_321       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_multic    +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT 
long @pattern_rain      +PATTERN_CW  + 0                <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long 0

hexagonest_patterns
long @pattern_solo1     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 6<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2_opp +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo3_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT

long @pattern_whirlpool2+PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_4spin     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_321       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT 
long @pattern_rain      +PATTERN_CW  + 0                <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT

long 0

hyper_hexagonest_patterns
long @pattern_solo1     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 6<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 5<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2_opp +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo3_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT

long @pattern_stair2    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_whirlpool2+PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT 
long @pattern_rain      +PATTERN_CW  + 0                <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT 
long @pattern_4spin     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_321       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT

long 0

blackwhite_patterns
long @pattern_solo1     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 7<<PATTERN_WEIGHT_SHIFT
long @pattern_solo1     +PATTERN_CW  + 0                <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_solo1     +PATTERN_CW  + 3                <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + 0                <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_triplec   +PATTERN_CW  + 3                <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo2_opp +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 8<<PATTERN_WEIGHT_SHIFT
long @pattern_solo3     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 7<<PATTERN_WEIGHT_SHIFT 
long @pattern_solo3_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 6<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 6<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_dbl +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT
long @pattern_solo4_thk +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 4<<PATTERN_WEIGHT_SHIFT

long @pattern_stair1    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_stair2    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_whirlpool2+PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_321       +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_3spin     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_4spin     +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT
long @pattern_multic    +PATTERN_CW  + OFFSET_RANDOMIZE2<<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT
long @pattern_ladder    +PATTERN_CW  + OFFSET_RANDOMIZE <<PATTERN_OFFSET_SHIFT  + 2<<PATTERN_WEIGHT_SHIFT 
long @pattern_rain      +PATTERN_CW  + 0                <<PATTERN_OFFSET_SHIFT  + 3<<PATTERN_WEIGHT_SHIFT

long 0

{
pattern_test
byte 2
byte W__X__X 
byte W__X___
byte 6 ' spacing
}
pattern_solo1
byte 1
byte WXXXXX_
byte 6 ' spacing

pattern_solo2
byte 1
byte W_XXX_X
byte 6 ' spacing


pattern_solo2_opp'osing
byte 7
byte W_XXX_X 
byte W______[5]
byte WX_X_XX
byte 12 ' spacing

pattern_solo3
byte 1
byte WX_X_X_
byte 6 ' spacing

pattern_solo3_dbl
byte 3
byte WX_X_X_
byte W______
byte WX_X_X_
byte 6 ' spacing

pattern_solo3_thk
byte 2
byte WX_X_X_[2]
byte 6 ' spacing

pattern_triplec
byte 13
byte WXXXXX_
byte W______[5]
byte WXX_XXX
byte W______[5]
byte WXXXXX_
byte 18 ' spacing


pattern_solo4
byte 1
byte W__X__X
byte 5 ' spacing

pattern_solo4_dbl
byte 3
byte W__X__X
byte W______
byte W__X__X
byte 6 ' spacing

pattern_solo4_thk
byte 2
byte W__X__X 
byte W__X__X
byte 6 ' spacing

pattern_stair1
byte 16
byte WXX_XX_
byte W______[2]
byte WX_XX_X   
byte W______[2]
byte W_XX_XX 
byte W______[2]
byte WXX_XX_ 
byte W______[2]
byte WX_XX_X 
byte W______[2]
byte W_XX_XX    
byte 20 ' spacing

pattern_stair2
byte 16
byte WXX_XX_
byte W______[2]
byte WX_XX_X   
byte W______[2]
byte W_XX_XX 
byte W______[2]
byte WX_XX_X 
byte W______[2]
byte WXX_XX_  
byte W______[2]
byte W_XX_XX      
byte 20 ' spacing

pattern_multic
byte 16
byte WXXXXX_ 
byte W______[2]
byte WXXXX_X 
byte W______[2]
byte WXXX_XX 
byte W______[2]
byte WXX_XXX 
byte W______[2]
byte WX_XXXX
byte W______[2]
byte W_XXXXX                    
byte 20 ' spacing

pattern_rain
byte 13
byte WX_X_X_
byte W______[2] 
byte W_X_X_X
byte W______[2]
byte WX_X_X_
byte W______[2]
byte W_X_X_X  
byte W______[2]
byte WX_X_X_
byte 17 ' spacing (increased from 16?)


pattern_2spin
byte 16
byte WXXX__X
byte W_____X[2]
byte W__XXXX
byte W_____X[2]
byte WXXX__X
byte W_____X[2]
byte W__XXXX
byte W_____X[2]
byte WXXX__X
byte W_____X[2]
byte W__XXXX
byte 20 ' spacing

pattern_3spin
'' I slightly altered this pattern to make it shorter and more challenging
byte 23
byte WXXXX_X
byte WX____X[4]
byte WX_XXXX
byte WX__XXX
byte WX___XX
byte WX____X
byte WX____X
byte WXXXX_X
byte WXXX__X
byte WXX___X
byte WX____X
byte WX____X
byte WX_XXXX
byte WX__XXX
byte WX___XX
byte WX____X
byte WX____X
byte WXXXX_X
byte WXXX__X
byte WXX___X
byte 30 ' spacing

pattern_4spin
byte 13
byte W_XXXXX
byte W_____X[5]
byte WXXXX_X
byte W_____X[5]
byte W_XXXXX
byte 20 ' spacing

pattern_whirlpool
byte 16
byte WXXXXX_
byte WXXXX__
byte WXXX___
byte WXX____
byte WX____X
byte W____XX
byte W___XX_
byte W__XX__
byte W_XX___
byte WXX____ 
byte WX____X
byte W____XX
byte W___XX_
byte W__XXX_
byte W_XXXX_
byte WXXXXX_
byte 20 ' spacing TODO:remeasure

pattern_whirlpool2
'' This pattern seems to use weird 1.5 unit walls.
'' Have made them 1 unit and given it a kinda entry tunnel such that it is easier to not get snagged
byte 10
byte WXX_XX_
byte WXX_XX_
byte WX__X__
byte W__X__X
byte W_X__X_
byte WX__X__
byte W__X__X
byte W_X__X_
byte WX__X__
byte WX_XX_X 
byte 14 ' spacing

pattern_321
byte 16
byte WXXXXX_
byte W______[3]
byte WX___XX
byte WXX_XXX
byte WXX_XXX
byte W_____X
byte W_____X
byte W__X__X
byte W_XXX_X
byte W_XXX_X
byte W__X__X
byte W__X__X
byte WX___XX
byte WX___XX
byte 20 ' spacing

pattern_bat
byte 15
byte WXXXXX_
byte W_XXX__
byte W_XXX__
byte W_XXX__
byte W__X___
byte W__X__X
byte W__X__X
byte WX___XX
byte WX___XX
byte WX___XX
byte WXX_XXX[4]
byte WX___X_
byte 20 ' spacing

pattern_ladder
byte 13
byte WXX_XX_
byte WX__X__[2]
byte WX_XX_X
byte WX__X__[2]
byte WXX_XX_
byte WX__X__[2]
byte WX_XX_X
byte WX__X__[2]
byte WXX_XX_
byte 18 ' spacing


CON
  SNES_R      = %0000100000000000
  SNES_L      = %0000010000000000
  SNES_X      = %0000001000000000
  SNES_A      = %0000000100000000
  SNES_RIGHT  = %0000000010000000
  SNES_LEFT   = %0000000001000000
  SNES_DOWN   = %0000000000100000
  SNES_UP     = %0000000000010000
  SNES_START  = %0000000000001000
  SNES_SELECT = %0000000000000100
  SNES_Y      = %0000000000000010
  SNES_B      = %0000000000000001
PUB SNES_Read_Gamepad : nes_bits   |   i

DIRA [plat#SNES_LATCH] := 1 ' output
DIRA [plat#SNES_CLK] := 1 ' output
DIRA [plat#SNES_PLAYER1] := 0 ' input   

OUTA [plat#SNES_CLK] := 0
OUTA [plat#SNES_LATCH] := 0
waitcnt(381+cnt)
OUTA [plat#SNES_LATCH] := 1
waitcnt(381+cnt)  
OUTA [plat#SNES_LATCH] := 0
waitcnt(381+cnt)
nes_bits := 0
nes_bits := INA[plat#SNES_PLAYER1]<<16

repeat i from 0 to 14
  OUTA [plat#SNES_CLK] := 1 ' JOY_CLK = 1
  waitcnt(381+cnt) 
  OUTA [plat#SNES_CLK] := 0 ' JOY_CLK = 0
  waitcnt(381+cnt) 
  nes_bits := (nes_bits << 1)
  nes_bits := nes_bits | INA[plat#SNES_PLAYER1]<<16

nes_bits := (!nes_bits)><0

CON

W______ = %000000
W_____X = %000001
W____X_ = %000010
W____XX = %000011
W___X__ = %000100
W___X_X = %000101
W___XX_ = %000110
W___XXX = %000111
W__X___ = %001000
W__X__X = %001001
W__X_X_ = %001010
W__X_XX = %001011
W__XX__ = %001100
W__XX_X = %001101
W__XXX_ = %001110
W__XXXX = %001111
W_X____ = %010000
W_X___X = %010001
W_X__X_ = %010010
W_X__XX = %010011
W_X_X__ = %010100
W_X_X_X = %010101
W_X_XX_ = %010110
W_X_XXX = %010111
W_XX___ = %011000
W_XX__X = %011001
W_XX_X_ = %011010
W_XX_XX = %011011
W_XXX__ = %011100
W_XXX_X = %011101
W_XXXX_ = %011110
W_XXXXX = %011111
WX_____ = %100000
WX____X = %100001
WX___X_ = %100010
WX___XX = %100011
WX__X__ = %100100
WX__X_X = %100101
WX__XX_ = %100110
WX__XXX = %100111
WX_X___ = %101000
WX_X__X = %101001
WX_X_X_ = %101010
WX_X_XX = %101011
WX_XX__ = %101100
WX_XX_X = %101101
WX_XXX_ = %101110
WX_XXXX = %101111
WXX____ = %110000
WXX___X = %110001
WXX__X_ = %110010
WXX__XX = %110011
WXX_X__ = %110100
WXX_X_X = %110101
WXX_XX_ = %110110
WXX_XXX = %110111
WXXX___ = %111000
WXXX__X = %111001
WXXX_X_ = %111010
WXXX_XX = %111011
WXXXX__ = %111100
WXXXX_X = %111101
WXXXXX_ = %111110
WXXXXXX = %111111

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