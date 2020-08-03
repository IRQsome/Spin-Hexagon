_clkmode = xtal1 + pll16x
_xinfreq = 5_000_000
_stack   = 120
_free    = sdda#STASH_SIZE+2

OBJ

tv : "TV_Text"
fat :"SD-MMC_FATEngine.spin"
sdda : "hexagon_sdda.spin"
plat: "platform.spin"

PUB main | err
tv.start(12)
tv.str(string("Loading Spin Hexagon...",13,"2020 IRQsome Software",13))
if err:=\boot
  tv.str(string(13,"ABORT "))
  tv.dec(err)
  fat.unmountPartition
  repeat


PUB boot :savesector|erc,i,savepath,clust


fat.FATEngineStart(plat#spiDO,plat#spiClk,plat#spiDI,plat#spiCS,-1,-1,-1,-1,-1)   
erc := \fat.mountPartition(0)
if erc > 1
  tv.str(string("mount error "))
  tv.str(erc)
  tv.str(string(", retrying...",13))
  erc := \fat.mountPartition(0)
  if erc > 1
      tv.str(string("mount error "))
      tv.str(erc)
      tv.str(string(", halting!",13))
      abort 32

sdda.setup_music(sdda#MUSIC_COURTESY,contigFile(string("COURTESY.VU")),fat.fileSize)
sdda.setup_music(sdda#MUSIC_OTIS,contigFile(string("OTIS.VU")),fat.fileSize)
sdda.setup_music(sdda#MUSIC_FOCUS,contigFile(string("FOCUS.VU")),fat.fileSize)
sdda.setup_music(sdda#MUSIC_BLACKWHITE,contigFile(string("FINAL.VU")),fat.fileSize)

sdda.setup_sfx(sdda#SFX_TITLE,contigFile(string("HEXTITLE.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_CHOOSE,contigFile(string("HEXCHOOS.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_SELECT,contigFile(string("HEXSELEC.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_BEGIN,contigFile(string("HEXBEGIN.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_LINE,contigFile(string("HEXL2.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_TRIANGLE,contigFile(string("HEXL3.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_SQUARE,contigFile(string("HEXL4.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_PENTAGON,contigFile(string("HEXL5.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_HEXAGON,contigFile(string("HEXL6.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_EXCELLENT,contigFile(string("HEXEXEL.RAW")),fat.fileSize)
sdda.setup_sfx(sdda#SFX_GAMEOVER,contigFile(string("HEXGOVER.RAW")),fat.fileSize)      

tv.str(string(13,"Checking save file... "))
savepath:=string("HEXAGON.SAV")
erc:=\fat.openFile(savepath,"R")
case fat.partitionError
  0: clust := fat.getCurrentFileCluster
  fat#Entry_Not_Found:
    tv.str(string("Not found!",13,"Creating save file... "))
    erc:=\fat.newFile(savepath)
    if fat.partitionError
      tv.str(erc)
      abort 34
    erc:=\fat.openFile(savepath,"A")
    if fat.partitionError
      tv.str(erc)
      abort 35
    clust := fat.getCurrentFileCluster
    repeat 128 ' zero out one sector
      fat.writeLong(0)
    fat.closeFile
  other:
    tv.str(erc)
    abort 33

    
{if (i:=512-fat.fileSize)>0
  tv.str(string("too small, appending "))
  tv.dec(i)
  tv.str(string("bytes... "))}
savesector := fat.firstSectorOfCluster(clust) + fat.getHiddenSectors
fat.closeFile
tv.str(string("OK!",13))
  

sdda.stash(fat.getSPIShift,savesector)

fat.bootPartition(string("HEXAGON.BI2"))

return 0
                     
PUB contigFile(name) | clust,sn,sl,erc
  tv.str(string(13,"Checking "))
  tv.str(name)
  tv.str(string("... "))
  erc := \fat.openFile(name,"r")
  if fat.partitionError
    tv.str(erc)
    repeat
  'pst.str(string(" clusters",13,"$-------$-------$-------$-------"))
  clust := fat.getCurrentFileCluster
  result := fat.firstSectorOfCluster(clust) + fat.getHiddenSectors
  'pst.hex(clust,8)

  'go looking for fragmentation (adapted from PropCMD's CHAIN command)
  repeat
    erc := fat.followClusterChain(clust)
    'pst.str(string("      $"))
    'pst.hex(erc,8)
    if fat.isClusterEndOfClusterChain(erc)
      quit
    if erc <> clust+1
      tv.str(string(" oh no, fragmented!",13))
      repeat
    clust := erc
  
  tv.str(string("OK!"))
