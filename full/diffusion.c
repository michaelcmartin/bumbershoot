#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

unsigned char grid[33*33];

uint64_t rng_state;
uint64_t attempts;

uint32_t xorshift64star(void)
{
    uint64_t x = rng_state;
    x ^= x >> 12; 
    x ^= x << 25; 
    x ^= x >> 27; 
    rng_state = x;
    return (x * 0x2545F4914F6CDD1DLLU) >> 32;
}

void init_grid(void)
{
    int i, x, y;
    for (i = 0; i < 33; ++i) {
        grid[i] = grid[33*i] = grid[33*i+32] = grid[i+32*33] = 'X';
    }
    for (y = 1; y < 32; ++y) {
        int start = y*33 + 1;
        for (x = 0; x < 15; ++x) {
            grid[start+x] = '+';
            grid[start+16+x] = '*';
        }
        grid[start+15] = '.';
    }
}

void print_grid(void)
{
    int x, y, i;
    i = 0;
    for (y = 0; y < 33; ++y) {
        for (x = 0; x < 33; ++x) {
            fputc(grid[i++], stdout);
        }
        fputc('\n', stdout);
    }
}

double imbalance(void)
{
    int x, y;
    double total = 0.0;
    for (x = 0; x < 31; ++x) {
        int i = 34+x;
        int v = 0;
        for (y = 0; y < 31; ++y) {
            unsigned char c = grid[i];
            i += 33;
            if (c == '+') {
                ++v;
            }
            if (c == '*') {
                --v;
            }
        }
        if (v < 0) {
            v = -v;
        }
        total += v;
    }
    return total / 31;
}

void make_move() {
    static int offsets[4] = { -33, -1, 1, 33 };
    while (1) {
        unsigned long randval = xorshift64star();
        int index = (int)(randval / ((double)(0x100000000LLU) / (31*33))) + 33;
        int offset = offsets[(randval & 7) >> 1];
        ++attempts;
        if (index < 33 || index >= (32*33)) {
            fprintf(stderr, "Impossible grid move! %d (%lx)\n", index, randval);
            exit(1);
        }
        if (grid[index] != '+' && grid[index] != '*') {
            continue;
        }
        if (grid[index+offset] != '.') {
            continue;
        }
        grid[index+offset] = grid[index];
        grid[index] = '.';
        return;
    }
}

int main(int argc, char **argv)
{
    int i = 0;
    rng_state = time(NULL);
    attempts = 0;
    init_grid();
    printf("%5i    %7.3lf\n", 0, imbalance());
    while (i < 3000000) {
        make_move();
        ++i;
        if (i % 10000 == 0) {
            printf("%5i    %7.3lf\n", i / 1000, imbalance());
        }
    }
    /* 
    print_grid();
    printf("%d PRNG values consumed by time 50000000\n", attempts);
    */
    return 0;
}
    
