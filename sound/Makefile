CFLAGS=-O2

all: conv_amiga conv_dos conv_nes_pcm conv_nes_dmc revbits

conv_amiga: conv_amiga.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_amiga.c wavefile.c

conv_dos: conv_dos.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_dos.c wavefile.c

conv_nes_pcm: conv_nes_pcm.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_nes_pcm.c wavefile.c

conv_nes_dmc: conv_nes_dmc.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_nes_dmc.c wavefile.c

revbits: revbits.c
	$(CC) $(CFLAGS) -o $@ revbits.c

clean:
	rm -f conv_amiga conv_dos conv_nes_pcm conv_nes_dmc revbits
