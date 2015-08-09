10 print chr$(147);"floating point peek"
20 clr:v=0:pv=peek(45)+256*peek(46)+2
30 input "enter address (0 to quit)";a
40 if a=0 then end
50 if a<0 or a>65531 then print "invalid address":goto 30
60 for i=0 to 4:poke pv+i,peek(a+i):next i
70 print "address";a;"has value";v
80 goto 30
