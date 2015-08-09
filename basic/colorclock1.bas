10 rem color-clock experiment
20 print "loading, please wait..."
30 d=36:rem offset into delay code (0-49)
40 for i=49152 to 49234:read v:poke i,v:next
50 poke 56333,127:poke 788,d:poke 789,192:poke 53265,27:poke 53266,1
60 poke 53281,0:poke 53274,1
70 print "{clr}{blk}{down}{5 right}raster interrupt cycle counter"
80 print "{9 down}{wht}{12 right}target raster is"
90 print "{11 right}between these rows"
100 print "{5 down}{6 right}use +/- keys to change delay"
110 print "{12 right}press f7 to quit"
120 rem main loop
130 if d=49 then t=6:goto 150
140 t=56-d
150 print "{home}{blk}{5 down}{8 right}current delay:";t;"{left} cycles "
160 poke 788,d
170 get a$
180 if a$="-" and d<49 then d=d+1:goto 130
190 if a$="+" and d>0 then d=d-1:goto 130
200 if a$<>"{f7}" then 170
210 rem return to status quo
220 poke 53274,0:poke 788,49:poke 789,234:poke 56333,129
230 poke 53281,6:print "{lblu}{clr}";
240 end
250 data 201,201,201,201,201,201,201,201,201,201,201,201,201,201,201,201,201
260 data 201,201,201,201,201,201,201,201,201,201,201,201,201,201,201,201,201
270 data 201,201,201,201,201,201,201,201,201,201,201,201,201,197,234,238,33
280 data 208,169,1,141,25,208,174,18,208,48,7,169,15,141,33,208,169,146,141,18
290 data 208,173,13,220,240,3,76,49,234,76,188,254
