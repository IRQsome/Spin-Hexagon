'' tinySDDA v0.1 preview
'' (C)2020 IRQsome Software
'' Tiny SD + Digital Audio driver

CTR_DUTY = %00110 << 26

#1,CMD_READ,CMD_WRITE,CMD_MUSIC,CMD_SFX

VAR
long cmd,p1,p2,p3,subcode_var
byte cognum

PUB start(addrshift,spi_do,spi_clk,spi_di,spi_cs,leftpin,rightpin,sample_rate,asmptr)
stop
long[asmptr][1] := CTR_DUTY + leftpin 'ctra_v
long[asmptr][3] := |<leftpin ' dira_v
if rightpin > 0
  long[asmptr][2] := CTR_DUTY + rightpin 'ctrb_v
  long[asmptr][3] |= |<rightpin 'dira_v                        
else
  long[asmptr][2] := 0 'ctrb_v
long[asmptr][4] := clkfreq/sample_rate 'sample_period
long[asmptr][5] := addrshift 'address_shift

long[asmptr][3] |= |<spi_di | |<spi_clk | |<spi_cs 'dira_v
long[asmptr][6] := |<spi_do
long[asmptr][7] := |<spi_clk
long[asmptr][8] := |<spi_di
long[asmptr][9] := |<spi_cs

long[asmptr][10] := @cmd
long[asmptr][11] := @p1
long[asmptr][12] := @p2
long[asmptr][13] := @p3
long[asmptr][14] := @subcode_var

cognum:=result:= cognew(asmptr, 0) + 1
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