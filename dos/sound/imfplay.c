/****************************************************************************
 * IMFPLAY.C - Play an IMF-format file (Commander Keen, Bio Menace, etc.)
 *
 * Copyright (c) 2017 Michael Martin. Distributed under the terms of the MIT
 * license; see LICENSE for details.
 *
 * This program is written to be compiled with Borland Turbo C 2.01 with the
 * Small memory model.
 ****************************************************************************/

#include <stdio.h>
#include <conio.h>

#include "adlib.h"
#include "pit.h"

#define byte unsigned char

/* This is the IMF data being played. Loading the music file will properly
 * initialize the music and music_size variables; the other two have their
 * correct initial values already. */
byte *music = NULL;              /* The raw IMF data */
unsigned int music_size = 0;     /* Number of bytes in the IMF file */
unsigned int music_index = 0;    /* Where in the file we are */
unsigned int music_timer = 1;    /* How many ticks left until next event */

/* This routine is called 560 times per second by the clock interrupt. */
void
imf_play(void)
{
    /* Advance timer one tick */
    --music_timer;
    /* Is it time to read the next command? */
    while (music_timer == 0) {
        /* IMF files are made of 4-byte blocks: register, value,
         * and a 16-bit number-of-ticks-to-next-block. */

        /* Step 1: Write the next value to the next register */
        adlib_write(music[music_index], music[music_index+1]);

        /* Step 2: update the timer to the time of the next block. THIS IS
         *         ALLOWED TO BE ZERO; that's why we've put all this in a
         *         while loop. If the value is zero, we'll just keep
         *         reading. */
        music_timer = music[music_index+2] | (music[music_index+3] << 8);

        /* Step 3: update the index into the music data. If we go past the
         *         end, wrap around to the beginning again. */
        music_index += 4;
        if (music_index >= music_size) {
            music_index = 0;
        }
    }
}

/* read_file: loads an entire (<64KB) file into memory.
 *
 *     filename: the file to load.
 *         size: pointer to write size of loaded file through. May be NULL.
 *
 *      RETURNS: contents of the file in a freshly-allocated memory block,
 *               or NULL if the file does not exist or is too large.
 */
void *
read_file (const char *filename, unsigned int *size)
{
    FILE *f;
    long fsize;
    char *buf;
    int i;

    /* Try to open the file */
    f = fopen(filename, "rb");

    if (!f) {
        /* File does not exist or cannot be opened */
        return NULL;
    }

    /* Find the size of the file */
    fseek(f, 0, SEEK_END);
    fsize = ftell(f);
    if (fsize > 0xffff) {
        /* File is too big */
        fclose(f);
        return NULL;
    }
    fseek(f, 0, SEEK_SET);

    /* Allocate the memory for the file's contents */
    buf = (char *)malloc(fsize);
    if (!buf) {
        /* Out of memory, most likely */
        fclose(f);
        return NULL;
    }

    /* Read in the file, 4KB at a time */
    i = 0;
    while (i < fsize) {
        int n = fread(buf+i, 1, 4096, f);
        if (n == 0) {
            break;
        }
        i += n;
    }

    /* Clean up */
    fclose(f);

    /* Write out the file size if the caller asked for it... */
    if (size) {
        *size = i;
    }

    /* ...and give the data back to the caller */
    return buf;
}

int
main(int argc, char **argv)
{
    /* Check for command line arguments and error out if it's wrong */
    if (argc != 2) {
        fprintf(stderr, "Usage: %s [IMF file]\n", argv[0]);
        return 1;
    }

    /* Load the file and error out if that fails */
    music = read_file(argv[1], &music_size);
    if (!music) {
        fprintf(stderr, "Could not load %s!\n", argv[1]);
        return 1;
    }

    /* Set up the soundcard and start calling our IMF_play routine 560 times
     * per second. */

    /* TODO: Blake Stone and the Wolfenstein games are actually at 700Hz, and
     *       Duke Nukem II is at 280Hz. We should have more sophisticated
     *       command line options to support that (the values aren't in the
     *       files themelves). */
    adlib_reset();
    PIT_configure(560, imf_play);

    /* Wait for the user to press a key. All the real work is happening in
     * in the IRQ0 processor. */
    printf ("Playing %s. Press any key to quit...\n", argv[1]);
    getch();

    /* Clean up our mess and get out */
    PIT_reset();
    free(music);
    adlib_reset();
    return 0;
}
