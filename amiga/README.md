# Special Notes for Amiga Programs

These programs are generally written for use with the [vbcc](http://sun.hasenbraten.de/vbcc/) and [vasm](http://sun.hasenbraten.de/vasm/) toolchains. See [my post at Bumbershoot Software](https://bumbershootsoft.wordpress.com/2022/06/06/cross-platform-development-for-the-amiga-500) for instructions on getting this toolchain up and running on Windows and Linux.

They have been written to not require the AmigaOS NDK; however, Hyperion Entertainment does provide [NDK 3.2 as a free download](https://www.hyperion-entertainment.com/index.php/downloads?view=details&file=126) and it is compatible with this toolchain, even when targeting the Amiga 500 or 1200.

With the exception of `IntuiTut`, all the programs in this directory can run as command-line from the AmigaDOS shell. Both `IntuiTut` and `Hamurabi` can run as Workbench applications, but they will need an appropriate info file to do so. `PNG2Icon` can produce them; it needs a stack size of at least 10KB to run properly, so run `STACK 16384` before invoking it.
