all: hello.sms sprcont.sms rainbow.sms multiscroll.sms

%.sms: %.asm smsfix
	sjasm $< $@ && ./smsfix $@

smsfix: tools/smsfix.c
	gcc -O2 -o $@ $<

sinestra.bin: ../asm/fonts/sinestra.s
	ophis -o $@ $<

halogen.bin: ../asm/fonts/halogen.s
	ophis -o $@ $<

clean:
	rm -f hello.sms sprcont.sms rainbow.sms multiscroll.sms sinestra.bin halogen.bin smsfix

reallyclean:
	rm -f hello.sms hello.lst sprcont.sms sprcont.lst rainbow.sms rainbow.lst multiscroll.sms multiscroll.lst halogen.bin sinestra.bin smsfix

hello.asm: sega8bios.asm
sprcont.asm: sega8bios.asm ../genesis/res/nyansong.bin sinestra.bin
rainbow.asm: sega8bios.asm sinestra.bin
multiscroll.asm: sega8bios.asm sinestra.bin halogen.bin
