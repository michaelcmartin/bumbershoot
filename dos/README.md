# DOS programs from Bumbershoot Software

This directory and its subdirectories include various DOS projects explored on the Bumbershoot Software blog.

All assembly-language source code is designed to be built with [the Netwide Assembler](http://nasm.us). Code that includes the directive `org 100h` or similar should be assembled into a `.com` file with the `-f bin` option; otherwise they should be assembled into `.obj` files with the `-f obj` option.

The C and Pascal projects are written to use Turbo C 2.01 and Turbo Pascal 5.5, respectively. The build scripts assume that these tools are present in your path.

If you have cloned this repository on a Unix or Mac system, it may be necessary to convert the line endings of the `.c` and `.h` files to DOS format before the Borland tools will accept them.