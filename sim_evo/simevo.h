/**********************************************************************
 *                       SIMULATED EVOLUTION
 *
 * A program by Michael C. Martin for Bumbershoot software, based on
 * Michael Palmiter's program of the same name, as described by A.K.
 * Dewdney in the May 1989 edition of his "Computer Recreations"
 * column in Scientific American, and as collected in his book "The
 * Magic Machine: a Handbook of Computer Sorcery".
 *
 * It is made available under the 2-Clause BSD License, reproduced
 * below.
 *
 * Copyright 2020 Michael C. Martin.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **********************************************************************/

#ifndef SIM_EVO_H_
#define SIM_EVO_H_

/**********************************************************************
 * Data structures
 **********************************************************************/

typedef struct bug_s {
    int name, gen, x, y, dir, time, fuel, gene[6];
} bug_t;

typedef struct evo_state_s {
    bug_t bugs[100];
    unsigned char plankton[15000];  /* 150 * 100 */
    int num_bugs, num_names, cycles;
} evo_state_t;

/**********************************************************************
 * Simulation functions. The UI/Harness must call these functions to
 * operate the simulation. It may then inspect the state structure to
 * determine the new state of the world as needed.
 **********************************************************************/

/* Initialize the state object. Your RNG should already be initialized
 * at this point, since this function will make use of it. */
void initialize(evo_state_t *state);

/* Run one cycle of the simulation. If bugs fission or die, the report
 * routines below will be called. */
int run_cycle(evo_state_t *state);

/* Provide the extra plankton to produce the "garden" scenario if
 * the harness wants to have it. */
int seed_garden(evo_state_t *state);

/**********************************************************************
 * Event functions. These functions are defined BY the UI/harness to
 * absorb information that isn't readily available from the evo_state_t
 * object.
 **********************************************************************/

/* Report a generic action on a bug in the state. bug_num is an index into
 * the bugs array. */
void report_bug(const evo_state_t *state, int bug_num, const char *action);

/* Report a pending fission event. At the time this is called, the parent
 * bug exists but the children do not. As such, these integers are *names*
 * and not usable indices into the array. Birth reports for the children
 * will follow from the simulation once they are created. At that point
 * the parent will no longer exist per se (it lives on as its children). */
void report_birth(const evo_state_t *state, int parent, int child_1, int child_2);

/**********************************************************************
 * Platform-specific rendering functions. Real-time application shells
 * will implement these to actually update the screen. Application
 * shells that rebuild the display every frame will leave these as
 * no-ops.
 **********************************************************************/

/* The start of a bug move. */
void erase_bug(int x, int y);

/* The end of a bug move. */
void draw_bug(int x, int y);

/* New plankton deposit. */
void draw_plankton(int x, int y);

/**********************************************************************
 * Platform-specific support functions. The simulation core relies on
 * the application shell to provide this functionality.
 **********************************************************************/

/* Deliver a random integer between 0 and n-1. Seeding the underlying
 * the RNG, if necessary, is the responsibility of the application
 * shell. */
unsigned long rand_int(unsigned long n);

#endif
