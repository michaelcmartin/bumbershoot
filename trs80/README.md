# TRS-80 Programs

The main directory here includes programs written for the TRS-80 Model III. They should be assembled with [Sjasm](https://github.com/Konamiman/Sjasm) and converted to runnable **`.CMD`** files with the **`bin2cmd`** program included here.

The **`coco`** subdirectory holds programs written for the TRS-80 Color Computer and its cousin systems the Dragon 32 and 64. That code should be assembled with the [asm6809 assembler](http://www.6809.org.uk/asm6809/) and packaged as a cassette image with the **`cococas`** program included there. Resource files for these programs may require other programs from this repository, but [the Ophis assembler](https://michaelcmartin.github.io/Ophis/) and [the `lz4` archiver](https://github.com/lz4/lz4) are both necessary for that.

The included Makefiles should manage the build process for both platforms, assuming the prerequisites are available.
