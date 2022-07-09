#ifndef LIBICON_H_
#define LIBICON_H_

#include <stdint.h>

void SaveIcon(const char *filename, uint32_t width, uint32_t height, uint16_t *image, uint16_t *highlight_image, uint32_t stack);

#endif