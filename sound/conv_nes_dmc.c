#include <stdio.h>
#include <stdlib.h>
#include "wavefile.h"

int dmc_cycles[16] = { 428, 380, 340, 320, 286, 254, 226, 214,
                       190, 160, 142, 128, 106, 84, 72, 54 };

#define NTSC_CLOCK 1789773
#define SAMPLE_RATE 8

void dmc_stats(void)
{
    int i;
    for (i = 0; i < 16; ++i) {
        printf("%2d. %3d => %8.2lf\n", i+1, dmc_cycles[i], (double)NTSC_CLOCK / dmc_cycles[i]);
    }
}

int main(int argc, char **argv)
{
    FILE *f, *o;
    wavefile_t wave;
    uint32_t i, bytes_written, bits_written;
    uint8_t *data, current, current_byte;
    double samples_per_bit, offset;

    if (argc != 3) {
        dmc_stats();
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
    current = 0x40;
    offset = 0.0;
    bytes_written = 0;
    bits_written = 0;
    current_byte = 0;
    samples_per_bit = (double)dmc_cycles[SAMPLE_RATE] * 16000.0 / NTSC_CLOCK;
    printf("Samples per bit: %.2lf\n", samples_per_bit);
    printf("Wave data size: %d\n", wave.data_size);
    while (offset < wave.data_size) {
        uint8_t target = data[(int)offset];
        current_byte >>= 1;
        if (target > current) {
            current_byte |= 0x80;
            if (current < 0x7e) {
                current += 2;
            } else if (current > 1) {
                current -= 2;
            }
        }
        bits_written += 1;
        offset += samples_per_bit;
        if (bits_written == 8) {
            fputc(current_byte, o);
            bits_written = 0;
            current_byte = 0;
            ++bytes_written;
        }
    }
    for (; bits_written < 8; ++bits_written) {
        current_byte >>= 1;
    }
    fputc(current_byte, o);
    ++bytes_written;
    while (bytes_written % 16 != 1) {
        fputc(0, o);
        ++bytes_written;
    }
    fclose(o);
    free(wave.filemem);
    return 0;
}
