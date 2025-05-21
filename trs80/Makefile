all: inpnum.cmd zoom.cmd jabber.cmd

bin2cmd: bin2cmd.c
	gcc -O2 -o $@ $<

%.cmd: %.bin bin2cmd
	./bin2cmd $< 6a00

%.bin: %.asm
	sjasm $< $@

tidy:
	rm -f *.bin *.lst

clean:
	rm -f *.cmd *.bin *.lst bin2cmd
