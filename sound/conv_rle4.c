#include <stdio.h>
#include <stdlib.h>
#include "wavefile.h"

int main(int argc, char **argv)
{
    FILE *f, *o;
    wavefile_t wave;
    uint32_t i;
    uint8_t *data;
    int histo[101];

    if (argc != 3) {
        fprintf(stderr, "Usage:\n\tconv_rle4 <infile.wav> <outfile.bin>\n");
        return 1;
    }
    f = fopen(argv[1],"rb");
    if (!f) {
        perror(argv[1]);
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
    for (i = 0; i < 101; ++i) histo[i] = 0;

    int current = 0;
    uint8_t target = 0;
    for (i = 0; i < wave.data_size; i += 2) {
        uint8_t c = data[i];
        uint8_t d = (i + 1 < wave.data_size) ? data[i+1] : c;
        int e = ((int)c + (int)d) >> 1;
        c = (e < 8) ? 0 : ((e - 8) >> 4);
        if (current == 0) {
            target = c;
            current = 1;
        } else if (c == target) {
            ++current;
            if (current > 15) {
                fputc(0xf0 | target, o);
                current -= 15;
            }
        } else {
            fputc((current << 4) | target, o);
            current = 1;
            target = c;
        }
    }
    if (current > 0) {
        fputc((current << 4) | target, o);
    }
    fputc(0, o);
    fclose(o);
    free(wave.filemem);
    return 0;
}
