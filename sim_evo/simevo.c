#include <stdint.h>
#include <stdio.h>
#include <sys/time.h>

typedef struct bug_s {
    int name, gen, x, y, dir, time, fuel, gene[6];
} bug_t;

typedef struct evo_state_s {
    bug_t bugs[100];
    int plankton[15000];
    int num_bugs, num_names, cycles;
} evo_state_t;

const static int xmove[6] = { 0, 2,  2,  0, -2, -2 };
const static int ymove[6] = { 2, 1, -1 ,-2, -1,  1 };

/* PRNG */
uint64_t rng_state = 0x100000001LL;

void seed_rng(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    rng_state = ((uint64_t)tv.tv_sec * 1000000 + tv.tv_usec) | 0x100000001LL;
}

uint32_t rng(void)
{
    uint64_t x = rng_state;
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    rng_state = x;
    return (x * 0x2545F4914F6CDD1DLLU) >> 32;
}

/* Our window into the world */
void report_bug(evo_state_t *state, int i, const char *action)
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

/* The simulation itself */

void normalize_genes(bug_t *bug)
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
    seed_rng();
    state->num_names = 0;
    state->num_bugs = 0;
    state->cycles = 0;
    /* Initialize bugs */
    for (i = 0; i < 10; ++i) {
        int j;
        bug_t *bug = &state->bugs[i];
        bug->name = state->num_names++;
        bug->gen = 1;
        bug->x = rng() % 148;
        bug->y = rng() % 98;
        bug->fuel = 40;
        bug->time = 0;
        bug->dir = rng() % 6;
        for (j = 0; j < 6; ++j) {
            bug->gene[j] = rng() % 10;
        }
        normalize_genes(bug);
        ++state->num_bugs;
        report_bug(state, i, "born");
    }
    /* Initialize plankton */
    for (i = 0; i < 15000; ++i) {
        state->plankton[i] = 0;
    }
    for (i = 0; i < 100; ++i) {
        state->plankton[rng() % 15000] = 1;
    }
}

int run_cycle(evo_state_t *state)
{
    int i;
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
        genesum = 0;
        for (j = 0; j < 6; ++j) {
            genesum += 1 << bug->gene[j];
        }
        generoll = rng() % genesum;
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

        /* Aging */
        --bug->fuel;
        ++bug->time;

        /* Reproduction and starvation */
        if (bug->fuel <= 0) {
            --state->num_bugs;
            report_bug(state, i, "starved");
            if (state->num_bugs > 0) {
                state->bugs[i] = state->bugs[state->num_bugs];
                --i;
            }
        } else if (bug->fuel >= 1000 && bug->time >= 800 && state->num_bugs < 100) {
            bug_t *new_bug = &state->bugs[state->num_bugs];
            ++state->num_bugs;
            printf("Time %5d: Bug %4d fissions into %d and %d\n", state->cycles, bug->name, state->num_names, state->num_names+1);
            bug->name = state->num_names++;
            bug->fuel >>= 1;
            bug->time = 0;
            ++bug->gen;
            *new_bug = *bug;
            new_bug->name = state->num_names++;
            ++bug->gene[rng() % 6];
            --new_bug->gene[rng() % 6];
            normalize_genes(bug);
            normalize_genes(new_bug);
            report_bug(state, i, "born");
            report_bug(state, state->num_bugs-1, "born");
            --i; /* Reprocess first child */
        }
    }
    /* Replenish plankton */
    state->plankton[rng() % 15000] = 1;
    /* Advance time */
    ++state->cycles;
    return 1;
}

/* Main program */

int main(int argc, char **argv)
{
    int i;
    evo_state_t state;
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
    
