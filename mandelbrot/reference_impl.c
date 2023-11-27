/*********************************************************************
 * MANDELBROT SET GENERATOR
 * Reference implementation in C
 * (c) 2023, Michael C. Martin
 * Made available under the MIT License; see README.md
 **********************************************************************/

#include <stdint.h>

void mandelbrot(double xmin, double ymax, double width, int edge, uint16_t *output)
{
	int ix, iy, out_index;
	out_index = 0;
	for (iy = 0; iy < edge; ++iy) {
		double y = ymax - iy * (width / edge);
		for (ix = 0; ix < edge; ++ix) {
			double x = xmin + ix * (width / edge);
			double a = 0.0;
			double b = 0.0;
			uint16_t n;
			for (n = 0; n < 1000; ++n) {
				double a2 = a*a, b2 = b*b;
				if (a2 + b2 > 4.0) {
					break;
				}
				b = 2 * a * b + y;
				a = a2 + x - b2;
			}
			output[out_index++] = n;
		}
	}
}

