10 GRAPHICS 0:PRINT CHR$(125)
20 DIM B$(18)
30 B$(1)=CHR$(17):FOR I=2 TO 17:B$(I)=CHR$(18):NEXT I:B$(18)=CHR$(5)
40 DLIST=PEEK(560)+256*PEEK(561)
50 V=PEEK(DLIST+4)+256*PEEK(DLIST+5)+212
60 PRINT "         ATARI SCREEN CODES"
70 PRINT
80 PRINT "          0123456789ABCDEF"
90 PRINT "         ";B$
100 FOR I=0 TO 9:PRINT "        ";I;"|                |":NEXT I
110 FOR I=0 TO 5:PRINT "        ";CHR$(65+I);"|                |":NEXT I
120 B$(1)=CHR$(26):B$(18)=CHR$(3)
130 PRINT "         ";B$
140 N=0:FOR I=0 TO 255
150 POKE V+N,I
160 N=N+1:IF N=16 THEN N=0:V=V+40
170 NEXT I
180 POSITION 2,20
