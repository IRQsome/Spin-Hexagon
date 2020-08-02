'' Spin Hexagon platform definitions

spiDO         = 21
spiClk        = 24
spiDI         = 20
spiCS         = 25   

'' Please note: mono not supported yet
audioLeft     = 11
audioRight    = 10

SNES_CLK      = 16
SNES_LATCH    = 17
SNES_PLAYER2  = 18
SNES_PLAYER1  = 19

TV_BASEPIN    = 12
TV_PINGROUP   = (TV_BASEPIN & $38) << 1 | (TV_BASEPIN & 4 == 4) & %0101 '%001_0101

PUB getoffmylawnproptoolaaaaaaa