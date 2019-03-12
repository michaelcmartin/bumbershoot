all: hello.P xorshift_test.P lightsout81.P wallpaper.P mandala.P

wallpaper.P: wallpaper.asm xorshift.asm
	z80asm -b -r4009 wallpaper.asm && mv wallpaper.bin wallpaper.P

%.P: %.bin
	python zx81link.py -c $<

%.bin: %.asm
	z80asm -b -r4090 $<

tidy:
	rm -f *.map *.bin *.obj *.sym

clean:
	rm -f *.P *.map *.bin *.obj *.sym

xorshift_test.bin: xorshift.asm
lightsout81.bin: xorshift.asm
mandala.bin: xorshift.asm
