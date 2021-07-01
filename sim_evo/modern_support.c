#include "simevo.h"
#include <stdint.h>

/* PRNG */
static uint64_t rng_state = 0x100000001LL;

void seed_rng(int64_t seed)
{
    rng_state = seed | 0x100000001LL;
}

static uint32_t rng(void)
{
    uint64_t x = rng_state;
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    rng_state = x;
    return (x * 0x2545F4914F6CDD1DLLU) >> 32;
}

unsigned long rand_int(unsigned long n)
{
    return rng() % n;
}

/* Modern platforms do not rely on the real-time screen update
 * routines. */
void erase_bug(int x, int y)
{
}

void draw_bug(int x, int y)
{
}

void draw_plankton(int x, int y)
{
}
