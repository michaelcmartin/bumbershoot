10 for i=49152 to 49191:read a:poke i,a:next
20 for i=1024 to i+1000:poke i,160:poke i+54272,11:next i
30 for i=0 to 15:for j=0 to 15
40 p=1196+40*i+j:poke p,j+1:poke p+54272,j:next j,i
50 poke 53265,27:poke 53266,90:poke 251,90:poke 53281,0
60 poke 56333,127:poke 788,0:poke 789,192:poke 53274,1
70 get a$:if a$="" then 70
80 poke 53274,0:poke 788,49:poke 789,234:poke 56333,129
90 print chr$(147);:poke 53281,6
100 data 169,1,141,25,208,238,33,208,165,251,24,105,8,201,218,144,7,169,0,141
110 data 33,208,169,90,141,18,208,133,251,173,13,220,240,3,76,49,234,76,188,254
