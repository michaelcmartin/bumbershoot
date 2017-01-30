/*
 * PIT.H - Configure the Programmable Interval Timer. These routines are
 *         intended to trigger a periodic callback with near-microsecond
 *         precision. This hooks IRQ0, so only only callback may be used
 *         at a time. BIOS clock ticks will continue to happen at roughly
 *         the same times as usual.
 */

#ifndef PIT_H_
#define PIT_H_

/* Type alias for the kinds of callbacks you can set. These are ordinary C
 * functions that take no arguments and return nothing. Note that they will
 * be running with interrupts disabled, so don't try anything *too* crazy
 * in them. */
typedef void (*PIT_callback_t)(void);

/* Set up a periodic callback. The {callback} function will be called {hz}
 * times per second. hz should be at least 19 and at most, well, that
 * depends on how small your function is. More than 50,000 is probably a
 * bad idea. */
void PIT_configure(int hz, PIT_callback_t callback);

/* Restore the ordinary behavior of IRQ0. YOU *MUST* CALL THIS FUNCTION
 * BEFORE YOUR PROGRAM EXITS IF YOU EVER CALLED PIT_configure. It is safe
 * to call it without having called PIT_configure, so just call it on the
 * way out. */
void PIT_reset(void);

#endif
