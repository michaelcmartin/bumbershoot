COptions	= -w 17 -proto strict -sym off -D OLDROUTINELOCATIONS=0

fileTestObs	= FileTest.c.o XorShift.a.o
fileTestLLObs   = FileTestLL.c.o XorShift.a.o
fileTestAsmObs  = FileTestRaw.a.o XorShift.a.o

sharedLibs	= "{Libraries}"Interface.o ∂
		  "{Libraries}"MacRuntime.o

all	ƒƒ	FileTest FileTestLL FileTestAsm

FileTest	ƒƒ	{fileTestObs}
	Link -o {Targ} {fileTestObs} {sharedLibs} -sym off
	SetFile {Targ} -t APPL -c '????'

FileTestLL	ƒƒ	{fileTestLLObs}
	Link -o {Targ} {fileTestLLObs} {sharedLibs} -sym off
	SetFile {Targ} -t APPL -c '????'

FileTestAsm	ƒƒ	{fileTestAsmObs}
	Link -o {Targ} {fileTestAsmObs} -sym off
	SetFile {Targ} -t APPL -c '????'
