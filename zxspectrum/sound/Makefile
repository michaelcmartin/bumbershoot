advanced.tzx: advanced.asm
	sjasm advanced.asm advanced.bin && ../spectralink.py advanced.bin 8100 && mv advanced.bin.tzx advanced.tzx

clean:
	rm -f advanced.bin advanced.lst advanced.tzx
