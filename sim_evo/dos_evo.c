/**********************************************************************
 *                 SIMULATED EVOLUTION: DOS HARNESS
 *
 * This runs the simulated evolution simulation until Escape is
 * pressed, providing an animation of the process as it evolves.
 *
 * It is written to use Borland Turbo C, and should work in any memory
 * model. (The shipped binary uses Tiny to ship it as a .COM file.)
 *
 * The total memory footprint is about 30KB, and it only uses CGA
 * graphics, so it should run on any computer capable of running DOS
 * at all, even an original 64KB PC.
 *
 * See simevo.h for authorship, provenance, and copyright information.
 **********************************************************************/

#include <conio.h>
#include <dos.h>

#include "pit.h"
#include "simevo.h"

static evo_state_t state;

/********** Rate Limiter **********/

static volatile unsigned int clocks = 0;

void clock_step(void)
{
    ++clocks;
}

/********** PRNG **********/

/* This is the Xorshift PRNG the 8-bit versions also use. */

static unsigned short rng_x = 1;
static unsigned short rng_y = 1;

static void seed_rng(unsigned long seed)
{
    rng_x = (unsigned short)seed;
    rng_y = (unsigned short)(seed >> 16);
    rng_x |= 1;
    rng_y |= 1;
}

static unsigned short rng(void)
{
    unsigned short t = (rng_x ^ (rng_x << 5));
    rng_x = rng_y;
    return rng_y = (rng_y ^ (rng_y >> 1)) ^ (t ^ (t >> 3));
}

/********** Graphics support **********/

/* Set screen mode */
static void screen_mode(unsigned int mode)
{
    union REGS regs;
    regs.x.ax = mode;
    int86(0x10, &regs, &regs);
}

/* Draw a double-sized pixel to the Mode 5 (320x200x4 CGA) bitmap.
 * Valid values of (x, y) range from (0,0)-(159,99).
 * Valid values of c range from 0-3. */
static void pset(int x, int y, unsigned char c)
{
    /* Pointer to the bitmap base */
    static unsigned char far * const screen = (unsigned char far * const) 0xb8000000;
    unsigned int offset;
    unsigned char erase_mask, val;
    /* The bitmap is a bit inconveniently laid-out, but we get to make
     * some simplifying assumptions thanks to being double-size: we
     * get to write a nybble at a time, and we can simply make the
     * even and odd scanlines mirror each other instead of worrying
     * about how best to toggle between them. */
    c |= c << 2;
    if (x & 1) {
        erase_mask = 0xf0;
    } else {
        erase_mask = 0x0f;
        c <<= 4;
    }
    offset = y * 80 + (x >> 1);
    val = (screen[offset] & erase_mask) | c;
    screen[offset] = val;        /* Draw to the even-scanline field */
    screen[offset+0x2000] = val; /* Draw to the odd-scanline field */
}

/********** System timer **********/

/* Return the number of (18.2Hz) clock ticks since midnight. We use
 * this value to seed the PRNG. */
static unsigned long systicks(void)
{
    union REGS regs;
    regs.h.ah = 0;
    int86(0x1A, &regs, &regs);
    return (((unsigned long)regs.x.cx)) << 16 | regs.x.dx;
}

/********** Main program **********/
int main()
{
    int garden = 0;       /* Start out of garden mode */
    screen_mode(5);       /* Set 320x200x4 CGA graphics mode */
    seed_rng(systicks()); /* Init PRNG */
    initialize(&state);   /* Init simulation */
    PIT_configure(50, clock_step);  /* Init timer */
    while (1) {
        unsigned int start_time = clocks;
        run_cycle(&state);
        if (garden) {
            seed_garden(&state);
        }
        /* User input: toggle garden on 'g', quit on ESC */
        if (kbhit()) {
            char c = getch();
            if (c == 'g' || c == 'G') {
                garden = !garden;
            }
            if (c == 27) {
                break;
            }
        }
        /* Advance no faster than 50Hz. */
        while (clocks == start_time);
    }
    PIT_reset();          /* Turn off the timer */
    screen_mode(3);       /* Back to 80-column text mode */
    return 0;
}

/**********************************************************************
 * Implementations of the routines used by the SimEvo core
 **********************************************************************/

/********** Event reports **********/
void report_bug(const evo_state_t *state, int bug_num, const char *action)
{
    /* Callback ignored */
    (void)state;
    (void)bug_num;
    (void)action;
}

void report_birth(const evo_state_t *state, int parent, int child_1, int child_2)
{
    /* Callback ignored */
    (void)state;
    (void)parent;
    (void)child_1;
    (void)child_2;
}

/********** Draw callbacks **********/

void erase_bug(int x, int y)
{
    int dx, dy;
    x += 5;
    for (dy = 0; dy < 3; ++dy) {
        for (dx = 0; dx < 3; ++dx) {
            pset(x+dx, y+dy, 0);
        }
    }
}

void draw_bug(int x, int y)
{
    int dx, dy;
    x += 5;
    for (dy = 0; dy < 3; ++dy) {
        for (dx = 0; dx < 3; ++dx) {
            pset(x+dx, y+dy, 3);
        }
    }
}

void draw_plankton(int x, int y)
{
    pset(x+5, y, 1);
}

/********** RNG interface **********/

unsigned long rand_int(unsigned long n)
{
    /* Rely more on the high bits when deciding on a value. This
     * behavior tracks the 8-bit versions. */
    unsigned long v = rng();
    return (v * n) >> 16;
}
