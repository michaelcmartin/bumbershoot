/**********************************************************************
 *               SIMULATED EVOLUTION: ATARI ST HARNESS
 *
 * This runs the simulated evolution simulation until Escape is
 * pressed, providing an animation of the process as it evolves.
 *
 * It is written to use the vbcc/vasm/vlink toolchain, and it must be
 * compiled using a mode that uses 16-bit integers (vbccm68ks, the
 * vc16 library, etc). The assembly-language support library ST Evo
 * Lib (stevolib.asm) will also need to be linked into the final
 * binary.
 *
 * This program runs in low-resolution mode, so a color monitor is
 * required.
 *
 * See simevo.h for authorship, provenance, and copyright information.
 **********************************************************************/

#include <tos.h>
#include <stdlib.h>
#include "stevolib.h"
#include "simevo.h"

static evo_state_t state;
static unsigned short checkerboard[2] = { 0xAAAA, 0x5555 };

static unsigned short erase_bug_color = 4;     /* Blue */
static unsigned short draw_bug_color = 0;      /* White */
static unsigned short draw_plankton_color = 2; /* Green */
static unsigned short *plankton_pattern = NULL;
static int plankton_pattern_length = 0;
static int x_shift = 1, y_shift = 1, x_offset = 10;
static short bug_side = 5, plankton_side = 1;

int main()
{
    int i, rez, garden;

    /* Reconfigure drawing rules for high resolution if needed,
     * otherwise force low resolution mode. */
    rez = Getrez();
    if (rez == 2) {
        erase_bug_color = 1;    /* Black */
        draw_bug_color = 0;     /* White */
        draw_plankton_color = 1;
        plankton_pattern = checkerboard;
        plankton_pattern_length = 2;
        x_shift = y_shift = 2;
        x_offset = 20;
        bug_side = 11;
        plankton_side = 3;
        Cconws("\033f"); /* Turn cursor off */
    } else {
        Setscreen((void *)-1,(void *)-1,0);
    }

    /* Initialize graphics system and draw the petri dish */
    init_line_a();
    fill_box(x_offset,
             0,
             x_offset + (150 << x_shift) - 1,
             (100 << y_shift) - 1,
             erase_bug_color);

    /* Initialize sim */
    seed_random(get_ticks());
    initialize(&state);
    garden = 1;

    while (1) {
        unsigned long start_time = get_ticks();
        run_cycle(&state);
        if (garden) {
            seed_garden(&state);
        }
        /* User input: toggle garden on 'g', quit on ESC */
        if (Bconstat(2)) {
            int c = Bconin(2) & 0xFF;
            if (c == 'G' || c == 'g') {
                garden = !garden;
            }
            if (c == 0x1b) {
                break;
            }
        }
        /* Maximum update speed 50Hz */
        while ((get_ticks() - start_time) < 4);
    }

    /* Restore original screen resolution if necessary and exit */
    if (rez == 2) {
        Cconws("\033e"); /* Restore cursor */
    } else {
        Setscreen((void *)-1,(void *)-1,rez);
    }
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
    x <<= x_shift;
    x += x_offset;
    y <<= y_shift;
    fill_box(x,y,x+bug_side,y+bug_side,erase_bug_color);
}

void draw_bug(int x, int y)
{
    x <<= x_shift;
    x += x_offset;
    y <<= y_shift;
    fill_box(x,y,x+bug_side,y+bug_side,draw_bug_color);
}

void draw_plankton(int x, int y)
{
    x <<= x_shift;
    x += x_offset;
    y <<= y_shift;
    set_fill_pattern(plankton_pattern, plankton_pattern_length);
    fill_box(x,y,x+plankton_side,y+plankton_side,draw_plankton_color);
    set_fill_pattern(NULL, 0);
}

/********** RNG interface **********/

unsigned long rand_int(unsigned long n)
{
    return random() % n;
}
