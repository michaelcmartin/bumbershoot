all: Hamurabi MakeIcon IntuiTut PNG2Icon WowPlay SongPlay

Hamurabi: hamuwrapper.c ../full/hamurabi.c
	vc +kick13 -o Hamurabi hamuwrapper.c AmiCon.asm -lm13

MakeIcon: MakeIcon.asm
	vasmm68k_mot -Fhunkexe -nosym -kick1hunks -o MakeIcon MakeIcon.asm

IntuiTut: IntuiTut.asm
	vasmm68k_mot -Fhunkexe -nosym -kick1hunks -o IntuiTut IntuiTut.asm

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

clean:
	rm -f Hamurabi MakeIcon IntuiTut PNG2Icon WowPlay SongPlay
