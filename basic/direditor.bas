   10 rem directory editor
   20 rem bumbershoot software, 2016-7
   30 dim sn%(17),de$(143),d%(17)
   31 rem sn%=sector number for each blk
   32 rem de$=directory entries
   33 rem d%=dirty bits
   34 rem ns=number of dir sectors
   35 rem dv=target drive (set below)
   36 rem eu/es=ever (un)scratched
   40 gosub 1000:rem init drive
   50 gosub 2000:rem main program
   60 gosub 3000:rem write changes
   70 end
  100 rem list files
  110 for i=1 to ns*8
  120 print i;"{left}. ";mid$(de$(i-1),4,16)
  130 next i
  140 return
  200 rem exchange entries i1 and i2
  210 t$=de$(i1-1):de$(i1-1)=de$(i2-1):de$(i2-1)=t$
  220 d%(int((i1-1)/8))=1:d%(int((i2-1)/8))=1
  230 return
 1000 rem select and read drive
 1010 input "which drive (8-11)";a$:dv=val(a$):if dv<8 or dv>11 then 1010
 1020 open 15,dv,15,"i0":input#15,ec,em$,ft,fs
 1030 if ec<>0 then print "error code";ec;"on track";ft;"sector";fs:print em$
 1040 if ec<>0 then close 15:goto 1010
 1050 gosub 1100:rem read directory
 1060 close 15:es=0:eu=0
 1070 return
 1100 rem read directory entries
 1110 open 3,dv,2,"#":t=18:s=1:ns=0
 1120 sn%(ns)=s:print#15,"u1:";2;0;t;s
 1130 print "reading track";t;"sector";s
 1140 get#3,a$:t=asc(a$+chr$(0)):get#3,a$:s=asc(a$+chr$(0))
 1150 for i=0 to 7:if i<>0 then get#3,a$:get#3,a$
 1160 de$="":for j=1 to 30:get#3,a$:de$=de$+chr$(asc(a$+chr$(0))):next j
 1170 de$(ns*8+i)=de$:next i
 1180 d%(ns)=0:ns=ns+1:if t=18 then 1120
 1190 close 3:return
 2000 rem main menu loop
 2010 gosub 100:rem list files
 2020 print "{rvon}l{rvof}ist files"
 2030 print "{rvon}m{rvof}ove a file":print"e{rvon}x{rvof}change two files"
 2040 print "change file {rvon}t{rvof}ype"
 2050 print "{rvon}q{rvof}uit":print:print "which? ";
 2060 get a$:if a$="q" then print "quit":return
 2070 a=-(a$="l")-2*(a$="m")-3*(a$="x")-4*(a$="t"):if a=0 then 2060
 2080 on a gosub 2100,2200,2300,2400
 2090 goto 2020
 2100 rem list file option
 2110 print "list files"
 2120 gosub 100
 2130 return
 2200 rem move file option
 2210 print "move a file":input "from";i1:input "to";i2
 2220 i3=i2:di=-1:if i1<i3 then di=1
 2230 if i1=i3 then return
 2240 i2=i1+di:gosub 200:i1=i1+di:goto 2230
 2250 return
 2300 rem exchange files option
 2310 print "exchange two files":input "switch file";i1:input "with file";i2
 2320 gosub 200
 2330 return
 2400 rem change file type option
 2405 print "change file type":input "which file";i1
 2410 gosub 2500:rem print menu
 2415 oc=asc(de$(i1-1)):c=oc:gosub 2600:print "current file type: ";c$
 2420 print "which type? ";
 2425 get a$
 2430 a=126-(a$="n")-2*(a$="d")-3*(a$="s")-4*(a$="p")-5*(a$="u")-6*(a$="r")
 2435 if a=126 then 2425
 2440 c=a:gosub 2600:print c$
 2445 if a=127 then a=0
 2450 de$(i1-1)=chr$(a)+right$(de$(i1-1),29)
 2455 if oc=0 and a<>0 then eu=1
 2460 if oc<>0 and a=0 then es=1
 2465 if oc<>a then d%(int((i1-1)/8))=1
 2470 return
 2500 rem print file type menu
 2510 print "{rvon}n{rvof}ot a file":print "{rvon}d{rvof}elimiter"
 2520 print "{rvon}s{rvof}equential":print "{rvon}p{rvof}rogram"
 2530 print "{rvon}u{rvof}ser":print "{rvon}r{rvof}elative"
 2540 return
 2600 rem human-readable file type
 2610 if c=0 then c$="not a file":return
 2620 if c=128 then c$="delimiter":return
 2630 if c=129 then c$="sequential":return
 2640 if c=130 then c$="program":return
 2650 if c=131 then c$="user":return
 2660 if c=132 then c$="relative":return
 2670 c$="unknown ("+mid$(str$(c),2)+")"
 2680 return
 3000 rem write/validate directory info
 3010 gosub 3100:rem ask to validate
 3020 open 15,dv,15:open 3,dv,2,"#"
 3030 for i=0 to ns-1:if d%(i)=0 then 3065
 3035 print "writing track";18;"sector";sn%(i)
 3040 print#15,"b-p:";2;0
 3045 if i+1=ns then print#3,chr$(0);chr$(255);:goto 3055
 3050 print#3,chr$(18);chr$(sn%(i+1));
 3055 print#3,de$(i*8);:for j=1 to 7:print#3,chr$(0);chr$(0);de$(i*8+j);:next j
 3060 print#15,"u2:";2;0;18;sn%(i):d%(i)=0
 3065 next i:close 3
 3070 if vl<>2 then 3090
 3080 print "validating disk":print#15,"v0":es=0:eu=0
 3090 close 15:return
 3100 rem ask for validation
 3110 if eu=0 then 3130
 3120 print "you undeleted a file this session. it"
 3121 print "is {wht}{rvon} highly recommended {rvof}{lblu} that you"
 3122 print "validate the disk to ensure that all"
 3123 print "file blocks are properly allocated.":goto 3140
 3130 if es=0 then 3140
 3131 print "you deleted a file this session. you"
 3132 print "will be unable to reuse that file's"
 3133 print "disk blocks until you validate."
 3140 print:print "do you wish to validate the disk? ";
 3150 get a$:if a$="n" then vl=1:print "no":return
 3160 if a$<>"y" then 3150
 3170 vl=2:print "yes":return
