10 s=54272:gosub 100
20 read a,b:if a<25 then poke s+a,b:goto 20
30 get a$:if a$="" then 30
40 gosub 100
99 end
100 for l=s to s+24:poke l,0:next l
110 return
200 data 24,15,0,231,1,55,7,234,8,62,6,240,13,240,4,17,11,17,999,999
