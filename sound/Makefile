CFLAGS=-O2

all: conv_amiga conv_dos

conv_amiga: conv_amiga.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_amiga.c wavefile.c

conv_dos: conv_dos.c wavefile.c wavefile.h
	$(CC) $(CFLAGS) -o $@ conv_dos.c wavefile.c

clean:
	rm -f conv_amiga conv_dos
