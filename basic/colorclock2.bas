10 rem color-clock experiment
20 print "loading, please wait..."
30 d=36:rem offset into delay code (0-49)
40 tr=146:rem target raster
50 for i=49152 to 49234:read v:poke i,v:next
60 if peek(49220)<>tr then print "{clr}error in data statements":end
70 poke 56333,127:poke 788,d:poke 789,192:poke 53265,27:poke 53266,1
80 poke 53281,0:poke 53274,1
90 print "{clr}{blk}{down}{5 right}raster interrupt cycle counter"
100 print "{7 down}{wht}{12 right}target raster is"
110 print "{4 down}{11 right}between these rows"
120 print "{4 down}{6 right}use +/- keys to change delay"
130 print "{7 right}use f1/f3 to change raster"
140 print "{12 right}press f7 to quit"
150 rem main loop
160 if d=49 then t=6:goto 180
170 t=56-d
180 print "{home}{blk}{4 down}{8 right}current delay:";t;"{left} cycles "
190 print "{8 right}current raster:";tr;"{left} ";(tr and 7);"{3 left}({right})"
200 poke 788,d:poke 49220,tr
210 get a$
220 if a$="-" and d<49 then d=d+1:goto 160
230 if a$="+" and d>0 then d=d-1:goto 160
240 if a$="{f1}" and tr>136 then tr=tr-1:goto 160
250 if a$="{f3}" and tr<156 then tr=tr+1:goto 160
260 if a$<>"{f7}" then 210
270 rem return to status quo
280 poke 53274,0:poke 788,49:poke 789,234:poke 56333,129
290 poke 53281,6:print "{lblu}{clr}";
300 end
310 data 201,201,201,201,201,201,201,201,201,201,201,201,201,201,201,201,201
320 data 201,201,201,201,201,201,201,201,201,201,201,201,201,201,201,201,201
330 data 201,201,201,201,201,201,201,201,201,201,201,201,201,197,234,238,33
340 data 208,169,1,141,25,208,174,18,208,48,7,169,15,141,33,208,169,146,141,18
350 data 208,173,13,220,240,3,76,49,234,76,188,254
