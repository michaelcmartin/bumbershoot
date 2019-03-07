%.P: %.bin
	python zx81link.py -c $<

%.bin: %.asm
	z80asm -b -r4090 $<

tidy:
	rm -f *.map *.bin *.obj *.sym

clean:
	rm -f *.P *.map *.bin *.obj *.sym
