   10 poke 53280,0:poke 53281,0:i=rnd(-ti)
   20 cm=55296:for i=0 to 3:read dx(i),dy(i):next
   30 print "{wht}{clr}";tab(11);"diffusion chamber"
   40 print tab(9);"press any key to quit"
   50 print "{down}{down}";tab(11);"{CBM-A}CCCCCCCCCCCCCCC{CBM-S}"
   60 for i=1 to 15:print tab(11);"{wht}{SHIFT--}{rvon}{red}       {blk} {grn}       {rvof}{wht}{SHIFT--}":next
   70 print tab(11);"{CBM-Z}CCCCCCCCCCCCCCC{CBM-X}{home}"
   80 x=int(rnd(1)*15)+12:y=int(rnd(1)*15)+5
   90 i=int(rnd(1)*4):dx=dx(i):dy=dy(i)
  100 o=cm+x+y*40:od=o+dy*40+dx
  110 if (peek(o)<>242) and (peek(o)<>245) then 140
  120 if peek(od)<>240 then 140
  130 poke od,peek(o):poke o,0
  140 get a$:if a$="" then 80
  150 poke 53280,14:poke 53281,6
  160 print "{lblu}{clr}";
  170 data -1,0,1,0,0,-1,0,1

