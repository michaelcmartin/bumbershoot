/**********************************************************************
 *           SIMULATED EVOLUTION: ATARI ST SUPPORT LIBRARY
 *
 * This header provides C bindings to the assembly-language routines
 * implemented in stevolib.asm.
 *
 * See simevost.c for more information about the Atari ST port, or
 * simevo.h for authorship, provenance, and copyright information.
 **********************************************************************/

#ifndef ST_EVO_LIB_H_
#define ST_EVO_LIB_H_

/* Initialize the graphics system. Call this once at program start. */
void init_line_a(void);

/* Set the fill pattern for fill_box. set_fill_pattern(NULL, 0) will
 * restore the default solid pattern. */
void set_fill_pattern(unsigned short *pattern, int length);

/* Draw a filled rectangle with the specified upper-left and
 * lower-right corners, in the specified color. */
void fill_box(short x1, short y1, short x2, short y2, short color);

/* Seed, or consult, the PRNG. The ST Evo Lib uses the same 64-bit
 * Xorshift-star PRNG that the modern Linux and Windows ports use. */
void seed_random(unsigned long seed);
unsigned long random(void);

/* User-mode function for number of ticks of the 200Hz system clock
 * since system start. */
unsigned long get_ticks(void);

#endif
