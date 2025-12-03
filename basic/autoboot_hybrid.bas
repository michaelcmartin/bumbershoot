1 rem disk autoloader generator
2 rem by michael martin, 2025
3 rem based in part on a program
4 rem by dan carmichael, published
5 rem in compute!'s gazette, nov 1984
10 print "{clr} please wait..."
20 b=695:c=766:tt=0
30 for a=679 to 694:poke a,0:next:poke 767,0
40 for a=b to c:read d:tt=tt+d:poke a,d:next
50 if tt<>8104 then print "check data statements";b;"to";c:end
60 b=844:c=899:tt=0
70 for a=b to c:read d:tt=tt+d:poke a,d:next
80 if tt<>6978 then print "check data statements";b;"to";c:end
90 print "{clr}{down} auto-load a {rvon}b{rvof}asic or {rvon}m{rvof}achine language   program?"
100 get a$:if a$="" then 100
110 if a$="b" then 190
120 if a$<>"m" then 100
130 print "{clr}{down} enter starting address of machine lang. program."
140 input n:if n<0 or n>65535 then 140
150 for a=732 to 745:read d:poke a,d:next
160 nn=int(n/256):poke 741,n-(nn*256):poke 742,nn
170 poke 710,1
180 for a=746 to 767:poke a,0:next
190 print "{clr}{down} enter name of program that is to be"
200 print " automatically booted.":print"{down} maximum length = 16 characters.{down}{down}"
210 input a$:a$=left$(a$,16)
220 for i=1 to len(a$):poke 678+i,asc(mid$(a$,i,1)):next i
230 poke 715,len(a$)
240 print "{clr}{down} place newly formatted disk in drive,{4 space}then press f1."
250 get a$:if a$<>"{f1}" then 250
260 print "{clr}{down} enter name of boot program.{down}"
270 print " maximum length = 16 characters.{down}{down}"
280 input a$:a$=left$(a$,16)
290 for i=1 to len(a$):poke 827+i,asc(mid$(a$,i,1)):next i
300 poke 845,len(a$)
310 sys 844:print "{clr}{down} autoboot program written to disk."
320 end
695 data 169,131,141,2,3,169,164,141
703 data 3,3,169,1,162,8,160,0
711 data 32,186,255,169,0,162,167,160
719 data 2,32,189,255,169,0,166,43
727 data 164,44,32,213,255,134,45,134
735 data 47,132,46,132,48,32,231,255
743 data 32,51,165,162,4,134,198,202
751 data 189,251,2,157,119,2,202,16
759 data 247,76,116,164,82,85,78,13
844 data 169,0,162,60,160,3,32,189
852 data 255,169,8,170,160,255,32,186
860 data 255,169,167,133,251,169,183,141
868 data 2,3,169,2,133,252,141,3
876 data 3,169,251,162,4,160,3,32
884 data 216,255,32,231,255,169,131,141
892 data 2,3,169,164,141,3,3,96
1732 data 32,66,166,169,13,32,210,255
1740 data 32,0,0,76,116,164
