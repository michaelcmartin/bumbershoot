# ZX81 Sample Programs

These programs are written in the assembler dialect used by [the z88dk toolkit](https://z88dk.org). This toolkit is runnable on a wide variety of platforms. (If you are running a Debianoid or a Fedora-based Linux distribution, they should be in your default repositories already.)

Assemble the programs with the command `z80asm -b -r4090 filename.asm` and then turn the binary into something runnable with the command `python zx81link.py filename.bin`. The `zx81link.py` script is presented here in this directory.

The resulting file will be named `filename.P` and should be loadable in any ZX81 emulator.

