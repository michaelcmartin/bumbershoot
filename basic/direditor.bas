' This is a C64List listing! petcat will not accept it.
' Update to the latest version of this file to create the program.
{alpha:invert}
{number:10}{step:10}

  rem DIRECTORY EDITOR
  rem BUMBERSHOOT SOFTWARE, 2016
{step:1}
  dim sn%(17),de$(143),d%(17)
  rem SN%=SECTOR NUMBER FOR EACH BLK
  rem DE$=DIRECTORY ENTRIES
  rem D%=DIRTY BITS
  rem NS=NUMBER OF DIR SECTORS
  rem DV=TARGET DRIVE (SET BELOW)
{nice:10}{step:10}
  gosub {:initdrive}:rem INIT DRIVE
  gosub {:main}:rem MAIN PROGRAM
  gosub {:writedir}:rem WRITE CHANGES
  end

{nice:100}
{:listfiles}
  rem LIST FILES
  for i=1 to ns*8
  print i;"{left}. ";mid$(de$(i-1),4,16)
  next i
  return

{nice:100}
{:exchangefiles}
  rem EXCHANGE ENTRIES I1 AND I2
  t$=de$(i1-1):de$(i1-1)=de$(i2-1):de$(i2-1)=t$
  d%(int((i1-1)/8))=1:d%(int((i2-1)/8))=1
  return


{nice:1000}
{:main}
  rem MAIN MENU LOOP
  gosub {:listfiles}:rem LIST FILES
{:mainmenu}
  print "{rvrs on}l{rvrs off}ist files"
  print "{rvrs on}m{rvrs off}ove a file":print"e{rvrs on}x{rvrs off}change two files"
  print "change file {rvrs on}t{rvrs off}ype"
  print "{rvrs on}q{rvrs off}uit":print:print "which? ";
{:mainmenu-keyloop}
  get a$:if a$="q" then print "quit":return
  a=-(a$="l")-2*(a$="m")-3*(a$="x")-4*(a$="t"):if a=0 then {:mainmenu-keyloop}
  on a gosub {:list-option},{:move-option},{:exchange-option},{:type-option}
  goto {:mainmenu}

{nice:100}
{:list-option}
  rem LIST FILE OPTION
  print "list files"
  gosub {:listfiles}
  return

{nice:100}
{:move-option}
  rem MOVE FILE OPTION
  print "move a file":input "from";i1:input "to";i2
  i3=i2:di=-1:if i1<i3 then di=1
{:movefiles-loop}
  if i1=i3 then return
  i2=i1+di:gosub {:exchangefiles}:i1=i1+di:goto {:movefiles-loop}
  return

{nice:100}
{:exchange-option}
  rem EXCHANGE FILES OPTION
  print "exchange two files":input "switch file";i1:input "with file";i2
  gosub {:exchangefiles}
  return

{nice:100}
{:type-option}
  rem CHANGE FILE TYPE OPTION
  print "change file type":input "which file";i1
  print "{rvrs on}n{rvrs off}ot a file":print "{rvrs on}d{rvrs off}elimiter"
  print "{rvrs on}s{rvrs off}equential":print "{rvrs on}p{rvrs off}rogram"
  print "{rvrs on}u{rvrs off}ser":print "{rvrs on}r{rvrs off}elative"
  oc=asc(de$(i1-1)):c=oc:gosub {:hr-filetype}:print "current file type: ";c$
  print "which type? ";
{:filetype-loop}
  get a$
  a=126-(a$="n")-2*(a$="d")-3*(a$="s")-4*(a$="p")-5*(a$="u")-6*(a$="r")
  if a=126 then {:filetype-loop}
  c=a:gosub {:hr-filetype}:print c$
  if a=127 then a=0
  de$(i1-1)=chr$(a)+right$(de$(i1-1),29)
  if oc=0 and a<>0 then eu=1
  if oc<>0 and a=0 then es=1
  if oc<>a then d%(int((i1-1)/8))=1
  return

{nice:100}
{:hr-filetype}
  rem HUMAN-READABLE FILE TYPE
  if c=0 then c$="not a file":return
  if c=128 then c$="delimiter":return
  if c=129 then c$="sequential":return
  if c=130 then c$="program":return
  if c=131 then c$="user":return
  if c=132 then c$="relative":return
  c$="unknown ("+mid$(str$(c),2)+")"
  return

{nice:1000}
{:initdrive}
  rem SELECT AND READ DRIVE
{:selectdrive}
  input "which drive (8-11)";a$:dv=val(a$):if dv<8 or dv>11 then {:selectdrive}
  open 15,dv,15,"i0":input#15,ec,em$,ft,fs
  if ec<>0 then print "error code";ec;"on track";ft;"sector";fs:print em$
  if ec<>0 then close 15:goto {:selectdrive}
  open 3,dv,2,"#"
  t=18:s=1:ns=0
{:readsector}
  sn%(ns)=s:print#15,"u1:";2;0;t;s
  print "reading track";t;"sector";s
  get#3,a$:t=asc(a$+chr$(0)):get#3,a$:s=asc(a$+chr$(0))
  for i=0 to 7:if i<>0 then get#3,a$:get#3,a$
  de$="":for j=1 to 30:get#3,a$:de$=de$+chr$(asc(a$+chr$(0))):next j
  de$(ns*8+i)=de$:next i
  d%(ns)=0:ns=ns+1:if t=18 then {:readsector}
  close 3:close 15
  es=0:eu=0
  return

{nice:1000}
{:writedir}
  rem WRITE/VALIDATE DIRECTORY INFO
  vl=1:if eu=0 then {:write-never-unscratched}
  print "you undeleted a file this session. it"
  print "is {white}{rvrs on} highly recommended {rvrs off}{lt. blue} that you"
  print "validate the disk to ensure that all"
  print "file blocks are properly allocated.":goto {:ask-validation}
{:write-never-unscratched}
  if es=0 then {:ask-validation}
  print "you deleted a file this session. you"
  print "will be unable to reuse that file's"
  print "disk blocks until you validate."
{:ask-validation}
  print:print "do you wish to validate the disk? ";
{:ask-loop}
  get a$:vl=-(a$="n")-2*(a$="y"):on vl goto {:ask-no},{:ask-yes}:goto {:ask-loop}
{:ask-no}
  print "no":goto {:do-write}
{:ask-yes}
  print "yes"
{:do-write}
  open 15,dv,15:open 3,dv,2,"#"
  for i=0 to ns-1:if d%(i)=0 then {:writedir-continue}
  print "writing track";18;"sector";sn%(i)
  print#15,"b-p:";2;0
  if i+1=ns then print#3,chr$(0);chr$(255);:goto {:writedir-entries}
  print#3,chr$(18);chr$(sn%(i+1));
{:writedir-entries}
  print#3,de$(i*8);:for j=1 to 7:print#3,chr$(0);chr$(0);de$(i*8+j);:next j
  print#15,"u2:";2;0;18;sn%(i):d%(i)=0
{:writedir-continue}
  next i
  close 3
  if vl<>2 then {:writedir-complete}
  print "validating disk"
  print#15,"v0"
  es=0:eu=0
{:writedir-complete}
  close 15:return
