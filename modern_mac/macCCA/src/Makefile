COBJS = CCA.o
OBJCOBJS = AppDelegate.o CCAView.o MainView.o main.o

CFLAGS = -O2 -Wall -mmacosx-version-min=10.7 -Wunguarded-availability
OBJCFLAGS = $(CFLAGS) -ObjC -fobjc-arc

CCA: $(COBJS) $(OBJCOBJS)
	clang $(OBJCFLAGS) -o $@ $(COBJS) $(OBJCOBJS) -framework Cocoa

clean:
	rm -f $(COBJS) $(OBJCOBJS) CCA

$(COBJS): %.o: %.c
	clang -c $(CFLAGS) -o $@ $<

$(OBJCOBJS): %.o: %.m
	clang -c $(OBJCFLAGS) -o $@ $<

CCA.o: CCA.h
AppDelegate.o: AppDelegate.h MainView.h CCA.h
CCAView.o: CCA.h CCAView.h AppDelegate.h
MainView.o: MainView.h CCAView.h CCA.h
main.o: AppDelegate.h
