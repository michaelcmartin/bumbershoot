/**********************************************************************
 *              SIMULATED EVOLUTION: CORE IMPLEMENTATION
 *
 * This file contains the portable C code that implements the core
 * logic of the Simulated evolution program.
 *
 * See simevo.h for authorship. provenance, and copyright information.
 **********************************************************************/

#include "simevo.h"

static const int xmove[6] = { 0, 2,  2,  0, -2, -2 };
static const int ymove[6] = { 2, 1, -1 ,-2, -1,  1 };

/* The simulation itself */

static void normalize_genes(bug_t *bug)
{
    int j;
    int min = bug->gene[0];
    for (j = 1; j < 6; ++j) {
        if (bug->gene[j] < min) {
            min = bug->gene[j];
        }
    }
    for (j = 0; j < 6; ++j) {
        bug->gene[j] -= min;
        if (bug->gene[j] > 13) {
            bug->gene[j] = 13;
        }
    }
}

void initialize(evo_state_t *state)
{
    int i;
    state->num_names = 0;
    state->num_bugs = 0;
    state->cycles = 0;
    /* Initialize plankton */
    for (i = 0; i < 15000; ++i) {
        state->plankton[i] = 0;
    }
    for (i = 0; i < 100; ++i) {
        int n = rand_int(15000);
        state->plankton[n] = 1;
        draw_plankton(n % 150, n / 150);
    }
    /* Initialize bugs */
    for (i = 0; i < 10; ++i) {
        int j;
        bug_t *bug = &state->bugs[i];
        bug->name = state->num_names++;
        bug->gen = 1;
        bug->x = rand_int(148);
        bug->y = rand_int(98);
        bug->fuel = 40;
        bug->time = 0;
        bug->dir = rand_int(6);
        for (j = 0; j < 6; ++j) {
            bug->gene[j] = rand_int(10);
        }
        normalize_genes(bug);
        ++state->num_bugs;
        report_bug(state, i, "born");
        draw_bug(bug->x, bug->y);
    }
}

int run_cycle(evo_state_t *state)
{
    int i, n;
    for (i = 0; i < state->num_bugs; ++i) {
        int j, dx, dy, genesum, generoll;
        bug_t *bug = &state->bugs[i];
        int x = bug->x, y = bug->y;

        /* Bug Eats */
        for (dx = 0; dx < 3; ++dx) {
            for (dy = 0; dy < 3; ++dy) {
                int index = x + dx + (y + dy) * 150;
                bug->fuel += 40 * state->plankton[index];
                if (bug->fuel > 1500) {
                    bug->fuel = 1500;
                }
                state->plankton[index] = 0;
            }
        }

        /* Bug Moves */
        erase_bug(bug->x, bug->y);
        genesum = 0;
        for (j = 0; j < 6; ++j) {
            genesum += 1 << bug->gene[j];
        }
        generoll = rand_int(genesum);
        for (j = 0; j < 5; ++j) {
            int target = 1 << bug->gene[j];
            if (generoll < target) {
                break;
            }
            generoll -= target;
        }
        /* At this point j is 0 to 5 and represents the turn the bug made.
           Rework it to be relative to the bug's current direction... */
        j += bug->dir;
        j %= 6;
        bug->dir = j;              /* Reset the direction... */
        x += xmove[j];             /* Make the move... */
        y += ymove[j];
        if (x < 0) {               /* Bounds-check to the left... */
            x = 0;
        }
        if (x > 147) {             /* ...right... */
            x = 147;
        }
        if (y < 0) {               /* ...top... */
            y = 0;
        }
        if (y > 97) {              /* ...and bottom. */
            y = 97;
        }
        bug->x = x;                /* Finally store the new value back. */
        bug->y = y;
        draw_bug(x, y);

        /* Aging */
        --bug->fuel;
        ++bug->time;

        /* Reproduction and starvation */
        if (bug->fuel <= 0) {
            --state->num_bugs;
            report_bug(state, i, "starved");
            erase_bug(bug->x, bug->y);
            if (state->num_bugs > 0) {
                state->bugs[i] = state->bugs[state->num_bugs];
                --i;
            }
        } else if (bug->fuel >= 1000 && bug->time >= 800 && state->num_bugs < 100) {
            bug_t *new_bug = &state->bugs[state->num_bugs];
            ++state->num_bugs;
            report_birth(state, bug->name, state->num_names, state->num_names+1);
            bug->name = state->num_names++;
            bug->fuel >>= 1;
            bug->time = 0;
            ++bug->gen;
            *new_bug = *bug;
            new_bug->name = state->num_names++;
            ++bug->gene[rand_int(6)];
            --new_bug->gene[rand_int(6)];
            normalize_genes(bug);
            normalize_genes(new_bug);
            report_bug(state, i, "born");
            report_bug(state, state->num_bugs-1, "born");
            --i; /* Reprocess first child */
        }
    }
    /* Replenish plankton */
    n = rand_int(15000);
    state->plankton[n] = 1;
    draw_plankton(n % 150, n / 150);
    /* Advance time */
    ++state->cycles;
    return 1;
}

int seed_garden(evo_state_t *state)
{
    int x = rand_int(20)+40;
    int y = rand_int(20)+80;
    state->plankton[y*150+x] = 1;
    draw_plankton(x, y);
    return 1;
}
