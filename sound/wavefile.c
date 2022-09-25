#include "wavefile.h"
#include <stdio.h>
#include <stdlib.h>

static uint32_t
u32(const unsigned char *p)
{
    uint32_t result = p[3];
    result <<= 8; result |= p[2];
    result <<= 8; result |= p[1];
    result <<= 8; result |= p[0];
    return result;
}

static uint16_t
u16(const unsigned char *p)
{
    return (((uint16_t)(p[1])) << 8) | p[0];
}

typedef struct chunk_s {
    uint32_t tag;
    uint32_t length;
    uint8_t *data;
} chunk_t;

int
read_chunk(chunk_t *chunk, FILE *f)
{
    uint8_t header[8];
    size_t i;
    if (!chunk) {
        return 0;
    }
    for (i = 0; i < 8; ++i) {
        int c = fgetc(f);
        if (c < 0) {
            return 0;
        }
        header[i] = (uint8_t)(c & 0xff);
    }
    chunk->tag = u32(header);
    chunk->length = u32(header+4);
    if (chunk->length > 0x1000000) {
        fprintf(stderr, "Chunk size %u exceeds 16MB\n", chunk->length);
        return 0;
    }
    chunk->data = malloc(chunk->length);
    if (!chunk->data) {
        fprintf(stderr, "Out of memory\n");
        return 0;
    }
    for (i = 0; i < chunk->length; ++i) {
        int c = fgetc(f);
        if (c < 0) {
            free(chunk->data);
            return 0;
        }
        chunk->data[i] = (uint8_t)(c & 0xff);
    }
    return 1;
}

int
wavefile_parse(wavefile_t *parsed, FILE *f)
{
    chunk_t chunk;
    uint8_t *data;
    int had_format = 0;
    uint32_t res_sz, wave_sz, index;
    if (!parsed) {
        return 0;
    }
    parsed->valid = 0;
    parsed->filemem = NULL;
    parsed->data = NULL;
    parsed->data_size = 0;
    if (!read_chunk(&chunk, f)) {
        fprintf(stderr, "Could not load wave file\n");
        return 0;
    }
    if (chunk.length < 4 ||
        chunk.tag       != 0x46464952 ||         /* 'RIFF' */
        u32(chunk.data) != 0x45564157) {         /* 'WAVE' */
        fprintf(stderr, "Not a wave file\n");
        return 0;
    }
    wave_sz = chunk.length;
    parsed->filemem = chunk.data;
    data = chunk.data;
    index = 4;
    while (index < wave_sz) {
        uint32_t tag = u32(data+index);
        uint32_t chunk_size = u32(data+index+4);
        index += 8;
        switch(tag) {
        case 0x20746d66:    /* 'fmt ' */
            if (had_format) {
                fprintf(stderr, "Wave file has multiple format chunks\n");
                return 0;
            }
            parsed->format = u16(data+index);
            parsed->channels = u16(data+index+2);
            parsed->sample_rate = u32(data+index+4);
            parsed->data_rate = u32(data+index+8);
            parsed->frame_size = u16(data+index+12);
            parsed->bits_per_sample = u16(data+index+14);
            had_format = 1;
            break;
        case 0x61746164:    /* 'data' */
            if (parsed->data) {
                fprintf(stderr, "Wave file has multiple data chunks\n");
                return 0;
            }
            parsed->data = data + index;
            parsed->data_size = chunk_size;
            break;
        default:
            break;
        }
        index += chunk_size;
        if (index & 1) ++index;
    }
    if (parsed->data == NULL) {
        fprintf(stderr, "Wave file had no data segment\n");
        return 0;
    }
    if (!had_format) {
        fprintf(stderr, "Wave file had no format segment\n");
        return 0;
    }
    if (parsed->format != 1 || parsed->channels != 1 ||
        parsed->sample_rate != 16000 || parsed->bits_per_sample != 8) {
        fprintf(stderr, "Wave data must be 16kHz mono 8-bit PCM\n");
        return 0;
    }
    parsed->valid = 1;
    return 1;
}
