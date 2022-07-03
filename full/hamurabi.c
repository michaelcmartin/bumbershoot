/**********************************************************************
 * HAMURABI
 * A C port from David Ahl's "101 BASIC Computer Games" by
 * Michael Martin, 2022.
 **********************************************************************/
#include <ctype.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

/* The variables from the BASIC original. BASIC has no scope, so we
 * just declare these all as file-static */
static float p1;
static int d1, z, p, s, h, e, y, a, i, q, d, c;

/* A better random number generator than C usually ships with. The
 * rnd() function returns a random integer from 0 through range-1,
 * which doesn't exactly match BASIC but which will do what we
 * need. */
static uint64_t rng_state = 0x100000001L;

void seed_rnd(uint32_t seed)
{
    uint64_t full_seed = seed | 1;
    rng_state = full_seed | (full_seed << 32);
}

uint32_t xorshift64star(void)
{
    uint64_t x = rng_state;
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    rng_state = x;
    return (x * 0x2545F4914F6CDD1DLLU) >> 32;
}

int rnd(int range)
{
    return xorshift64star() % range;
}

/* Read a line of text from f. Store up to bufsiz bytes in buf along
 * the way. Lines that are too long are still consumed in their
 * entirety by the reader. */
void readline(FILE *f, char *buf, int bufsiz)
{
    if (fgets(buf, bufsiz, f)) {
        char *cursor = buf;
        while (*cursor) {
            if (*cursor == '\n') {
                /* We read a newline, we don't have to do any skipping */
                *cursor = 0;
                return;
            }
            ++cursor;
        }
        /* Line too long for buffer, read to eol, eof, or error */
        while (!feof(f) && !ferror(f) && fgetc(f) != '\n');        
    } else if (feof(f)) {
        printf("[EOF Detected]\n");
        exit(1);
    } else if (ferror(f)) {
        printf("[Error state detected]\n");
        exit(1);
    }
}

/* Read lines from stdin until the user enters a valid integer input. */
long readint(void)
{
    char buf[81];
    while (1) {
        char *end;
        long result;
        fflush(stdout);
        readline(stdin, buf, 81);
        result = strtol(buf, &end, 10);
        if (end != buf && (*end == 0 || isspace(*end))) {
            return result;
        }
        printf("[Please enter a whole number.]\n> ");
    }
}        

/* GOSUB 720 */    
void insufficient_acres(void)
{
    printf("Hamurabi: think again.  You only own %d acres.\nNow then, ", a);
}

/* GOSUB 710 */
void insufficient_grain(void)
{
    printf("Hamurabi: think again.  You have only\n%d bushels of grain.  Now then,\n", s);
}

/* GOSUB 800 */
void d5(void)
{
    c = rnd(5) + 1;
}

/* Most of GOTO 850, but the caller needs to stop playing afterwards.
 * This whole sequence is repeated through the game loop, and I'm pretty
 * sure that it exists so that the user can quit the game by entering
 * a negative number at any prompt */
void refuse(void)
{
    printf("\nHamurabi: I cannot do what you wish.\nGet yourself another steward!\n");
}

/* Original rating code is a bit tangled due to the early-removal arc,
 * so we end up mashing that logic up a bit */
void rating(int autofink)
{
    float l = 0.0f;
    if (!autofink) {
        l = a / p;
        printf("In your 10-year term of office, %.2f percent of the\n"
               "population starved per year on the average, i.e. a total of\n"
               "%d people died!!\n"
               "You started with 10 acres per person and ended with\n"
               "%.2f acres per person.\n", p1, d1, l);
    }
    if (autofink || p1 > 33 || l < 7.0f) {
        printf("Due to this extreme mismanagement you have not only been\n"
               "impeached and thrown out of office but you have\n"
               "also been declared national fink!!!!\n");
    } else if (p1 > 10 || l < 9.0f) {
        printf("Your heavy-handed performance smacks of Nero and Ivan IV.\n"
               "The people (remaining) find you an unpleasant ruler, and,\n"
               "frankly, hate your guts!!");
    } else if (p1 > 3 || l < 10.0f) {
        printf("Your performance could have been somewhat better, but\n"
               "really wasn't bad at all.  %d people\n"
               "would have dearly liked to have seen you assassinated but\n"
               "we all have our trivial problems.\n", rnd(p * 0.8));
    } else {
        printf("A fantastic performance!!!  Charlemagne, Disraeli, and\n"
               "Jefferson combined could not have done better!\n");
    }
}

/* The main game logic. Returning from this function is GOTO 990. */
void hamurabi_game(void)
{
    d1 = 0;
    p1 = 0.0f;
    z = 0;
    p = 95;
    s = 2800;
    h = 3000;
    e = h - s;
    y = 3;
    a = h/y;
    i = 5;
    q = 1;
    d = 0;
    while (1) {
        ++z;
        printf("\n\nHamurabi: I beg to report to you,\n"
               "in year %d, %d people starved, %d came to the city\n", z, d, i);
        p += i;
        if (q <= 0) {
            p /= 2;
            printf("A horrible plague struck!  Half the people died.\n");
        }
        printf("Population is now %d\n"
               "The city now owns %d acres.\n"
               "You harvested %d bushels per acre.\n"
               "Rats ate %d bushels.\n"
               "You now have %d bushels in store.\n", p, a, y, e, s);
        if (z == 11)
            break;
        c = rnd(10);
        y = c + 17;
        while (1) {
            printf("Land is trading at %d bushels per acre.\nHow many acres do you wish to buy? ", y);
            q = readint();
            if (q < 0) {
                refuse();
                return;
            }
            if (y * q <= s)
                break;
            insufficient_grain();
        }
        if (q == 0) {
            while (1) {
                printf("How many acres do you wish to sell? ");
                q = readint();
                if (q < 0) {
                    refuse();
                    return;
                }
                if (q < a) {
                    break;
                }
                insufficient_acres();
            }
            a -= q;
            s += y * q;
            c = 0;
        } else {
            a += q;
            s -= y * q;
            c = 0;
        }
        printf("\n");
        while (1) {
            printf("How many bushels do you wish to feed your people? ");
            q = readint();
            if (q < 0) {
                refuse();
                return;
            }
            /* Trying to use more grain than is in silos? */
            if (q <= s) {
                break;
            }
            insufficient_grain();
        }
        s -= q;
        c = 1;
        printf("\n");
        while (1) {
            printf("How many acres do you wish to plant with seed? ");
            d = readint();
            if (d == 0) {
                break;
            }
            if (d < 0) {
                refuse();
                return;
            }
            /* Trying to plant more acres than you own? */
            if (d > a) {
                insufficient_acres();
                continue;
            }
            /* Enough grain for seed? */
            if ((d / 2) > s) {
                insufficient_grain();
                continue;
            }
            /* Enough people to tend the crops? */
            if (d > 10*p) {
                printf("But you only have %d people to tend the fields!\nNow then, ", p);
                continue;
            }
            break;
        }
        s -= d / 2;
        d5();
        /* A bountiful harvest! */
        y = c;
        h = d * y;
        e = 0;
        d5();
        if ((c%2) == 0) {
            /* Rats are running wild! */
            e = s / c;
        }
        s = s - e + h;
        d5();
        /* Let's have some babies */
        i = (int)(c * (float)(20*a + s) / (float)p / 100.0f) + 1;
        /* How many people had full tummies? */
        c = q / 20;
        /* horror, a 15% chance of plague */
        q = rnd(20) - 3;
        if (p < c) {
            d = 0;
            continue;
        }
        /* Starve enough for impeachment? */
        d = p - c;
        if (d > .45 * p) {
            printf("You starved %d people in one year!!!\n", d);
            rating(1);
            return;
        }
        p1 = ((z-1) * p1 + d * 100.0f/p) / (float)z;
        p = c;
        d1 += d;
    }
    rating(0);
}

int main(int argc, char **argv)
{
    seed_rnd(time(NULL));
    printf("%32sHAMURABI\n%15sCreative Computing  Morristown, New Jersey\n\n\n\nTry your hand at governing ancient Sumeria\nfor a ten-year term of office.\n\n", " ", " ");
    hamurabi_game();
    /* Removed: making the console beep 10 times like a jerk */
    printf("\nSo long for now.\n\n");
    return 0;
}
