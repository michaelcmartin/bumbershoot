 5 rem expected results: 42 255
10 v=49152:poke 785,0:poke 786,192
20 read a:if a<256 then poke v,a:v=v+1:goto 20
30 print usr(41);usr(-2)
40 data 32,170,177,169,0,200,108,5,0,999
