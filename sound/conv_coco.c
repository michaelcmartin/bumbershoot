#include <stdio.h>
#include <stdlib.h>
#include "wavefile.h"

int main(int argc, char **argv)
{
    FILE *f, *o;
    wavefile_t wave;
    uint32_t i;
    uint8_t *data;

    if (argc != 3) {
        fprintf(stderr, "Usage:\n\tconv_coco <infile.wav> <outfile.bin>\n");
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
    // TODO: Downsample to 4khz instead, leave as 8-bit
    for (i = 0; (i + 3) < wave.data_size; i += 4) {
        /* Downsample to 8kHz, 7-bit */
        int c = ((int)data[i] + (int)data[i+1] + (int)data[i+2] + (int)data[i+3]) >> 2;
        fputc(c, o);
    }
    if (wave.data_size % 4 != 0) {
        /* Extend the final byte in the last run */
        int v[4], j;
        for (j = 0; j < 4; ++j) {
            v[j] = data[wave.data_size - 1];
        }
        for (j = 0; (i + j < wave.data_size) && j < 4; ++j) {
            v[j] = (int)data[i];
        }
        fputc((v[0] + v[1] + v[2] + v[3]) >> 2, o);
    }
    fclose(o);
    free(wave.filemem);
    return 0;
}
