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
        fprintf(stderr, "Usage:\n\tconv_nes_pcm <infile.wav> <outfile.bin>\n");
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
    for (i = 0; (i + 1) < wave.data_size; i += 2) {
        /* Downsample to 8kHz, 7-bit */
        int c = ((int)data[i] + (int)data[i+1]) >> 2;
        fputc(c, o);
    }
    if (wave.data_size % 2 == 1) {
        /* Preserve the last byte as-is if there was one */
        fputc(data[wave.data_size - 1] >> 1, o);
    }
    fclose(o);
    free(wave.filemem);
    return 0;
}
