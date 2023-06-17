CFLAGS=-O2

all: conv_amiga conv_dos conv_nes_pcm conv_nes_dmc conv_iigs revbits sndplay

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

sndplay: sndplay.c wavefile.c wavefile.h sinestra.c wow.c bumbershoot.c
	$(CC) $(CFLAGS) -o $@ `sdl2-config --cflags` sndplay.c wavefile.c sinestra.c wow.c bumbershoot.c `sdl2-config --libs`

sinestra.bin: ../asm/fonts/sinestra.s
	ophis -o sinestra.bin ../asm/fonts/sinestra.s

sinestra.c: sinestra.bin
	xxd -i sinestra.bin > sinestra.c

wow.c: wow.wav
	xxd -i wow.wav > wow.c

bumbershoot.c: bumbershoot.wav
	xxd -i bumbershoot.wav > bumbershoot.c

clean:
	rm -f conv_amiga conv_dos conv_nes_pcm conv_nes_dmc revbits conv_iigs sndplay wow.c bumbershoot.c sinestra.c sinestra.bin
