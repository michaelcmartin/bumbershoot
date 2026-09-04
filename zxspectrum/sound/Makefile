advanced.tzx: advanced.asm sample.dat
	sjasm advanced.asm advanced.bin && ../spectralink.py advanced.bin 8100 && mv advanced.bin.tzx advanced.tzx

sample.dat: ../../sound/conv_1bit ../../sound/wow.wav
	../../sound/conv_1bit ../../sound/wow.wav sample.dat

../../sound/conv_1bit:
	make -C ../../sound conv_1bit

clean:
	rm -f advanced.bin advanced.lst advanced.tzx sample.dat
