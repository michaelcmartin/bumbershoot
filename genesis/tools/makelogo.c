#include <stdint.h>
#include <stdio.h>

#define STB_IMAGE_IMPLEMENTATION
#define STBI_PNG_ONLY
#include "stb_image.h"

static uint16_t palette[32] = { 0, 0x222, 0x444, 0x666, 0x888, 0xAAA, 0xCCC, 0xEEE };
static unsigned char img[0x9000];
static unsigned char patterns[0x10000];
static unsigned int num_patterns = 0;
static uint16_t nametables[2][24][24];
static uint8_t bitfont[512], font[4096];

static int extract_palette(unsigned char *image, int w, int h)
{
    unsigned char colors = 8;
    unsigned char *dest = img;
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < h; ++x, image += 4) {
            int r = image[0];
            int g = image[1];
            int b = image[2];
            if ((r & 0x1f) || (g & 0x1f) || (b & 0x1f)) {
                fprintf(stderr, "Image palette too fine\n");
                return 0;
            }
            uint16_t c = (r >> 4) | g | (b << 4);
            unsigned char i;
            for (i = 0; i < colors; ++i) {
                if (c == palette[i]) break;
            }
            if (i == colors) {
                if (colors == 16) ++colors;
                if (colors == 32) {
                    fprintf(stderr, "Color depth too great\n");
                    return 0;
                }
                palette[colors++] = c;
            }
            *dest++ = i;
        }
    }
    return 1;
}

static int encode_font(void)
{
    int i, j, k, n, b, v;
    for (i = 0; i < 4096; ++i) {
        font[i] = 0;
    }
    i = 256; j = 0;
    for (n = 0; n < 64; ++n) {
        for (k = 0; k < 8; ++k) {
            v = bitfont[i];
            for (b = 0; b < 8; ++b) {
                if (v & 0x80) {
                    font[j] = (k != 3 && k != 4) ? 5 : 7;
                    if (b < 7 && k < 7) font[j+9] = 3;
                }
                v <<= 1;
                ++j;
            }
            ++i;
            if (i >= 512) i -= 512;
        }
    }
    i = 0x400;
    for (n = 0; n < 4096; n += 2) {
        patterns[i++] = (font[n] << 4) | (font[n+1]);
    }
}

static uint16_t find_tile(unsigned char *tile)
{
    int i, j;
    for (i = 0; i < num_patterns; ++i) {
        int c = i * 32;
        for (j = 0; j < 32; ++j) {
            if (tile[j] != patterns[c+j]) break;
        }
        if (j == 32) break;
    }
    if (i == num_patterns) {
        ++num_patterns;
        if (i == 32) {
            // Leave room for the font
            i += 64;
            num_patterns += 64;
        }
        int c = i * 32;
        for (j = 0; j < 32; ++j) {
            patterns[c+j] = tile[j];
        }
    }
    return i;
}

static void extract_image(void)
{
    unsigned char tilea[32], tileb[32];
    num_patterns = 0;
    for (int i = 0; i < 32; ++i) {
        tilea[i] = tileb[i] = 0;
    }
    find_tile(tilea);
    for (int cy = 0; cy < 24; ++cy) {
        for (int cx = 0; cx < 24; ++cx) {
            int i = ((cy * 192) + cx) * 8;
            int j = 0;
            for (int y = 0; y < 8; ++y) {
                for (int x = 0; x < 8; x += 2) {
                    int c0 = img[i + x];
                    int c1 = img[i + x + 1];
                    int ca0 = c0 > 15 ? 0 : c0;
                    int ca1 = c1 > 15 ? 0 : c1;
                    int cb0 = c0 > 15 ? c0 - 16 : 0;
                    int cb1 = c1 > 15 ? c1 - 16 : 0;
                    tilea[j] = (ca0 << 4) | ca1;
                    tileb[j] = (cb0 << 4) | cb1;
                    ++j;
                }
                i += 192;
            }
            nametables[0][cy][cx] = find_tile(tilea);
            nametables[1][cy][cx] = find_tile(tileb);
        }
    }
}

int main(int argc, char **argv)
{
    FILE *f;
    int w, h, n;
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <filename> [<fontname>]\n", argv[0]);
        return 1;
    }
    unsigned char *truecolor = stbi_load(argv[1], &w, &h, &n, 4);
    if (!truecolor) {
        fprintf(stderr, "Could not load %s\n", argv[1]);
        return 1;
    }
    if (w != 192 || h != 192) {
        fprintf(stderr, "Incorrect source image size\n");
        stbi_image_free(truecolor);
        return 1;
    }
    if (!extract_palette(truecolor, w, h)) {
        stbi_image_free(truecolor);
        return 1;
    }
    /*
    for (int i = 0; i < 32; ++i) {
        printf("%2d. %04X\n", i, palette[i]);
    }
    */
    extract_image();
    if (argc > 2) {
        f = fopen(argv[2], "rb");
        if (!f) {
            fprintf(stderr, "Could not open font file '%s', skipping font\n", argv[2]);
        } else {
            n = 0;
            while (n < 512 && !feof(f) && !ferror(f))
                n += fread(bitfont + n, 512-n, 1, f);
            fclose(f);
            encode_font();
        }
    }
    /*
    printf("\n%d total tiles.\n", num_patterns);
    for (int i = 0; i < num_patterns; ++i) {
        printf("%3d. ", i);
        for (int j = 0; j < 32; ++j) {
            printf("%02X",patterns[i*32+j]);
        }
        printf("\n");
    }
    for (int n = 0; n < 2; ++n) {
        printf("Nametable %d\n", n+1);
        for (int y = 0; y < 24; ++y) {
            for (int x = 0; x < 24; ++x) {
                printf("%03X ", nametables[n][y][x]);
            }
            printf("\n");
        }
    }
    */
    f = fopen("logoraw.bin","wb");
    for (int i = 0; i < 32; ++i) {
        fputc(palette[i] >> 8, f);
        fputc(palette[i] & 0xff, f);
    }
    printf("%5d bytes of palette info\n", 64);
    for (int i = 0; i < num_patterns * 32; ++i) {
        fputc(patterns[i], f);
    }
    printf("%5d bytes of pattern data\n", num_patterns * 32);
    int topmask = 0x80;
    int final_padding = 4864;
    for (int n = 0; n < 2; ++n) {
        for (int i = 0; i < 256; ++i) fputc(0, f);
        for (int y = 0; y < 24; ++y) {
            for (int i = 0; i < 8; ++i) { fputc(topmask, f); fputc(0, f); }
            for (int x = 0; x < 24; ++x) {
                fputc(topmask | (nametables[n][y][x] >> 8), f);
                fputc(nametables[n][y][x] & 0xff, f);
            }
            for (int i = 0; i < 32; ++i) { fputc(topmask, f); fputc(0, f); }
        }
        for (int i = 0; i < final_padding; ++i) fputc(0, f);
        topmask |= 0x20;
        final_padding = 768;
    }
    printf("%5d bytes of nametable data\n", 12288);
    fclose(f);

    stbi_image_free(truecolor);
    return 0;
}

