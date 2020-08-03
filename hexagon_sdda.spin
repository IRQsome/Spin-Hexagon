'' TinySDDA wrapper thing for Spin Hexagon

#0,MUSIC_COURTESY,MUSIC_OTIS,MUSIC_FOCUS,MUSIC_BLACKWHITE,MUSIC_COUNT

#0,SFX_TITLE,SFX_CHOOSE,SFX_SELECT,SFX_BEGIN,SFX_LINE,SFX_TRIANGLE,SFX_SQUARE,SFX_PENTAGON,SFX_HEXAGON,SFX_EXCELLENT,SFX_GAMEOVER,SFX_COUNT

STASH_LOC = $8000 - STASH_SIZE*4
STASH_SIZE = (1 + 1 + MUSIC_COUNT*2 + SFX_COUNT*2 + 1) ' +1 for safety or smth IDK it makes stuff work
STASH_SIGNATURE = $8EC5A60F

SAVE_SIZE = 32 ' longs

OBJ

sdda: "tinySDDA_xasm.spin"
plat: "platform.spin"

VAR

long sdinfo,savesector
long musicstarts[MUSIC_COUNT]
long musicstops[MUSIC_COUNT]    

long sfxstarts[SFX_COUNT]
long sfxstops[SFX_COUNT]


PUB play_music(n)
case n
  0..constant(MUSIC_COUNT-1):
    sdda.setmusic(musicstarts[n],musicstops[n],musicstarts[n])
    return true
  other:
    sdda.stopmusic

PUB play_sfx(n)
case n
  0..constant(SFX_COUNT-1):
    sdda.setsfx(sfxstarts[n],sfxstops[n],0)
    return true
  other:        
    sdda.stopsfx

PUB readsavedata(where)
if savesector
  sdda.put_command(sdda#CMD_READ,savesector,where,SAVE_SIZE)

PUB writesavedata(where)
if savesector
  sdda.put_command(sdda#CMD_WRITE,savesector,where,SAVE_SIZE)

PUB sdda_start(asmptr)
sdda.start(sdinfo,asmptr)
return sdda.get_subcode_ptr

PUB unstash
if result:=long[STASH_LOC]==STASH_SIGNATURE
  longmove(@sdinfo,STASH_LOC+4,STASH_SIZE)

PUB setup_music(n,sector,size)
sector<<=1
musicstarts[n]:=sector
musicstops[n]:=sector + (size+255)>>8

PUB setup_sfx(n,sector,size)
sector<<=2
sfxstarts[n]:=sector
sfxstops[n]:=sector + size>>7

PUB stash(sdinfo_in,saveptr_in)
longmove(@sdinfo,@sdinfo_in,2)
longmove(STASH_LOC+4,@sdinfo,STASH_SIZE)
long[STASH_LOC]:=STASH_SIGNATURE
