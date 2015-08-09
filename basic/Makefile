BINARIES = colorchart0.prg colorchart1.prg colorchart2.prg \
           colorclock1.prg colorclock2.prg \
           usr.prg fpeek1.prg fpeek2.prg ebs.prg \
           hello.prg striping.prg winceotron.prg

all: $(BINARIES)

clean:
	rm -f *.prg

%.prg: %.bas
	petcat -w2 -o $@ $<
