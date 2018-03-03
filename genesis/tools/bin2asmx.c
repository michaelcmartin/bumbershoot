#include <stdio.h>

int main(int argc, char **argv)
{
    FILE *f;
    int i;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s [filename]\n", argv[0]);
        return 1;
    }

    f = fopen(argv[1], "rb");
    if (!f) {
        fprintf(stderr, "Could not open %s\n", argv[1]);
        return 1;
    }

    i = 0;
    while (1) {
        int c = fgetc(f);
        if (c < 0) {
            break;
        }
        if (!(i & 15)) {
            if (i) {
                printf("\n");
            }
            printf("        HEX    ");
        }
        printf(" %02X", c);
        ++i;
    }
    if (i != 0) {
        printf("\n");
    }

    fclose(f);
    return 0;
}
