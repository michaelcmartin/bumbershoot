/**********************************************************************
 *              SIMULATED EVOLUTION: UNIX CLI HARNESS
 *
 * This runs a million cycles of the simulation and outputs births
 * and deaths to standard output. It makes use of POSIX routines to
 * seed the random number generator and as such will only work on
 * sufficiently UNIX-like environments.
 *
 * See simevo.h for authorship. provenance, and copyright information.
 **********************************************************************/

#include <stdio.h>
#include <time.h>
#include "simevo.h"
#include "modern_support.h"

void report_bug(const evo_state_t *state, int i, const char *action)
{
    int j;
    printf("Time %5d: Bug %4d %s [", state->cycles, state->bugs[i].name, action);
    for (j = 0; j < 6; ++j) {
        if (j > 0) {
            printf(", ");
        }
        printf("%d", state->bugs[i].gene[j]);
    }
    printf("], new population %d\n", state->num_bugs);
}

void report_birth(const evo_state_t *state, int parent, int child_1, int child_2)
{
    printf("Time %5d: Bug %4d fissions into %d and %d\n", state->cycles, parent, child_1, child_2);
}

/* Main program */

int main(int argc, char **argv)
{
    int i;
    evo_state_t state;
    seed_rng(time(NULL));
    initialize(&state);
    for (i = 0; i < 1000000; ++i) {
        if (!run_cycle(&state)) {
            break;
        }
    }
    if (state.num_bugs > 0) {
        int max = 0;
        for (i = 0; i < state.num_bugs; ++i) {
            if (state.bugs[i].gen > max) {
                max = state.bugs[i].gen;
            }
        }
        printf("Latest surviving generation is %d.\n", max);
    }

    return 0;
}
