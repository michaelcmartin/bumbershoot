#include <stdio.h>
#include <stdlib.h>
#include "wavefile.h"

int main(int argc, char **argv)
{
    FILE *f, *o;
    wavefile_t wave;
    uint32_t i, prev;
    uint8_t *data;

    if (argc != 3) {
        fprintf(stderr, "Usage:\n\tconv_1bit <infile.wav> <outfile.bin>\n");
        return 1;
    }
    f = fopen(argv[1],"rb");
    if (!f) {
        perror(argv[i]);
        return 1;
    }
    wavefile_parse(&wave, f);
    fclose(f);
    if (!wave.valid) {
        if (wave.filemem) {
            free(wave.filemem);
        }
        return 1;
    }
    o = fopen(argv[2],"wb");
    if (!o) {
        perror(argv[2]);
        return 1;
    }
    data = wave.data;
    prev = 0;
    for (i = 0; i < wave.data_size; i += 8) {
        /* Convert unsigned 8-bit to packed 1-bit */
        uint32_t j, val;
        val = 0;
        for (j = 0; j < 8; ++j) {
            val <<= 1;
            if (i + j >= wave.data_size) continue;
            if (prev == 0 && data[i + j] >= 0x88) {
                prev = 1;
            } else if (data[i + j] <= 0x78) {
                prev = 0;
            }
            val |= prev;
        }
        fputc((int)val, o);
    }
    fclose(o);
    free(wave.filemem);
    return 0;
}
