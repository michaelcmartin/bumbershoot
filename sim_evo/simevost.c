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
#include "stevolib.h"
#include "simevo.h"

static evo_state_t state;

int main()
{
    int i, rez, garden;

    /* Force low resolution mode, or abort the whole program. */
    rez = Getrez();
    if (rez == 2) {
        Cconws("Oh no!\r\n\r\nSIMEVO requires a color monitor.\r\n\r\n"
               "Please press a key to quit: ");
        (void)Bconin(2);
        return 0;
    }
    Setscreen((void *)-1,(void *)-1,0);

    /* Initialize graphics system and draw the petri dish */
    init_line_a();
    fill_box(10,0,309,199,4); /* A box of solid blue */

    /* Initialize sim */
    seed_random(get_ticks());
    initialize(&state);
    garden = 0;

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

    /* Restore original screen resolution and exit */
    Setscreen((void *)-1,(void *)-1,rez);
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
    x <<= 1;
    x += 10;
    y <<= 1;
    fill_box(x,y,x+5,y+5,4);
}

void draw_bug(int x, int y)
{
    x <<= 1;
    x += 10;
    y <<= 1;
    fill_box(x,y,x+5,y+5,0);
}

void draw_plankton(int x, int y)
{
    x <<= 1;
    x += 10;
    y <<= 1;
    fill_box(x,y,x+1,y+1,2);
}

/********** RNG interface **********/

unsigned long rand_int(unsigned long n)
{
    return random() % n;
}
