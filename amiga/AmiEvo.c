#include <stdlib.h>
#include <stdint.h>
#include "simevo.h"

static evo_state_t state;

extern intptr_t init_gui(void);
extern uint32_t poll_gui(void);
extern void close_gui(void);

extern void seed_random(uint32_t seed);
extern uint32_t random(void);
extern uint32_t timer_seed(void);

int garden;

unsigned long rand_int(unsigned long n)
{
    return random() % n;
}

void toggle_garden(void)
{
    garden = 1 - garden;
}

int main()
{
    if (!init_gui()) {
        return 1;
    }

    /* Initialize sim */
    seed_random(timer_seed());
    initialize(&state);
    garden = 1;

    do {
        run_cycle(&state);
        if (garden) {
            seed_garden(&state);
        }
    } while (poll_gui());
    close_gui();
    return 0;
}
