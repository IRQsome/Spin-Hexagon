CON
''
''     Parallax Serial Terminal
''    Control Character Constants
''─────────────────────────────────────
  CS = 16  ''CS: Clear Screen      
  CE = 11  ''CE: Clear to End of line     
  CB = 12  ''CB: Clear lines Below 

  HM =  1  ''HM: HoMe cursor       
  PC =  2  ''PC: Position Cursor in x,y          
  PX = 14  ''PX: Position cursor in X         
  PY = 15  ''PY: Position cursor in Y         

  NL = 13  ''NL: New Line        
  LF = 10  ''LF: Line Feed       
  ML =  3  ''ML: Move cursor Left          
  MR =  4  ''MR: Move cursor Right         
  MU =  5  ''MU: Move cursor Up          
  MD =  6  ''MD: Move cursor Down
  TB =  9  ''TB: TaB          
  BS =  8  ''BS: BackSpace          
           
  BP =  7  ''BP: BeeP speaker          

CON

   BUFFER_LENGTH = 64                                   'Recommended as 64 or higher, but can be 2, 4, 8, 16, 32, 64, 128 or 256.
   BUFFER_MASK   = BUFFER_LENGTH - 1
   MAXSTR_LENGTH = 49                                   'Maximum length of received numerical string (not including zero terminator).
PUB Start(baudrate) : okay

PUB StartRxTx(rxpin, txpin, mode, baudrate) : okay

PUB Stop

PUB Char(bytechr)

PUB Chars(bytechr, count)

PUB CharIn : bytechr

PUB Str(stringptr)

PUB StrIn(stringptr)

PUB StrInMax(stringptr, maxcount)

PUB Dec(value) | i, x                                                                   'Update divisor

PUB DecIn : value

PUB Bin(value, digits)

PUB BinIn : value
   
PUB Hex(value, digits)

PUB HexIn : value

PUB Clear
{{Clear screen and place cursor at top-left.}}
  
  Char(CS)

PUB ClearEnd
{{Clear line from cursor to end of line.}}
  
  Char(CE)
  
PUB ClearBelow
{{Clear all lines below cursor.}}
  
  Char(CB)
  
PUB Home
{{Send cursor to home position (top-left).}}
  
  Char(HM)
  
PUB Position(x, y)
{{Position cursor at column x, row y (from top-left).}}
  
  Char(PC)
  Char(x)
  Char(y)
  
PUB PositionX(x)
{{Position cursor at column x of current row.}}
  Char(PX)
  Char(x)
  
PUB PositionY(y)
{{Position cursor at row y of current column.}}
  Char(PY)
  Char(y)

PUB NewLine
{{Send cursor to new line (carriage return plus line feed).}}
  
  Char(NL)
  
PUB LineFeed
{{Send cursor down to next line.}}
  
  Char(LF)
  
PUB MoveLeft(x)
{{Move cursor left x characters.}}
  
  repeat x
    Char(ML)
  
PUB MoveRight(x)
{{Move cursor right x characters.}}
  
  repeat x
    Char(MR)
  
PUB MoveUp(y)
{{Move cursor up y lines.}}
  
  repeat y
    Char(MU)
  
PUB MoveDown(y)
{{Move cursor down y lines.}}
  
  repeat y
    Char(MD)
  
PUB Tab
{{Send cursor to next tab position.}}
  
  Char(TB)
  
PUB Backspace
{{Delete one character to left of cursor and move cursor there.}}
  
  Char(BS)
  
PUB Beep
{{Play bell tone on PC speaker.}}
  
  Char(BP)
  
PUB RxCount : count

PUB RxFlush
