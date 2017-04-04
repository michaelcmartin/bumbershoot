/*******************************************************************
 * CLOVER.C - Implements the famous "Smoking Clover" effect
 * (c) 2017 Michael Martin/Bumbershoot Software.
 * Published under the 2-clause BSD license.
 *
 * This implementation is written to Borland's Turbo C, and has
 * been actually tested on Turbo C 2.0.1. It uses no inline
 * assembly language and relies entirely on compiler intrinsics and
 * Borland's DOS and console extensions.
 *******************************************************************/

#include <conio.h>
#include <dos.h>
#include <math.h>
#include <string.h>

/* Select a graphics mode via the BIOS interrupt. */
void set_mode(unsigned char mode)
{
    union REGS regs;
    regs.x.ax = (unsigned int) mode;
    int86(0x10, &regs, &regs);
}

/* Simple implementation of Bresenham's algorithm from Paul Heckbert's
 * version in Graphics Gems. The plot routine is an increment operation. */
void line_inc(int x1, int y1, int x2, int y2)
{
    static char far *screen = (char far *)0xa0000000;
    int d, x, y, ax, ay, sx, sy, dx, dy;

    dx = x2-x1; ax = dx < 0 ? -dx : dx; sx = dx < 0 ? -1 : (dx > 0 ? 1 : 0);
    dy = y2-y1; ay = dy < 0 ? -dy : dy; sy = dy < 0 ? -1 : (dy > 0 ? 1 : 0);
    ax <<= 1; ay <<= 1;

    x = x1; y = y1;
    if (ax > ay) {                      /* x dominant */
        d = ay - (ax >> 1);
        for (;;) {
            if (x >= 0 && y >= 0 && x < 320 && y < 200) {
                ++screen[y*320+x];
            }
            if (x == x2) {
                return;
            }
            if (d >= 0) {
                y += sy;
                d -= ax;
            }
            x += sx;
            d += ay;
        }
    } else {                            /* y dominant */
        d = ax - (ay >> 1);
        for (;;) {
            if (x >= 0 && y >= 0 && x < 320 && y < 200) {
                ++screen[y*320+x];
            }
            if (y == y2) {
                return;
            }
            if (d >= 0) {
                x += sx;
                d -= ay;
            }
            y += sy;
            d += ax;
        }
    }
}

/* Draw the clover image itself by drawing a circle of radius r
 * converging on the center. We need to hit each pixel in the circle
 * exactly once, so we solve x^2+y^2=r^2 in the first octant and then
 * mirror the rest. */
void draw_display(int r)
{
    int x;
    double r2 = (double)r * (double)r;
    for (x = 0; x < r; ++x) {
        double x2 = (double)x * (double)x;
        int y = sqrt(r2-x2);
        if (y < x) break;
        line_inc(160, 100, 160+x, 100+y);
        line_inc(160, 100, 160+y, 100+x);
        line_inc(160, 100, 160-x, 100+y);
        line_inc(160, 100, 160-y, 100+x);
        line_inc(160, 100, 160+x, 100-y);
        line_inc(160, 100, 160+y, 100-x);
        line_inc(160, 100, 160-x, 100-y);
        line_inc(160, 100, 160-y, 100-x);
    }
}

/* Our palette sequence, with buffers for intro and overlaps */
unsigned char palette[2877];

/* Set up the palette. The first 256 entries are for the original
 * palette, which we will fade to black, and then the rest cycle
 * through our series of hues. That gets tedious very fast, so we use
 * some macros to make our life easier. */
#define SET_RED(block, val)     palette[((block)*64+i)*3]   = val
#define SET_GREEN(block, val)   palette[((block)*64+i)*3+1] = val
#define SET_BLUE(block, val)    palette[((block)*64+i)*3+2] = val

void init_palette(void)
{
    int i;
    /* Start with all zeros */
    memset(palette, 0, 2880);
    /* Then load the first 256 entries with the default palette */
    outportb(0x3c7, 0);
    for (i = 0; i < 768; ++i) {
        palette[i] = inportb(0x3c9);
    }
    /* Then create all of our gradients after that */
    for (i = 0; i < 64; ++i) {
        SET_RED(4, i);
        SET_RED(5, 63);
        SET_GREEN(5, i);
        SET_GREEN(6, 63);
        SET_RED(6, 63-i);
        SET_GREEN(7, 63);
        SET_BLUE(7, i);
        SET_BLUE(8, 63);
        SET_GREEN(8, 63-i);
        SET_BLUE(9, 63);
        SET_RED(9, i);
        SET_RED(10, 63);
        SET_BLUE(10, 63-i);
    }
    /* Finally copy the beginning of the sequence to the end, so that
     * we can smoothly loop. */
    memcpy(palette+2112, palette+960, 765);
}

/* Our periodic update routine. We start in fade mode and then move
 * into cycle mode. */

#define FADE_MODE  0
#define CYCLE_MODE 1

static int current_mode    = FADE_MODE;
static int current_counter = 0;

void clover_frame(void)
{
    int i, j;
    if (current_mode==FADE_MODE) {
        i = 0;
        for (j = 0; j < 768; ++j) {
            if (palette[j] > 0) {
                --palette[j];
            }
        }
        ++current_counter;
        if (current_counter >= 64) {
            current_mode = CYCLE_MODE;
            current_counter = 0;
        }
    } else {
        /* Cycle mode */
        i = current_counter;
        current_counter += 3;
        if (current_counter > 2109) {
            current_counter = 960;
        }
    }
    outportb(0x3c8, 0);
    for (j = 0; j < 768; ++j) {
        outportb(0x3c9, palette[i+j]);
    }
}

int main(int argc, char **argv)
{
    set_mode(0x13);                     /* 320x200x256 graphics */
    draw_display(1000);

    init_palette();

    while (!kbhit()) {
        clover_frame();
        delay(20);
    }

    while (kbhit()) getch();            /* Consume key */
    set_mode(0x03);                     /* 80x25 color text */

    (void) argc;
    (void) argv;
    return 0;
}

