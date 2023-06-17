#ifndef WAVEFILE_H_
#define WAVEFILE_H_

#include <stdio.h>
#include <stdint.h>

typedef struct wavefile_s {
    int valid;
    uint16_t format, channels;
    uint32_t sample_rate, data_rate;
    uint16_t frame_size, bits_per_sample;
    void *data, *filemem;
    uint32_t data_size;
} wavefile_t;

int wavefile_parse(wavefile_t *parsed, FILE *f);
int wavefile_parsebuf(wavefile_t *parsed, unsigned char *buf, unsigned int buf_len);
#endif
