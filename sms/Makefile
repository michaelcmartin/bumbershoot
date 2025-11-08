all: hello.sms sprcont.sms rainbow.sms

%.sms: %.asm smsfix
	sjasm $< $@ && ./smsfix $@

smsfix: tools/smsfix.c
	gcc -O2 -o $@ $<

sinestra.bin: ../asm/fonts/sinestra.s
	ophis -o $@ $<

clean:
	rm -f hello.sms sprcont.sms rainbow.sms sinestra.bin smsfix

reallyclean:
	rm -f hello.sms hello.lst sprcont.sms sprcont.lst rainbow.sms rainbow.lst smsfix

hello.asm: sega8bios.asm
sprcont.asm: sega8bios.asm ../genesis/res/nyansong.bin sinestra.bin
rainbow.asm: sega8bios.asm sinestra.bin
