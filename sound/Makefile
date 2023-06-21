CFLAGS=-O2

all: conv_amiga conv_dos conv_nes_pcm conv_nes_dmc conv_iigs revbits sndplay_sdl2

conv_amiga: conv_amiga.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_amiga.c wavefile.c

conv_dos: conv_dos.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_dos.c wavefile.c

conv_nes_pcm: conv_nes_pcm.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_nes_pcm.c wavefile.c

conv_nes_dmc: conv_nes_dmc.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_nes_dmc.c wavefile.c

conv_iigs: conv_iigs.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_iigs.c wavefile.c

revbits: revbits.c
	$(CC) $(CFLAGS) -o $@ revbits.c

sndplay_sdl2: sndplay_sdl2.c wavefile.c wavefile.h sinestra.c wow.c bumbershoot.c
	$(CC) $(CFLAGS) -o $@ `sdl2-config --cflags` sndplay_sdl2.c wavefile.c sinestra.c wow.c bumbershoot.c `sdl2-config --libs`

sndplay_dx9.exe: sndplay_dx9.c wavefile.c wavefile.h sndplay_dx9-res.o ../win32/dx9pixmap.c ../win32/dx9pixmap.h
	$(CC) $(CFLAGS) -mwindows -municode -D_UNICODE -I../win32 -o $@ sndplay_dx9.c wavefile.c ../win32/dx9pixmap.c sndplay_dx9-res.o -ld3d9 -ldsound

sinestra.bin: ../asm/fonts/sinestra.s
	ophis -o sinestra.bin ../asm/fonts/sinestra.s

sinestra.c: sinestra.bin
	xxd -i sinestra.bin > sinestra.c

wow.c: wow.wav
	xxd -i wow.wav > wow.c

bumbershoot.c: bumbershoot.wav
	xxd -i bumbershoot.wav > bumbershoot.c

sndplay_dx9-res.o: sndplay_dx9.rc sinestra.bin wow.wav bumbershoot.wav
	windres -o $@ $<

clean:
	rm -f conv_amiga conv_dos conv_nes_pcm conv_nes_dmc revbits conv_iigs sndplay_sdl2 wow.c bumbershoot.c sinestra.c sinestra.bin sndplay_sdl2.exe sndplay_dx9.exe sndplay_dx9-res.o
