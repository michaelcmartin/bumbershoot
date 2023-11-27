/*********************************************************************
 * MANDELBROT SET GENERATOR
 * Main Shell program
 * (c) 2023, Michael C. Martin
 * Made available under the MIT License; see README.md
 **********************************************************************/

#include <stdio.h>
#include <stdint.h>
#include <time.h>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// Draw the entire figure
#define XMIN -2.0
#define YMAX 1.25
#define WIDTH 2.5

// Zoom in on one of the "Mini-Mandelbrots"
// #define XMIN -0.19112141927083334
// #define YMAX 1.0658772786458333
// #define WIDTH 0.06510416666666667

#define EDGE 4096

extern void mandelbrot(double xmin, double ymax, double width, int edge, uint16_t *output);

uint16_t vals[EDGE * EDGE];
uint32_t palette[1000];
uint32_t img[EDGE * EDGE];

#define RGB(r,g,b) \
	(((r) & 0xff) | (((g) & 0xff) << 8) | (((b) & 0xff) << 16) | \
	 0xff000000)

void tight_palette(void)
{
	int i;
	for (i = 0; i < 32; ++i) {
		palette[i] = RGB(0,0,64+i*4);
	}
	for (i = 0; i < 64; ++i) {
		palette[i+ 32] = RGB(i*3,0,192);
		palette[i+ 96] = RGB(192+i,0,192-i*3);
		palette[i+160] = RGB(255,i*4,0);
		palette[i+224] = RGB(255,255,i*4);
	}
	for (i = 280; i < 1000; ++i) {
		palette[i] = RGB(255,255,255);
	}
}

int main(int argc, char **argv)
{
	int i;
	FILE *vdump;
	struct timespec start_time, end_time;
	double diff_time;

	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &start_time);
	mandelbrot(XMIN, YMAX, WIDTH, EDGE, vals);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &end_time);
	if ((vdump = fopen("mandelbrot.dat", "wb")) != NULL) {
		for (i = 0; i < EDGE * EDGE; ++i) {
			fputc(vals[i] & 0xff, vdump);
			fputc((vals[i] >> 8) & 0xff, vdump);
		}
		fclose(vdump);
	}

	tight_palette();
	for (i = 0; i < EDGE * EDGE; ++i) {
		if (vals[i] >= 1000) {
			img[i] = 0xff000000;
		} else {
			int v = vals[i] * 3;
			if (v > 999) { v = 999; }
			img[i] = palette[v];
		}
	}
	stbi_write_png("mandelbrot.png", EDGE, EDGE, 4, img, EDGE*4);

	diff_time = end_time.tv_nsec - start_time.tv_nsec;
	diff_time /= 1000000000.0;
	diff_time += end_time.tv_sec - start_time.tv_sec;
	printf("Mandelbrot execution time: %.3lf\n", diff_time);
	return 0;
}

