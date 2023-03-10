# SIMULATED EVOLUTION

A program by Michael C. Martin for Bumbershoot software, based on Michael Palmiter's program of the same name, as described by A.K. Dewdney in the May 1989 edition of his "Computer Recreations" column in Scientific American, and as collected in his book "The Magic Machine: a Handbook of Computer Sorcery".

Editions are provided for a large number of platforms. Unlike the Lights-Out projects elsewhere in this repository, the goal of these editions is to share as much code as possible.

All versions are made available under the 2-Clause BSD License, reproduced below.

## Editions

* `SimEvo` and `SimEvoCLI` are intended to run on modern machines. `SimEvo` uses the SDL2 library to provide an animated display of the simulated world, while `SimEvoCLI` prints out a series of significant events to standard output over the course of a million simulated cycles. These programs were tested on gcc and clang, but are written in very portable C that should work on any system that understands a reasonable amount of C99.
* `SimEvoDX9.exe` is a Windows port that uses Direct3D 9 for rendering. It's built with MSYS2, but it should be trivial to get MSVS to compile it.
* `simevo.xex` and `simevo.atr` run on the Atari 800. The XEX file can run off of a DOS disk (or directly in emulators like Altirra that will boot into XEX files), and the ATR file is a self-booting disk image that will run even if only 16KB is available. They require the Ophis assembler to build.
* `simevo.prg` runs on the Commodore 64. It shares a large amount of code with the Atari 800 edition, and also requires the Ophis assembler.
* `simevo.tos` runs on the Atari ST. It shares the same core as the modern editions, but is built with the vbcc and vasm toolkits. The Atari-specific code requires that the compiler be used in a mode where `int` is only 16 bits wide.
* `AmiEvo` runs on the Commodore Amiga. Like the Atari ST version, it uses the modern core, and is built with the vbcc and vasm toolkits. Unlike the Atari code, `int` is presumed to be 32-bit. The Amiga NDK is not required to build this application.
* `simevo.com` cannot be built from the Makefile, but is instead built with Turbo C from inside a DOS environment. It shares the same core as the modern editions. Comments in the Makefile will provide build instructions. The resulting program should work on any PC (it only uses 32KB of RAM and a CGA-compatible video mode).

## License

Copyright 2020-2022 Michael C. Martin.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
