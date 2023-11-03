#include <stdint.h>
#include <stdio.h>

int main(int argc, char **argv)
{
    FILE *f;
    if (argc < 2) {
        fprintf(stderr, "Usage: %s {ROM}\n\nOnly power-of-two LoROM is supported.\n", argv[0]);
        return 1;
    }
    if ((f = fopen(argv[1], "r+b")) == 0) {
        perror(argv[1]);
        return 1;
    }
    uint16_t sum = 0;
    size_t sz = 0;
    while (!feof(f)) {
        int b = fgetc(f);
        if (b < 0) {
            break;
        }
        sz += 1;
        sum += b;
    }
    printf("Size is %d.\nChecksum is %04X.\n", sz, sum);
    fseek(f, 0x7fdc, SEEK_SET);
    fputc((sum & 0xff) ^ 0xff, f);
    fputc(((sum >> 8) & 0xff) ^ 0xff, f);
    fputc(sum & 0xff, f);
    fputc((sum >> 8) & 0xff, f);
    fclose(f);
    return 0;
}
