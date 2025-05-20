# ZX Spectrum Programs

ZX Spectrum programs should be assembled with [Sjasm](https://github.com/Konamiman/Sjasm) and linked with the **`spectralink.py`** program in this directory. An example build here is:

* **`sjasm lightsoutzx.asm lightsoutzx.bin`**
* **`./spectralink.py lightsoutzx.bin 7000`**

The **`7000`** passed to the linker should match the **`org`** directive at the top of the file.
