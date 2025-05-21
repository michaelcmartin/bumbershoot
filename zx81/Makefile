all: hello.P xorshift_test.P lightsout81.P wallpaper.P mandala.P

wallpaper.P: wallpaper.asm xorshift.asm
	sjasm wallpaper.asm wallpaper.P

%.P: %.bin
	python zx81link.py -c $<

%.bin: %.asm
	sjasm $< $@

tidy:
	rm -f *.bin *.lst

clean:
	rm -f *.P *.bin *.lst

xorshift_test.bin: xorshift.asm
lightsout81.bin: xorshift.asm
mandala.bin: xorshift.asm
