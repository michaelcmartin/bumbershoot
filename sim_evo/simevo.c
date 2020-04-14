#include <stdint.h>
#include <stdio.h>
#include <sys/time.h>

typedef struct bug_s {
    int name, gen, x, y, dir, time, fuel, gene[6];
} bug_t;

const int xmove[6] = { 0, 2,  2,  0, -2, -2 };
const int ymove[6] = { 2, 1, -1 ,-2, -1,  1 };

bug_t bugs[100];
int plankton[15000];
int num_bugs, num_names, cycles;
int max_plankton = 0;

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
void report_bug(int i, const char *action)
{
    int j;
    printf("Time %5d: Bug %4d %s [", cycles, bugs[i].name, action);
    for (j = 0; j < 6; ++j) {
        if (j > 0) {
            printf(", ");
        }
        printf("%d", bugs[i].gene[j]);
    }
    printf("], new population %d\n", num_bugs);
}

/* The simulation itself */

void normalize_genes(int i)
{
    int j;
    int min = bugs[i].gene[0];
    for (j = 1; j < 6; ++j) {
        if (bugs[i].gene[j] < min) {
            min = bugs[i].gene[j];
        }
    }
    for (j = 0; j < 6; ++j) {
        bugs[i].gene[j] -= min;
        if (bugs[i].gene[j] > 13) {
            bugs[i].gene[j] = 13;
        }
    }
}

void initialize(void)
{
    int i;
    seed_rng();
    num_names = 0;
    num_bugs = 0;
    cycles = 0;
    /* Initialize bugs */
    for (i = 0; i < 10; ++i) {
        int j;
        bugs[i].name = num_names++;
        bugs[i].gen = 1;
        bugs[i].x = rng() % 148;
        bugs[i].y = rng() % 98;
        bugs[i].fuel = 40;
        bugs[i].time = 0;
        bugs[i].dir = rng() % 6;
        for (j = 0; j < 6; ++j) {
            bugs[i].gene[j] = rng() % 10;
        }
        normalize_genes(i);
        ++num_bugs;
        report_bug(i, "born");
    }
    /* Initialize plankton */
    for (i = 0; i < 15000; ++i) {
        plankton[i] = 0;
    }
    for (i = 0; i < 100; ++i) {
        plankton[rng() % 15000] = 1;
    }
}

int run_cycle(void)
{
    int i;
    for (i = 0; i < num_bugs; ++i) {
        int j, dx, dy, genesum, generoll;
        int x = bugs[i].x, y = bugs[i].y;

        /* Bug Eats */
        for (dx = 0; dx < 3; ++dx) {
            for (dy = 0; dy < 3; ++dy) {
                int index = x + dx + (y + dy) * 150;
                bugs[i].fuel += 40 * plankton[index];
                if (bugs[i].fuel > 1500) {
                    bugs[i].fuel = 1500;
                }
                plankton[index] = 0;
            }
        }

        /* Bug Moves */
        genesum = 0;
        for (j = 0; j < 6; ++j) {
            genesum += 1 << bugs[i].gene[j];
        }
        generoll = rng() % genesum;
        for (j = 0; j < 5; ++j) {
            int target = 1 << bugs[i].gene[j];
            if (generoll < target) {
                break;
            }
            generoll -= target;
        }
        /* At this point j is 0 to 5 and represents the turn the bug made.
           Rework it to be relative to the bug's current direction... */
        j += bugs[i].dir;
        j %= 6;
        bugs[i].dir = j;              /* Reset the direction... */
        bugs[i].x += xmove[j];        /* Make the move... */
        bugs[i].y += ymove[j];
        if (bugs[i].x < 0) {          /* Bounds-check to the left... */
            bugs[i].x = 0;
        }
        if (bugs[i].x > 147) {        /* ...right... */
            bugs[i].x = 147;
        }
        if (bugs[i].y < 0) {          /* ...top... */
            bugs[i].y = 0;
        }
        if (bugs[i].y > 97) {         /* ...and bottom. */
            bugs[i].y = 97;
        }

        /* Aging */
        --bugs[i].fuel;
        ++bugs[i].time;

        /* Reproduction and starvation */
        if (bugs[i].fuel <= 0) {
            --num_bugs;
            report_bug(i, "starved");
            if (num_bugs > 0) {
                bugs[i] = bugs[num_bugs];
                --i;
            }
        } else if (bugs[i].fuel >= 1000 && bugs[i].time >= 800 && num_bugs < 100) {
            printf("Time %5d: Bug %4d fissions into %d and %d\n", cycles, bugs[i].name, num_names, num_names+1);
            bugs[i].name = num_names++;
            bugs[i].fuel >>= 1;
            bugs[i].time = 0;
            ++bugs[i].gen;
            bugs[num_bugs] = bugs[i];
            bugs[num_bugs].name = num_names++;
            ++bugs[i].gene[rng() % 6];
            --bugs[num_bugs].gene[rng() % 6];
            normalize_genes(i);
            normalize_genes(num_bugs);
            ++num_bugs;
            report_bug(i, "born");
            report_bug(num_bugs-1, "born");
            --i; /* Reprocess first child */
        }
    }
    /* Replenish plankton */
    plankton[rng() % 15000] = 1;
    return 1;
}

/* Main program */

int main(int argc, char **argv)
{
    int i;
    initialize();
    for (i = 0; i < 1000000; ++i) {
        if (!run_cycle()) {
            break;
        }
        ++cycles;
    }
    if (num_bugs > 0) {
        int max = 0;
        for (i = 0; i < num_bugs; ++i) {
            if (bugs[i].gen > max) {
                max = bugs[i].gen;
            }
        }
        printf("Latest surviving generation is %d.\n", max);
    }
        
    return 0;
}
    
