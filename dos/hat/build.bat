nasm -f obj -o keywait.obj keywait.asm
nasm -f obj -o cgaext.obj cgaext.asm
nasm -f obj -o hataux.obj hataux.asm
nasm -f obj -o c_hataux.obj c_hataux.asm
tpc keywait.pas
tpc systimer.pas
tpc cga.pas
tpc cgaasm.pas
tpc hat1.pas
tpc hat2.pas
tpc hat3.pas
tpc hat4.pas
tcc -mt -f87 c_hat.c c_hataux.obj
