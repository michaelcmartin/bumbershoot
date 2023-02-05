COptions	= -w 17 -proto strict -sym Full -D OLDROUTINELOCATIONS=0

helloObs	= HelloWorld.c.o

helloLibs	= "{Libraries}"Interface.o ∂
			  "{Libraries}"MacRuntime.o

HelloWorld	ƒƒ	{helloObs} HelloWorld.r HelloWorld.h
	Link -o {Targ} {helloObs} {helloLibs} -sym Full
	Rez -rd -append -o {Targ} HelloWorld.r
	SetFile {Targ} -t APPL -c 'BbHW' -a B
