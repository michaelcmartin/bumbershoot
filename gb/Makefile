LIFE_OBJS = life.o lifemain.o vector.o
RGBFIX_ARGS = -jv -k MB -l 0x33 -p 0x00

all: gb_hello.gb life.gb

clean:
	rm -f *.o *~ *.gb

gb_hello.gb: gb_hello.o
	rgblink -t -o $@ $< && rgbfix $(RGBFIX_ARGS) -m 0 -r 0 -t "HELLOWORLD" $@

life.gb: $(LIFE_OBJS)
	rgblink -t -o $@ $(LIFE_OBJS) && rgbfix $(RGBFIX_ARGS) -m 0 -r 0 -t "CONWAYLIFE" $@

%.o: %.s
	rgbasm -o $@ $<
