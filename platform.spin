'' Spin Hexagon platform definitions

spiDO         = 21
spiClk        = 24
spiDI         = 20
spiCS         = 25   

'' For mono output, set audioRight to -1
audioLeft     = 11
audioRight    = 10

'' If you don't have SNES controller port, set these to -1
SNES_CLK      = 16
SNES_LATCH    = 17
SNES_PLAYER1  = 19

'' If you don't have PS/2 Keyboard port, edit hexagon.spin to include DummyKeyboard.spin instead of Keyboard
PS2_DATA      = 8
PS2_CLOCK     = 9

TV_BASEPIN    = 12
TV_PINGROUP   = (TV_BASEPIN & $38) << 1 | (TV_BASEPIN & 4 == 4) & %0101 '%001_0101

PUB getoffmylawnproptoolaaaaaaa