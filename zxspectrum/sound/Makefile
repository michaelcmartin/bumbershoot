all: advanced.tzx ay3scale.tzx romscale.tzx

advanced.tzx: advanced.asm sample.dat
	sjasm advanced.asm advanced.bin && ../spectralink.py advanced.bin 8100 && mv advanced.bin.tzx advanced.tzx

ay3scale.tzx: ay3scale.asm sample.dat
	sjasm ay3scale.asm ay3scale.bin && ../spectralink.py ay3scale.bin 7000 && mv ay3scale.bin.tzx ay3scale.tzx

romscale.tzx: romscale.asm sample.dat
	sjasm romscale.asm romscale.bin && ../spectralink.py romscale.bin 7000 && mv romscale.bin.tzx romscale.tzx

sample.dat: ../../sound/conv_1bit ../../sound/wow.wav
	../../sound/conv_1bit ../../sound/wow.wav sample.dat

../../sound/conv_1bit:
	make -C ../../sound conv_1bit

clean:
	rm -f *.tzx *.bin *.lst sample.dat
