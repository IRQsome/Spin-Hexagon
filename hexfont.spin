VAR

long init

PUB get | i,l

ifnot init~~
  'wtf_fastspin '' call another function to make this a non-leaf function to get fastspin to not allocate a million registers
  repeat i from 0 to constant((@fontptrs_last - @fontptrs)/2)
    ifnot fontptrs[i] >> 15
      fontptrs[i] := @@fontptrs[i]

return @fontptrs

DAT

{{
  Terrible 8x8 version of "Bump IT UP" by Aaron Amar
  https://fontstruct.com/fontstructions/show/155156/bump_it_up

  Licensed as Creative Commons Attribution Share Alike

}}

fontptrs word
word $8080 ' space
word (@chr_exclamation)
word (@chr_minus)[11] ' skip gunk
word (@chr_minus)
word (@chr_dot)
word (@chr_minus)[1] ' skip /
word (@chr_o) ' use O as 0
word (@chr_1)
word (@chr_2)
word (@chr_3)
word (@chr_4)
word (@chr_5)
word (@chr_6)
word (@chr_7)
word (@chr_8)
word (@chr_9)
word (@chr_colon)
word (@chr_minus)[6] ' skip gunk
word (@chr_a)
word (@chr_b)
word (@chr_c)
word (@chr_d)
word (@chr_e)
word (@chr_f)
word (@chr_g)
word (@chr_h)
word (@chr_i)
word (@chr_j)
word (@chr_k)
word (@chr_l)
word (@chr_m)
word (@chr_n)
word (@chr_o)
word (@chr_p)
word (@chr_q)
word (@chr_r)
word (@chr_s)
word (@chr_t)
word (@chr_u)
word (@chr_v)
word (@chr_w)
word (@chr_x)
word (@chr_y)   
fontptrs_last
word (@chr_z)




DAT

' import char 0
chr_exclamation
byte %00000110
byte %00000110
byte %00000110
byte %00000110
byte %00000110
byte %00000000
byte %00000110
byte %00000110

' import char 1
chr_minus
byte %00000000
byte %00000000
byte %00000000
byte %01111110
byte %01111110
byte %00000000
byte %00000000
byte %00000000
' import char 2
chr_dot
byte %00000000
byte %00000000
byte %00000000
byte %00000000
byte %00000000
byte %00000000
byte %00000110
byte %00000110
{
' import char 3
chr_0
byte %11111110
byte %11111111
byte %11000011
byte %11011011
byte %11011011
byte %11000011
byte %11111111
byte %01111111
}
' import char 4 
chr_1
byte %00001111
byte %00011111
byte %00011000
byte %00011000
byte %00011000
byte %00011000
byte %11111111
byte %11111111
' import char 5
chr_2
byte %11111111
byte %11111111
byte %11000000
byte %11111110
byte %01111111
byte %00000011
byte %11111111
byte %11111111
' import char 6
chr_3
byte %01111111
byte %11111111
byte %11000000
byte %11111111
byte %11111111
byte %11000000
byte %11111111
byte %01111111
' import char 7
chr_4
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11111111
byte %11111110
byte %11000000
byte %11000000
' import char 8
chr_5
byte %11111111
byte %11111111
byte %00000011
byte %01111111
byte %11111110
byte %11000000
byte %11111111
byte %11111111
' import char 9
chr_6
byte %11111111
byte %11111111
byte %00000011
byte %01111111
byte %11111111
byte %11000011
byte %11111111
byte %11111111
' import char 10    
chr_7
byte %01111111
byte %11111111
byte %11000000
byte %11000000
byte %11000000
byte %11000000
byte %11000000
byte %11000000
' import char 11
chr_8
byte %11111110
byte %11111111
byte %11000011
byte %11111111
byte %11111111
byte %11000011
byte %11111111
byte %01111111
' import char 12
chr_9
byte %11111111
byte %11111111
byte %11000011
byte %11111111
byte %11111110
byte %11000000
byte %11111111
byte %11111111
' import char 13
chr_colon
byte %00000000
byte %00000000
byte %00000000
byte %00010000
byte %00011000
byte %00000000
byte %00011000
byte %00001000
' import char 14
chr_a
byte %11111110
byte %11111111
byte %11000011
byte %11000011
byte %11111111
byte %11111111
byte %11000011
byte %11000011
' import char 15
chr_b
byte %11111111
byte %11111111
byte %11000011
byte %01111111
byte %01111111
byte %11000011
byte %11111111
byte %11111111
' import char 16 
chr_c
byte %11111111
byte %11111111
byte %00000011
byte %00000011
byte %00000011
byte %00000011
byte %11111111
byte %11111110
' import char 17 
chr_d
byte %01111111
byte %11111111
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11111111
byte %11111111
' import char 18
chr_e
byte %11111111
byte %11111111
byte %00000011
byte %11111111
byte %11111111
byte %00000011
byte %11111111
byte %11111110
' import char 19
chr_f
byte %11111110
byte %11111111
byte %00000011
byte %11111111
byte %11111111
byte %00000011
byte %00000011
byte %00000011
' import char 20
chr_g
byte %11111111
byte %11111111
byte %00000011
byte %11000011
byte %11000011
byte %11000011
byte %11111111
byte %01111111
' import char 21
chr_h
byte %11000011
byte %11000011
byte %11000011
byte %11111111
byte %11111111
byte %11000011
byte %11000011
byte %11000011
' import char 22 
chr_i
byte %11111111
byte %11111111
byte %00011000
byte %00011000
byte %00011000
byte %00011000
byte %11111111
byte %11111111
' import char 23
chr_j
byte %11000000
byte %11000000
byte %11000000
byte %11000000
byte %11000000
byte %11000011
byte %11111111
byte %01111111
' import char 24
chr_k
byte %11000011
byte %11000011
byte %11000011
byte %01111111
byte %01111111
byte %11000011
byte %11000011
byte %11000011
' import char 25
chr_l
byte %00000011
byte %00000011
byte %00000011
byte %00000011
byte %00000011
byte %00000011
byte %11111111
byte %11111110
' import char 26
chr_m
byte %11100111
byte %11111111
byte %11011011
byte %11011011
byte %11011011
byte %11011011
byte %11011011
byte %11011011
' import char 27
chr_n
byte %01111111
byte %11111111
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11000011
' import char 28
chr_o
byte %11111110
byte %11111111
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11111111
byte %01111111
' import char 29 
chr_p
byte %11111111
byte %11111111
byte %11000011
byte %11000011
byte %11111111
byte %01111111
byte %00000011
byte %00000011
' import char 30 
chr_q
byte %11111110
byte %11111111
byte %11000011
byte %11000011
byte %11000011
byte %11011011
byte %11111111
byte %01111111
' import char 31
chr_r
byte %01111111
byte %11111111
byte %11000011
byte %11000011
byte %01111111
byte %01111111
byte %11000011
byte %11000011
' import char 32
chr_s
byte %11111110
byte %11111111
byte %00000011
byte %11111111
byte %11111111
byte %11000000
byte %11111111
byte %01111111
' import char 33
chr_t
byte %11111111
byte %11111111
byte %00011000
byte %00011000
byte %00011000
byte %00011000
byte %00011000
byte %00011000
' import char 34
chr_u
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11111111
byte %11111110
' import char 35
chr_v
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11111111
byte %01111111
' import char 36
chr_w
byte %11011011
byte %11011011
byte %11011011
byte %11011011
byte %11011011
byte %11011011
byte %11111111
byte %11111110
' import char 37
chr_x
byte %11000011
byte %11000011
byte %11000011
byte %01111110
byte %01111110
byte %11000011
byte %11000011
byte %11000011
' import char 38
chr_y
byte %11000011
byte %11000011
byte %11000011
byte %11000011
byte %11111111
byte %01111110
byte %00011000
byte %00011000
' import char 39
chr_z
byte %01111111
byte %11111111
byte %11000000
byte %11111111
byte %11111111
byte %00000011
byte %11111111
byte %11111110
{
' import char 40
byte %00000000
byte %00000000
byte %00000000
byte %00000000
byte %00000000
byte %00000000
byte %00000000
byte %00000000
}