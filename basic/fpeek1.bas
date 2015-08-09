10 v=49152:poke 785,0:poke 786,192
20 read a:if a<256 then poke v,a:v=v+1:goto 20
30 print chr$(147);"floating point peek"
40 input "enter address (0 to quit)";a
50 if a=0 then end
60 if a<0 or a>65531 then print "invalid address":goto 40
70 print "address";a;"has value";usr(a)
80 goto 40
90 data 32,247,183,165,20,164,21,76,162,187,999
