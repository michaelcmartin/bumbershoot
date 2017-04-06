tcc -mt -Icommon imfplay.c common\adlib.c common\pit.c
tcc -ms -Icommon clover.c common\pit.c

