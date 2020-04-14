SimEvo: simevo.c simevo.h simevo_sdl2.c
	gcc -o SimEvo -O2 `sdl2-config --cflags` simevo.c simevo_sdl2.c `sdl2-config --libs`

SimEvoCLI: simevo.c simevo.h simevo_cli.c
	gcc -o SimEvoCLI -O2 simevo.c simevo_cli.c

clean:
	rm -f SimEvo SimEvoCLI
