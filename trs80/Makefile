bin2cmd: bin2cmd.c
	gcc -O2 -o $@ $<

%.cmd: %.bin bin2cmd
	./bin2cmd $< 6a00

%.bin: %.asm
	z80asm -b -r6a00 $<

tidy:
	rm -f *.map *.bin *.obj *.sym

clean:
	rm -f *.cmd *.map. *.bin *.obj *.sym
