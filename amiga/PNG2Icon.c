#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "LibIcon.h"

#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
#include "../win32/stb_image.h"

extern uint32_t __stackPtr, __stackLower;  /* Defined by vbcc startup.o */

void usage(void)
{
    printf("Usage:\n"
           "    PNG2Icon [options] <dest> <src.png> [<selected.png>]\n"
           "\nOptions:\n"
           "    -h, --help             Display this message\n"
           "    -s <n>, --stack <n>    Specify stack size of <n>\n"
           "\n\nThis program requires at least 10KB of DOS stack to run.\n");
}

int sanity_check(const char *path1, const char *path2, int *w, int *h)
{
    int w1, h1, w2, h2, n;
    if (!stbi_info(path1, &w1, &h1, &n)) {
        printf("%s: %s\n", path1, stbi_failure_reason());
        return 0;
    }
    if (w) *w = w1;
    if (h) *h = h1;
    if (!path2) {
        return 1;
    }
    if (!stbi_info(path2, &w2, &h2, &n)) {
        printf("%s: %s\n", path2, stbi_failure_reason());
        return 0;
    }
    if (w1 != w2 || h1 != h2) {
        printf("%s (%dx%d) and %s (%dx%d) are different sizes\n", path1, w1, h1, path2, w2, h2);
        return 0;
    }
    return 1;
}

uint16_t *convert(const char *path)
{
    int w, h, n, row_size;
    uint8_t *elt, *grid = stbi_load(path, &w, &h, &n, 4);
    uint16_t *result, *plane0, *plane1;
    if (!grid) {
        printf("%s: %s\n", path, stbi_failure_reason());
        return NULL;
    }
    row_size = (w + 15) >> 4;       /* Number of machine words per row */
    result = malloc(row_size * h * 2 * sizeof(uint16_t));
    if (!result) {
        printf("%s: Out of memory\n", path);
        return NULL;
    }

    plane0 = result;
    plane1 = result + (row_size * h);
    elt = grid;
    for (int y = 0; y < h; ++y) {
        for (int i = 0; i < row_size; ++i) {
            int x = 0;
            uint16_t p1 = 0, p2 = 0;
            for (int bit = 0; bit < 16; ++bit) {
                int pixel = 0;
                if (x < w) {
                    uint8_t r = *elt++;
                    uint8_t g = *elt++;
                    uint8_t b = *elt++;
                    uint8_t a = *elt++;
                    ++x;
                    if (a < 128) {
                        pixel = 0;
                    } else if (r > 0xef && g > 0xef && b > 0xef) {
                        pixel = 1;
                    } else if (r < 16 && g < 16 && b < 16) {
                        pixel = 2;
                    } else {
                        pixel = 3;
                    }
                }
                p1 = (p1 << 1) | (pixel & 1);
                p2 = (p2 << 1) | ((pixel >> 1) & 1);
            }
            *plane0++ = p1;
            *plane1++ = p2;
        }
    }
    stbi_image_free(grid);
    return result;
}

int main (int argc, char **argv)
{
    const char *dest_path = NULL, *img1_path = NULL, *img2_path = NULL;
    uint16_t *img1_dat = NULL, *img2_dat = NULL;
    int width, height;
    long stack = 4096;
    uint32_t stackSize = __stackPtr-__stackLower + 24;

    /***** Parse command line options *****/
    for (int i = 1; i < argc; ++i) {
        /* Check for options first */
        if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
            usage();
            return 0;
        }
        if (!strcmp(argv[i], "-s") || !strcmp(argv[i], "--stack")) {
            char *parse_end;
            ++i;
            if (i >= argc) {
                printf("Error: No stack size provided\n");
                return 1;
            }
            stack = strtol(argv[i], &parse_end, 10);
            if (stack < 1024 || *parse_end) {
                printf("Error: Invalid stack specification (must be integer of size at least 1024)\n");
                return 1;
            }
            continue;
        }
        if (argv[i][0] == '-') {
            printf("Error: Unrecognized argument '%s'\n", argv[i]);
            usage();
            return 1;
        }
        /* If it's not an option, it's a positional argument */
        if (!dest_path) {
            dest_path = argv[i];
        } else if (!img1_path) {
            img1_path = argv[i];
        } else if (!img2_path) {
            img2_path = argv[i];
        } else {
            printf("Error: Too many arguments\n");
            usage();
            return 1;
        }
    }
    /* Did we get enough positional arguments? */
    if (!img1_path) {
        printf("Error: Too few arguments\n");
        usage();
        return 1;
    }

    /***** Check stack size *****/
    if (stackSize < 10000) {
        printf("Reported stack size is %lu bytes. That's not enough.\n"
               "Please run STACK 16384 first to assign 16KB of stack.\n",
               stackSize);
        return 1;
    }

    /***** Validate PNG arguments *****/
    if (!sanity_check(img1_path, img2_path, &width, &height)) {
        return 1;
    }

    /***** Convert the PNGs *****/
    img1_dat = convert(img1_path);
    if (!img1_dat) {
        return 1;
    }
    if (img2_path) {
        img2_dat = convert(img2_path);
        if (!img2_dat) {
            free(img1_dat);
            return 1;
        }
    }

    /***** Save the result *****/
    SaveIcon(dest_path, width, height, img1_dat, img2_dat, stack);

    /***** Clean up *****/
    if (img2_dat) {
        free(img2_dat);
    }
    free (img1_dat);
    return 0;
}
