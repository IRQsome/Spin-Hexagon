_clkmode = xtal1 + pll16x
_xinfreq = 5_000_000
_stack   = 120
_free    = sdda#STASH_SIZE+2

OBJ

tv : "TV_Text"                   
sdda : "hexagon_sdda.spin"
plat: "platform.spin"

PUB main | err
tv.start(12)
tv.str(string("Stage 2 test...",13))

sdda.unstash

tv.hex(sdda.savesector,8)
