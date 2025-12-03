1 rem disk autoloader generator
2 rem 100% basic edition
3 rem by michael martin, 2025
4 rem based in part on a program
5 rem by dan carmichael, published
6 rem in compute!'s gazette, nov 1984
10 print "{clr} please wait..."
20 dim b(72)
30 tt=0:for a=1 to 72:read d:b(a)=d:tt=tt+d:next
40 if tt<>8104 then print "check data statements 695-766":end
50 print "{clr}{down} auto-load a {rvon}b{rvof}asic or {rvon}m{rvof}achine language   program?"
60 get a$:if a$="" then 60
70 if a$="b" then 140
80 if a$<>"m" then 60
90 print "{clr}{down} enter starting address of machine lang. program."
100 input n:if n<0 or n>65535 then 100
110 for a=38 to 51:read b(a):next
120 nn=int(n/256):b(47)=n-(nn*256):b(48)=nn:b(16)=1
130 for a=52 to 72:b(a)=0:next
140 print "{clr}{down} enter name of program that is to be"
150 print " automatically booted.":print"{down} maximum length = 16 characters.{down}{down}"
160 input f$:f$=left$(f$,16):b(21)=len(f$)
170 if len(f$)<16 then f$=f$+chr$(0):goto 170
180 print "{clr}{down} place newly formatted disk in drive,{4 space}then press f1."
190 get a$:if a$<>"{f1}" then 190
200 print "{clr}{down} enter name of boot program.{down}"
210 print " maximum length = 16 characters.{down}{down}"
220 input bn$:bn$=left$(bn$,16)
230 open 15,8,15,"i0"
240 open 2,8,2,"0:"+bn$+",p,w"
250 print#2,chr$(167);chr$(2);f$;
260 for a=1 to 72:print#2,chr$(b(a));:next
270 print#2,chr$(0);chr$(139);chr$(227);chr$(183);chr$(2);
280 close 2:close 15
290 print "{clr}{down} autoboot program written to disk."
299 end
695 data 169,131,141,2,3,169,164,141
703 data 3,3,169,1,162,8,160,0
711 data 32,186,255,169,0,162,167,160
719 data 2,32,189,255,169,0,166,43
727 data 164,44,32,213,255,134,45,134
735 data 47,132,46,132,48,32,231,255
743 data 32,51,165,162,4,134,198,202
751 data 189,251,2,157,119,2,202,16
759 data 247,76,116,164,82,85,78,13
1732 data 32,66,166,169,13,32,210,255
1740 data 32,0,0,76,116,164
