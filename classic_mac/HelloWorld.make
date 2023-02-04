COptions	= -w 17 -proto strict -sym Full -D OLDROUTINELOCATIONS=0

helloObs	= HelloWorld.c.o

helloLibs	= "{Libraries}"Interface.o ∂
			  "{Libraries}"MacRuntime.o

HelloWorld	ƒƒ	{helloObs}
	Link -o {Targ} {helloObs} {helloLibs} -sym Full
	SetFile {Targ} -t APPL -c '????'
