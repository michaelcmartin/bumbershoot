COptions	= -w 17 -proto strict -sym off -D OLDROUTINELOCATIONS=0

simEvoObs	= SimEvoMac.c.o SimEvo.c.o SimEvoUtil.a.o

sharedLibs	= "{Libraries}"Interface.o ∂
			  "{Libraries}"MacRuntime.o

SimEvo	ƒƒ	{simEvoObs} SimEvo.r
	Link -o {Targ} {simEvoObs} {sharedLibs} -sym off
	Rez -rd -append -o {Targ} SimEvo.r
	SetFile {Targ} -t APPL -c 'BbSE' -a B
