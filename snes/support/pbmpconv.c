#include <stdio.h>
#include <stdint.h>

#define STB_IMAGE_IMPLEMENTATION
#define STBI_PNG_ONLY
#include "stb_image.h"

uint8_t pixmap[32768];
uint16_t palette[256];
uint16_t cga[16] = {
    0x0000, 0x5400, 0x02a0, 0x56a0,
    0x0015, 0x5415, 0x0155, 0x56b5,
    0x294a, 0x7d4a, 0x2bea, 0x7fea,
    0x295f, 0x7d5f, 0x2bff, 0x7fff
};

void convert(uint8_t *dest, const unsigned char *img, int w, int h)
{
    int x, y, i;
    /* Preload initial palette to CGA equivalent */
    for (i = 0; i < 16; ++i) {
        palette[i] = cga[i];
    }
    for (i = 16; i < 256; ++i) {
        palette[i] = 0;
    }
    /* Clear image */
    for (i = 0; i < w*h; ++i) {
        dest[i] = 0;
    }
    for (y = 0; y < h; ++y) {
        int row = y * w;
        for (x = 0; x < w; ++x) {
            int i = (row + x) * 4;
            int r = img[i] >> 4;
            int g = img[i+1] >> 4;
            int b = img[i+2] >> 4;
            r = (r << 1) | ((r & 8) ? 1 : 0);
            g = (g << 1) | ((g & 8) ? 1 : 0);
            b = (b << 1) | ((b & 8) ? 1 : 0);
            int col = r + (g << 5) + (b << 10);
            if (col != 0) {
                /* Black stays black; everything else, we find it in
                 * the palette and add it if it's not there */
                for (i = 1; i < 256; ++i) {
                    if (palette[i] == 0) {
                        palette[i] = col;
                        break;
                    }
                    if (palette[i] == col) {
                        break;
                    }
                }
                if (i == 256) {
                    printf("Out of palette space!\n");
                    return;
                }
                if (i > 15) {
                    printf("Non-CGA color code: %04X\n", col);
                }
                dest[y * w + x] = i;
            }
        }
    }
}

int main(int argc, char **argv)
{
    int w, h, n;
    unsigned char *p;
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <in_filename> <out_filename>\n", argv[0]);
        return 1;
    }
    unsigned char *img = stbi_load(argv[1], &w, &h, &n, 4);
    if (!img) {
        fprintf(stderr, "Could not load %s\n", argv[1]);
        return 1;
    }
    printf("%s: %dx%d, %d channels\n", argv[1], w, h, n);
    if (w * h > 32768) {
        printf("Source image too large\n");
        stbi_image_free(img);
        return 1;
    }
    convert(pixmap, img, w, h);
    FILE *f = fopen(argv[2], "wb");
    if (f) {
        fwrite(pixmap, 1, w*h, f);
        fclose(f);
    }
    stbi_image_free(img);
    return 0;
}
