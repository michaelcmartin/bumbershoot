OBJS=gfx.o main.o shell.o

LightsOut.nes: $(OBJS) nrom_128.cfg
	ld65 -C nrom_128.cfg -o $@ $(OBJS)

%.o: %.s
	ca65 $<

clean:
	rm -f *.o LightsOut.nes

tidy:
	rm -f *.o
