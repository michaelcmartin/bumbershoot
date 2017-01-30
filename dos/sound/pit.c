#include "pit.h"
#include <dos.h>
#include <stdlib.h>

/* our_tick: a custom IRQ0 routine that manages both the caller-supplied
 *           callbacks and the BIOS's own clock handler. */
static void interrupt our_tick(void);

/* The location of the BIOS clock handler */
static void interrupt (*bios_tick)(void) = NULL;

/* The current user-supplied callback function. */
static PIT_callback_t timer_callback = NULL;

/* How many microseconds have passed since the last BIOS clock call */
static unsigned long subtick = 0;

/* How many microseconds are advanced each time IRQ0 actually happens */
static unsigned int counter_unit = 0;

/* Sets up a user-supplied callback at a specified speed. */
void
PIT_configure(int hz, PIT_callback_t cb)
{
    /* How many PIT ticks to get the specified speed? The PIT itself runs
     * at 0x1234CD Hz, so... */
    long counter = 0x1234CD / hz;

    /* PIT mode 3 is cleaner if the low bit of the counter is 0 */
    counter &= ~1;

    /* Save and rewrite the BIOS tick routine, if necessary */
    if (!bios_tick) {
        bios_tick = getvect(8);
        setvect(8, our_tick);
    }

    /* Disable interrupts to make sure we aren't interrupted while
     * configuring the clock */
    disable();

    /* Reprogram the PIT */
    outportb(0x43, 0x36);
    outportb(0x40, counter & 0xff);
    outportb(0x40, (counter >> 8) & 0xff);

    /* Record the callback and timing information */
    counter_unit = counter & 0xffff;
    timer_callback = cb;

    /* Re-enable interrupts. */
    enable();
}

void
PIT_reset(void)
{
    /* Restore BIOS defaults for the PIT timer 0, and null out all the user-
     * supplied information */
    disable();
    outportb(0x43, 0x36);
    outportb(0x40, 0x00);
    outportb(0x40, 0x00);
    counter_unit = 0;
    subtick = 0;
    timer_callback = NULL;
    enable();

    /* Point IRQ0 back to the original routine in BIOS.
     * Can't setvect with interrupts disabled, but if IRQ0 hits along the way,
     * timer_callback is already NULL so the our_tick code will just forward
     * it to BIOS */
    if (bios_tick) {
        setvect(8, bios_tick);
        bios_tick = NULL;
    }
}

/* This is our custom IRQ0 routine. */
static void interrupt
our_tick(void)
{
    /* "ticked" records whether we forwarded to BIOS or not this run */
    int ticked = 0;

    /* Call the user callback, if any */
    if (timer_callback) {
        timer_callback();
    }

    /* Advance the PIT's cycle counter. */
    subtick += counter_unit;
    if (subtick > 0xffff) {
        /* We've rolled over its 16-bit value. BIOS needs to see this. */
        subtick -= 0x10000;
        if (bios_tick) {
            /* bios_tick should never be NULL if we got here, but better
             * safe than sorry */
            bios_tick();
            ticked = 1;
        }
    }

    /* If we *didn't* forward to BIOS, we have to acknowledge the interrupt
     * ourselves, by writing 0x20 to port 0x20. */
    if (!ticked) {
        outportb(0x20, 0x20);
    }
}
