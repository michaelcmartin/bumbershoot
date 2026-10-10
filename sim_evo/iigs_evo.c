/**********************************************************************
 *              SIMULATED EVOLUTION: Apple IIgs HARNESS
 *
 * This runs the simulated evolution simulation until Escape is
 * pressed, providing an animation of the process as it evolves.
 *
 * It is written to use VBCC. Name the final file something like
 * SIMEVO#B30000 so that NAPS correctly marks it as an S16 file.
 *
 * See simevo.h for authorship, provenance, and copyright information.
 **********************************************************************/

#include <stdint.h>
#include <OS/MiscTool.h>

#include "simevo.h"

static evo_state_t state;

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

__far uint8_t * const shr_screen    = (__far uint8_t * const)0xe12000;
__far volatile uint8_t * const border_reg = (__far volatile uint8_t * const)0xe0c034;

static uint16_t palettes[4] = { 0x0000, 0x000a, 0x00a0, 0x0fff };
static uint8_t border_col;

void graphics_mode(void)
{
    __far uint16_t * const word_screen  = (__far uint16_t * const)shr_screen;
    __far uint16_t * const shr_palette  = (__far uint16_t * const)0xe19e00;
    for (int i = 0; i < 80; ++i) word_screen[i] = 0x1111;
    for (int i = 0; i < 5; ++i) shr_screen[i] = shr_screen[i+155] = 0;
    for (int i = 80; i < 16000; ++i) word_screen[i] = word_screen[i-80];
    for (int i = 16000; i < 16384; ++i) word_screen[i] = 0;
    for (int i = 0; i < 4; ++i) shr_palette[i] = palettes[i];

    *((volatile unsigned char *)0xe0c029) |= 0xc0;
    border_col = (*border_reg) & 0x0f;
    (*border_reg) &= 0xf0;
}

void text_mode(void)
{
    *((volatile unsigned char *)0xe0c029) &= 0x3f;
    *border_reg |= border_col;
}

/* Draw two pixels to the super high-res bitmap.
 * Valid values of (x, y) range from (0,0)-(159,99).
 * All values of c are valid, but each nybble should be 0-3 given the palette. */
static void pset(unsigned int x, unsigned int y, unsigned char c)
{
    /* offset is y * 320 + x + 5, but 65816 is bad at multiplication so we
     * do it with nested shifts */
    /* y * 320 = (y * 5) * 64 */
    unsigned int i = (((y << 2) + y) << 6) + x + 5;
    shr_screen[i] = c;
    shr_screen[i+160] = c;
}

/********** I/O support **********/

static int inkey(void)
{
    unsigned char c = *((__far volatile unsigned char *)0xe0c000);
    if (c < 0x80) return 0;
    /* acknowledge keystroke */
    unsigned char ignored = *((__far volatile unsigned char *)0xe0c010);
    return c & 0x7f;
}

/********** Main program **********/
int main()
{
    int garden = 1;       /* Start out in garden mode */
    graphics_mode();
    seed_rng(GetTick());  /* Init PRNG */
    initialize(&state);   /* Init simulation */

    while (1) {
        unsigned long start_time = GetTick();
        int c;
        run_cycle(&state);
        if (garden) {
            seed_garden(&state);
        }
        /* User input: toggle garden on 'g', quit on ESC */
        c = inkey();
        if (c) {
            if (c == 'g' || c == 'G') {
                garden = !garden;
            }
            if (c == 27) {
                break;
            }
        }
        /* Advance no faster than 60Hz. */
        while (GetTick() == start_time);
    }
    text_mode();
    return 0;
}

/**********************************************************************
 * Implementations of the routines used by the SimEvo core
 **********************************************************************/

/********** Event reports **********/
void report_bug(const evo_state_t *state, int bug_num, const char *action)
{
    /* Callback ignored */
}

void report_birth(const evo_state_t *state, int parent, int child_1, int child_2)
{
    /* Callback ignored */
}

/********** Draw callbacks **********/

void erase_bug(int x, int y)
{
    int dx, dy;
    for (dy = 0; dy < 3; ++dy) {
        for (dx = 0; dx < 3; ++dx) {
            pset(x+dx, y+dy, 0x11);
        }
    }
}

void draw_bug(int x, int y)
{
    int dx, dy;
    for (dy = 0; dy < 3; ++dy) {
        for (dx = 0; dx < 3; ++dx) {
            pset(x+dx, y+dy, 0x33);
        }
    }
}

void draw_plankton(int x, int y)
{
    pset(x, y, 0x22);
}

/********** RNG interface **********/

unsigned long rand_int(unsigned long n)
{
    /* Rely more on the high bits when deciding on a value. This
     * behavior tracks the 8-bit versions. */
    unsigned long v = rng();
    return (v * n) >> 16;
}
