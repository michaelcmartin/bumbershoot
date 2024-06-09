all: Hamurabi MakeIcon IntuiTut PNG2Icon WowPlay SongPlay HWLogo AmEGA

Hamurabi: hamuwrapper.c ../full/hamurabi.c
	vc +kick13 -o Hamurabi hamuwrapper.c AmiCon.asm -lm13

MakeIcon: MakeIcon.asm
	vasmm68k_mot -Fhunkexe -nosym -kick1hunks -o MakeIcon MakeIcon.asm

IntuiTut: IntuiTut.asm
	vasmm68k_mot -Fhunkexe -nosym -kick1hunks -o IntuiTut IntuiTut.asm

HWLogo: HWLogo.asm include/BareMetal.i include/SafeStart.i res/bumberlogo.bin
	vasmm68k_mot -Fhunkexe -nosym -kick1hunks -o HWLogo HWLogo.asm

AmEGA: AmEGA.asm include/BareMetal.i include/SafeStart.i res/sinestra.bin
	vasmm68k_mot -Fhunkexe -nosym -kick1hunks -o AmEGA AmEGA.asm

PNG2Icon: PNG2Icon.c LibIcon.asm LibIcon.h ../win32/stb_image.h
	vc +kick13 -o PNG2Icon PNG2Icon.c LibIcon.asm -lm13

WowPlay: WavPlay.asm WowCaption.asm ../sound/conv_amiga ../sound/wow.wav
	../sound/conv_amiga ../sound/wow.wav WavPlayRaw.bin && \
		cp WowCaption.asm WavPlayCaption.asm && \
		vasmm68k_mot -Fhunkexe -nosym -kick1hunks -o WowPlay WavPlay.asm

SongPlay: WavPlay.asm SongCaption.asm ../sound/conv_amiga ../sound/bumbershoot.wav
	../sound/conv_amiga ../sound/bumbershoot.wav WavPlayRaw.bin && \
		cp SongCaption.asm WavPlayCaption.asm && \
		vasmm68k_mot -Fhunkexe -nosym -kick1hunks -o SongPlay WavPlay.asm

../sound/conv_amiga:
	make -C ../sound conv_amiga

support/makelogo: support/makelogo.c
	gcc -O2 -I../win32 -o support/makelogo support/makelogo.c -lm

res/sinestra.bin:
	ophis -o res/sinestra.bin ../asm/fonts/sinestra.s

res/bumberlogo.bin: res/logo128.png support/makelogo
	cd res && ../support/makelogo logo128.png

clean:
	rm -f Hamurabi MakeIcon IntuiTut PNG2Icon WowPlay SongPlay HWLogo AmEGA res/sinestra.bin res/bumberlogo.bin support/makelogo
