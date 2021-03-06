'' tinySDDA v1.0
'' (C)2020 IRQsome Software
'' Tiny SD + Digital Audio driver

CTR_DUTY = %00110 << 26

#1,CMD_READ,CMD_WRITE,CMD_MUSIC,CMD_SFX

ALAW_BASESHL = 19

VAR
long cmd,p1,p2,p3,subcode_var
byte cognum

PUB start(addrshift,spi_do,spi_clk,spi_di,spi_cs,leftpin,rightpin,sample_rate)
stop
long[@entry][1] := CTR_DUTY + leftpin 'ctra_v
long[@entry][3] := |<leftpin ' dira_v
if rightpin => 0
  long[@entry][2] := CTR_DUTY + rightpin 'ctrb_v
  long[@entry][3] |= |<rightpin 'dira_v                        
else
  long[@entry][2] := 0 'ctrb_v
long[@entry][4] := clkfreq/sample_rate 'sample_period
long[@entry][5] := addrshift 'address_shift

long[@entry][3] |= |<spi_di | |<spi_clk | |<spi_cs 'dira_v
long[@entry][6] := |<spi_do
long[@entry][7] := |<spi_clk
long[@entry][8] := |<spi_di
long[@entry][9] := |<spi_cs

long[@entry][10] := @cmd
long[@entry][11] := @p1
long[@entry][12] := @p2
long[@entry][13] := @p3
long[@entry][14] := @subcode_var

cognum:=result:= cognew(@entry, 0) + 1
PUB stop
if cognum
  cogstop(cognum~ - 1)

PUB put_command_async(c,pr1,pr2,pr3)
repeat while cmd
longmove(@p1,@pr1,3)
cmd:=c

PUB put_command(c,pr1,pr2,pr3)
put_command_async(c,pr1,pr2,pr3)
repeat while cmd

PUB sync
repeat while cmd

PUB setmusic(startblk,endblk,restartblk)
if startblk
  put_command_async(CMD_MUSIC,startblk-1,endblk,restartblk)
else
  put_command_async(CMD_MUSIC,0,0,0)

PUB setsfx(startblk,endblk,restartblk)
if startblk
  put_command_async(CMD_SFX,startblk-1,endblk,restartblk)
else
  put_command_async(CMD_SFX,0,0,0)

PUB stopmusic
setmusic(0,0,0)
PUB stopsfx
setsfx(0,0,0)

PUB readSector(sectorn,where)
put_command(CMD_READ,sectorn,where,128)
sync

PUB writeSector(sectorn,where)
put_command(CMD_WRITE,sectorn,where,128)
sync

PUB get_subcode_ptr
return @subcode_var

DAT

entry         jmp #entry2
atmp1 ' alias
ctra_v        long 0
atmp2 ' alias
ctrb_v        long 0
spitmp1 ' alias
dira_v        long 0 
sample_period long 0
address_shift long 0 ' 0 for SDHC/SDXC, 9 for SDSC
do_mask       long 0
clk_mask      long 0
di_mask       long 0
cs_mask       long 0
mailboxptr    long 0
par1ptr       long 0
par2ptr       long 0
par3ptr       long 0
subcode_ptr   long 0

cmd_readwrite
              mov requestblock,par1
              mov hub_ptr,par2
              mov skipsize,par3
              shr skipsize,#16
              mov datasize,par3
              and datasize,conffff
              ' C is set for read!

sd_readwrite  
              'andn outa,cs_mask ' select card
              muxnc writeflag,#1
        if_c  movi spidata,#CMD17 << 1 'read single block
        if_nc movi spidata,#CMD24 << 1 'write single block
              mov spibits,#8
              call #writebits ' write command

              jmpret sdthread,audiothread ' task switch

              mov spidata,requestblock
              shl spidata,address_shift
              mov spibits,#32
              call #writebits ' write address

              jmpret sdthread,audiothread ' task switch

              mov spibits,#8
              call #skipbits ' pretend to send CRC
              'wrlong d0,#0
              ' Now we have to wait for a response...
:resploop     mov spibits,#8
              call #readbits
              test spidata,#$80 wc ' C set if no response start bit yet
        if_c  mov sdthread,#:resploop ' task...
        if_c  jmp audiothread      ' ...switch
              '' We might want to check here if we got an error
              '' But we might as well not (I've never gotten an error response for a valid request, ever...)
              'wrlong d1,#0
              tjz writeflag,#:waitstart
             '' Writing : emit block start token
              mov spibits,#8
              movi spidata,#$FE<<1
              call #writebits
              jmp #:frntskip

:waitstart    
              '' Reading : got to wait for a block start token..
              '' TODO: this could be done faster by doing it low-level?
:startloop    mov spibits,#8
              call #readbits
              and spidata,#$FF
              cmp spidata,#$FE wz
        if_ne mov sdthread,#:startloop ' task...
        if_ne jmp audiothread       ' ...switch
              


:frntskip
              '' Skip front data we don't want
              'wrlong d2,#0
              mov spitmp1,skipsize wz
        if_z  jmp #:no_frontskip
        
:fskplp       mov spibits,#32
              call #skipbits
              jmpret sdthread,audiothread ' task switch
              djnz spitmp1,#:fskplp

:no_frontskip '' Read/write the data we want
              'wrlong d3,#0
              mov spitmp1,datasize
              tjz writeflag,#do_read
do_write
writelp       rdlong spidata,hub_ptr
              add hub_ptr,#4

              'endian swap
              mov spitmp2,spidata      '$12345678
              rol spidata,#8           '$34567812
              ror spitmp2,#8           '$78123456
              and spidata,con00ff00ff  '$00560012
              andn spitmp2,con00ff00ff '$78003400
              or spidata,spitmp2
              
              ' write
              mov spibits,#32
              call #writebits
              
              jmpret sdthread,audiothread ' task switch
              djnz spitmp1,#writelp
              
              jmp #backskip
              
do_read       or outa,di_mask
              
readlp        mov spibits,#32

              ' read
:loop         andn outa,clk_mask
              or outa,clk_mask
              test do_mask,ina wc
              rcl spidata,#1
              djnz spibits,#:loop

              'endian swap
              mov spitmp2,spidata      '$12345678
              rol spidata,#8           '$34567812
              ror spitmp2,#8           '$78123456
              and spidata,con00ff00ff  '$00560012
              andn spitmp2,con00ff00ff '$78003400
              or spidata,spitmp2              

              tjz hubflag,#:cogrd
              wrlong spidata,hub_ptr
              add hub_ptr,#4
              jmpret sdthread,audiothread ' task switch
              djnz spitmp1,#readlp
              jmp #rdjoin
:cogrd
cog_ptr       mov 0-0,spidata
              add cog_ptr,con512
              jmpret sdthread,audiothread ' task switch
              djnz spitmp1,#readlp
rdjoin

backskip      '' Skip back data we don't want
              mov spitmp1,#128+1 ' skip over CRC aswell...
              sub spitmp1,skipsize
              sub spitmp1,datasize
              sub spitmp1,writeflag wz '.. except when writing
        if_z  jmp #:nobskp

              'wrlong d4,#0
              
:bskplp       mov spibits,#32
              call #skipbits
              jmpret sdthread,audiothread ' task switch
              djnz spitmp1,#:bskplp
:nobskp
              tjz writeflag,#rq_done '' Reading : All done! 

              ' skip over CRC
              mov spibits,#16
              call #skipbits

              '' Writing : wait for data response token
:respwait     mov spibits,#8
              call #readbits
              test spidata,#%00010000 wc
        if_c  mov sdthread,#:respwait  ' task...
        if_c  jmp audiothread       ' ...switch
              '' wait until not busy
              'wrlong d5,#0
:busywait     mov spibits,#8
              call #readbits
              test spidata,#$FF wz
        if_z  mov sdthread,#:busywait  ' task...
        if_z  jmp audiothread       ' ...switch
              

              '' Fall into rq_done
              
rq_done       mov 0-0,#0 '' indicate a request as done and fall into sd_loop
              movd rq_done,#0
              shr hubflag,#31 wc
        if_c  wrlong zero,mailboxptr

sd_loop       jmpret sdthread,audiothread ' task switch
              tjnz sfxrequest,#service_sfx
              tjnz musicrequest,#service_music
              '' Check mailbox
              rdlong command,mailboxptr wz
        if_z  jmp #sd_loop
              '' We got mail!
              rdlong par1,par1ptr 
              mov hubflag,#1              
              rdlong par2,par2ptr 
              cmp command,#CMD_WRITE wc,wz
              rdlong par3,par3ptr
        if_be jmp #cmd_readwrite ' C set if CMD_READ

              cmp command,#CMD_MUSIC wz
        if_e  jmp #cmd_setmusic
              cmp command,#CMD_SFX wz
        if_e  jmp #cmd_setsfx
        
              jmp #rq_done


cmd_setmusic
              mov musicblock,par1
              mov musicend,par2
              mov musicrestart,par3
              jmp #rq_done

cmd_setsfx    
              mov sfxblock,par1
              mov sfxend,par2
              mov sfxrestart,par3
              jmp #rq_done
              
              

service_music
              mov requestblock,musicrequest
              shr requestblock,#1 wc ' one music buffer is 64 longs = 256 bytes = 1/2 sector
        if_nc mov skipsize,#0
        if_c  mov skipsize,#64
              mov datasize,#64
              
musicrq_dst   movd cog_ptr,#0-0
              movd rq_done,#musicrequest
              jmpret zero,#sd_readwrite wc,nr ' set C (READ!)
              
service_sfx   
              mov requestblock,sfxrequest
              mov skipsize,#0
              shr requestblock,#1 wc ' one SFX buffer is 32 longs = 128 bytes = 1/4 sector
        if_c  add skipsize,#32
              shr requestblock,#1 wc
        if_c  add skipsize,#64

              mov datasize,#32 

sfxrq_dst     movd cog_ptr,#0-0
              movd rq_done,#sfxrequest
              jmpret zero,#sd_readwrite wc,nr ' set C (READ!)


skipbits
              or outa,di_mask
:loop         andn outa,clk_mask
              or outa,clk_mask
              djnz spibits,#:loop
skipbits_ret  ret

readbits
              or outa,di_mask
:loop         andn outa,clk_mask
              or outa,clk_mask
              test do_mask,ina wc
              rcl spidata,#1
              djnz spibits,#:loop
readbits_ret  ret

writebits
:loop         andn outa,clk_mask
              rol spidata,#1 wc
              muxc outa,di_mask
              or outa,clk_mask
              djnz spibits,#:loop
writebits_ret ret


audio_loop    jmpret audiothread,sdthread ' task switch
              mov atmp1,audio_stime
              sub atmp1,cnt
              cmps atmp1,#16 wc,wz
        if_a jmp #audio_loop

              mov frqa,leftsample
              mov frqb,rightsample

do_music
              tjz music_left,#music_chkrq ' don't update music if data is behind
              
              '' load, seperate and sign-extend samples
music_ptr     mov leftmusic,0-0
              mov rightmusic,leftmusic
              shl leftmusic,#16
left_sar      sar leftmusic,#1 ' #2 for mono
right_sar     sar rightmusic,#1 ' #2 for mono

              add music_ptr,#1
              djnz music_left,#music_done ' buffer done?
music_chkrq
              tjnz musicrequest,#music_done ' still busy (bad!)

              ' figure out which buffers to play/fill
              mov atmp1,musicrq_dst
              and atmp1,#511 wz ' set Z if there was no previous request  
              movd :subcode_wr,atmp1
        if_nz mov music_left,#64 ' samples ber buffer
:subcode_wr if_nz wrlong 0-0,subcode_ptr ' Subcode write HERE       
              movs music_ptr,atmp1   
              cmp atmp1,#music_buffer1 wz
        if_ne movs musicrq_dst,#music_buffer1
        if_e  movs musicrq_dst,#music_buffer2

              ' request next block
              testn musicblock,#0 wz
        if_nz add musicblock,#1
              cmp musicblock,musicend wc,wz
        if_ae mov musicblock,musicrestart wz
              mov musicrequest,musicblock wz
        if_z  movs musicrq_dst,#0 ' music has ended, don't play garbo next time
        if_z  mov leftmusic,#0
        if_z  mov rightmusic,#0

music_done

do_sfx        '' Do SFX
              tjz sfx_left,#sfx_chkrq ' don't update SFX if data is behind

              '' load long, select byte
sfx_ptr       mov atmp1,0-0 
              neg atmp2,sfx_left
              shl atmp2,#3 
              shr atmp1,atmp2
                                
              '' Decompress A-law
              xor atmp1,#$55
              mov sfxsample,atmp1
              and sfxsample,#$0F ' mantissa isolated
              shl sfxsample,#ALAW_BASESHL
              add sfxsample,alaw_bias
              mov atmp2,atmp1
              shr atmp2,#4
              and atmp2,#7 wz ' exponent isolated
        if_nz add sfxsample,alaw_leading
        if_nz sub atmp2,#1
              shl sfxsample,atmp2
              test atmp1,#$80 wc
              negnc sfxsample,sfxsample

              djnz sfx_left,#sfx_ptrinc

sfx_chkrq
              tjnz sfxrequest,#sfx_done ' still busy (bad!)
              
              ' figure out which buffers to play/fill
              mov atmp1,sfxrq_dst
              and atmp1,#511 wz ' set Z if there was no previous request
              
        if_nz mov sfx_left,#32*4 ' samples per buffer
              movs sfx_ptr,atmp1
              cmp atmp1,#sfx_buffer1 wz
        if_ne movs sfxrq_dst,#sfx_buffer1
        if_e  movs sfxrq_dst,#sfx_buffer2 

              ' request next block
              testn sfxblock,#0 wz
        if_nz add sfxblock,#1
              cmp sfxblock,sfxend wc,wz
        if_ae mov sfxblock,sfxrestart
              mov sfxrequest,sfxblock wz
        if_z  movs sfxrq_dst,#0 ' sfx has ended, don't play garbo next time
        if_z  mov sfxsample,#0

              jmp #sfx_done ' don't increment before first sample
sfx_ptrinc
              test sfx_left,#%11 wz
         if_z add sfx_ptr,#1
sfx_done
         
audio_entry
do_mixing

              '' mix next sample
              mov leftsample,bit31
              mov rightsample,bit31
                                                         
              add leftsample,leftmusic
right_mix     add rightsample,rightmusic ' D changes to leftsample for mono
                                        
              add leftsample,sfxsample 
              add rightsample,sfxsample                                          

              add audio_stime,sample_period 
              jmp #audio_loop


sdthread      long sd_loop
audiothread   long audio_entry

musicrequest  long 0
sfxrequest    long 0

leftsample    long 0
rightsample   long 0

leftmusic     long 0
rightmusic    long 0

music_left    long 0 ' samples left to play
sfx_left      long 0 ' samples left to play

sfxsample     long 0

musicblock    long 0 ' in half-sectors
musicend      long 0
musicrestart  long 0
sfxblock      long 0 ' in half-sectors
sfxend        long 0
sfxrestart    long 0

writeflag     long 0

alaw_bias     long |<(ALAW_BASESHL-1)
alaw_leading  long $10<<ALAW_BASESHL

bit31         long |<31
con512        long 512
conffff       long $ffff
con00ff00ff   long $00ff00ff
zero          long 0

{
d0 long 0
d1 long 1
d2 long 2
d3 long 3
d4 long 4
d5 long 5}

entry2
sfx_buffer1             res 32
sfx_buffer2             res 32


music_buffer1           res 64
music_buffer2           res 64

'' These keep track of the current request info
requestblock            res 1 ' sector number
datasize                res 1 ' in longs
skipsize                res 1 ' in longs                    
hubflag                 res 1 ' set if read to hub (write is always from hub)

hub_ptr                 res 1

command                 res 1
par1                    res 1
par2                    res 1
par3                    res 1

spitmp2                 res 1 

spibits                 res 1 ' how many SPI bits to transfer
spidata                 res 1

audio_stime             res 1

                        fit

                        
                        org entry2
              mov ctra,ctra_v    ' left audio out
              mov ctrb,ctrb_v wz ' right audio out (zero if mono)
              or outa,clk_mask

              '' mono fixup
        if_z  movs left_sar,#2
        if_z  movs right_sar,#2
        if_z  movd right_mix,#leftsample
              
              mov dira,dira_v
              fit 
              mov spibits,#8
              call #skipbits ' get SD attention
              mov audio_stime,cnt
              jmp audiothread

mono_mix
              add leftsample,leftmusic
              add leftsample,rightmusic
                        fit spibits



CON

  ' SDHC/SD/MMC command set for SPI
  CMD0    = $40+0        ' GO_IDLE_STATE 
  CMD1    = $40+1        ' SEND_OP_COND (MMC) 
  ACMD41  = $C0+41       ' SEND_OP_COND (SDC) 
  CMD8    = $40+8        ' SEND_IF_COND 
  CMD9    = $40+9        ' SEND_CSD 
  CMD10   = $40+10       ' SEND_CID 
  CMD12   = $40+12       ' STOP_TRANSMISSION
  CMD13   = $40+13       ' SEND_STATUS  
  ACMD13  = $C0+13       ' SD_STATUS (SDC)
  CMD16   = $40+16       ' SET_BLOCKLEN 
  CMD17   = $40+17       ' READ_SINGLE_BLOCK 
  CMD18   = $40+18       ' READ_MULTIPLE_BLOCK 
  CMD23   = $40+23       ' SET_BLOCK_COUNT (MMC) 
  ACMD23  = $C0+23       ' SET_WR_BLK_ERASE_COUNT (SDC)
  CMD24   = $40+24       ' WRITE_BLOCK 
  CMD25   = $40+25       ' WRITE_MULTIPLE_BLOCK
  CMD48   = $40+48       ' READ_EXTR_SINGLE
  CMD49   = $40+49       ' WRITE_EXTR_SINGLE 
  CMD55   = $40+55       ' APP_CMD 
  CMD58   = $40+58       ' READ_OCR
  CMD59   = $40+59       ' CRC_ON_OFF

  {{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
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