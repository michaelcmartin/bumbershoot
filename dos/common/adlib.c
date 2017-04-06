#include "adlib.h"
#include <dos.h>

/* Not a whole lot going on here; the chip is reset by writing zero to
 * every register. */
void
adlib_reset(void)
{
    int i;
    for (i = 0; i < 256; ++i) {
        adlib_write(i, 0);
    }
}

/* Write the specified value to the specified register. */
void
adlib_write(unsigned char regnum, unsigned char val)
{
    int i;
    outportb(0x0388, regnum);
    /* We must wait 3 microseconds after writing the register to write the
     * data. But while CPUs got much faster, the I/O bus did not. We can
     * ensure that we've waited long enough by reading the Adlib's status
     * port six times. */
    for (i = 0; i < 6; ++i) {
        inportb(0x0388);
    }
    outportb(0x0389, val);
    /* Likewise, we must wait 20 microseconds before writing anything else
     * to the chip. 35 reads will grant us this. */
    for (i = 0; i < 35; ++i) {
        inportb(0x0388);
    }
}
