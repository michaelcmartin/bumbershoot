SimEvo: simevo.c simevo.h modern_support.c modern_support.h simevo_sdl2.c
	gcc -o SimEvo -O2 `sdl2-config --cflags` simevo.c modern_support.c simevo_sdl2.c `sdl2-config --libs`

SimEvoCLI: simevo.c simevo.h modern_support.c modern_support.h simevo_cli.c
	gcc -o SimEvoCLI -O2 simevo.c modern_support.c simevo_cli.c

simevo.xex: simevo_a800_xex.s simevo_a800_shell.s simevocore.s
	ophis simevo_a800_xex.s

simevo.atr: simevo_a800_atr.s simevo_a800_shell.s simevocore.s
	ophis simevo_a800_atr.s

simevo.prg: simevo64.s mcbitmap.s simevocore.s
	ophis simevo64.s

simevo.tos: simevo.c simevo.h simevost.c stevolib.h stevolib.asm
	vc +tos16 -o simevo.tos simevost.c simevo.c stevolib.asm

# The DOS version, simevo.com, is not built with cross tools, but is
# instead built within a DOS environment with Borland Turbo C. The
# following commands will build the program from source (assuming that
# Turbo C is installed in C:\TC):
#
# C:\TC\TCC -f- -mt -c DOS_EVO.C
# C:\TC\TCC -f- -mt -c SIMEVO.C
# C:\TC\TLINK /t C:\TC\LIB\C0T.OBJ DOS_EVO.OBJ SIMEVO.OBJ,SIMEVO.COM,,C:\TC\LIB\CS.LIB
#
# If you are starting in a Unix-like environment, you may need to use
# the unix2dos utility to convert dos_evo.c, simevo.c, and simevo.h
# into DOS-style text files.

all: SimEvo SimEvoCLI simevo.xex simevo.atr simevo.prg simevo.tos

clean:
	rm -f SimEvo SimEvoCLI simevo.xex simevo.atr simevo.prg simevo.tos
