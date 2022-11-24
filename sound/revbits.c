#include <stdio.h>
#include <stdint.h>

int main(int argc, char **argv)
{
    FILE *f, *o;
    uint32_t i;
    uint8_t *data;

    if (argc != 3) {
        fprintf(stderr, "Usage:\n\trevbits <infile.bin> <outfile.bin>\n");
        return 1;
    }
    f = fopen(argv[1],"rb");
    if (!f) {
        perror(argv[i]);
        return 1;
    }
    o = fopen(argv[2],"wb");
    if (!o) {
        perror(argv[2]);
        fclose(f);
        return 1;
    }
    while (!feof(f)) {
        int c, r, i;
        c = fgetc(f);
        if (c < 0) {
            break;
        }
        r = 0;
        for (i = 0; i < 8; ++i) {
            r <<= 1;
            r |= c & 1;
            c >>= 1;
        }
        fputc(r, o);
    }
    fclose(o);
    fclose(f);
    return 0;
}
