COBJS = main.o reference_impl.o
SOBJS = scalar.o sse2.o avx.o

all: reference_impl scalar sse2 avx

clean:
	rm -f reference_impl scalar sse2 avx $(COBJS) $(SOBJS)

reference_impl: main.o reference_impl.o
	gcc -o $@ main.o reference_impl.o

scalar: main.o scalar.o
	gcc -o $@ main.o scalar.o

sse2: main.o sse2.o
	gcc -o $@ main.o sse2.o

avx: main.o avx.o
	gcc -o $@ main.o avx.o

$(COBJS): %.o: %.c
	gcc -c -O2 -o $@ $<

$(SOBJS): %.o: %.s
	nasm -f elf64 $<

main.o: stb_image_write.h
