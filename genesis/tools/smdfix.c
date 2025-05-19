#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint8_t buffer[0x4000];

static void fput_u32(uint32_t val, FILE *f)
{
    fputc((val >> 24) & 0xff, f);
    fputc((val >> 16) & 0xff, f);
    fputc((val >>  8) & 0xff, f);
    fputc((val      ) & 0xff, f);
}

static void fput_u16(uint16_t val, FILE *f)
{
    fputc((val >>  8) & 0xff, f);
    fputc((val      ) & 0xff, f);
}

static size_t fillbuf(FILE *f)
{
    size_t i, remaining;
    i = 0;
    remaining = 0x4000;

    memset(buffer, 0xff, 0x4000);

    while (remaining > 0 && f && !feof(f) && !ferror(f)) {
        size_t n = fread(buffer + i, 1, remaining, f);
        i += n;
        remaining -= n;
    }
    return i;
}

static int fixbin(const char *pathname)
{
    size_t chunk_size, real_size, total_size;
    int i;
    uint16_t checksum;

    if (!pathname) {
        fprintf(stderr, "Internal error: null pathname in fixbin()\n");
        return 1;
    }
    FILE *f = fopen(pathname, "r+b");
    if (!f) {
        perror(pathname);
        return 1;
    }
    total_size = real_size = 0;
    chunk_size = fillbuf(f);
    if (chunk_size < 0x200 ||
        (strncmp(buffer + 0x100, "SEGA GENESIS    ", 16) &&
         strncmp(buffer + 0x100, "SEGA MEGA DRIVE ", 16))) {
        fprintf(stderr, "%s: Not a Genesis/Mega Drive ROM\n", pathname);
        fclose(f);
        return 1;
    }
    checksum = 0;
    i = 0x200;
    while (chunk_size > 0) {
        real_size += chunk_size;
        total_size += 0x4000;
        while (i < 0x4000) {
            checksum += ((unsigned short)buffer[i]) << 8;
            checksum += (unsigned short)buffer[i+1];
            i += 2;
        }
        if (feof(f) || ferror(f)) {
            break;
        }
        chunk_size = fillbuf(f);
        i = 0;
    }
#ifdef VERBOSE
    printf("Initial ROM size: %zd\nFinal ROM size: %zu\nChecksum: %04X\n",
            real_size, total_size, checksum);
#endif
    if (real_size != total_size) {
#ifdef VERBOSE
        printf("Adding %zu bytes of padding\n", total_size - real_size);
#endif
        fseek(f, 0, SEEK_END);
        while (real_size < total_size) {
            ++real_size;
            fputc(0xff, f);
        }
    }
    /* TODO: Cache header values and do not update anything if everything
     *       is already fine */
#ifdef VERBOSE
    printf("Updating header\n");
#endif
    fseek(f, 0x1a0, SEEK_SET);
    fput_u32(0, f);
    fput_u32(total_size - 1, f);
    fput_u32(0x00ff0000, f);
    fput_u32(0x00ffffff, f);
    fseek(f, 0x18e, SEEK_SET);
    fput_u16(checksum, f);
    fclose(f);
    return 0;
}

int main(int argc, char **argv)
{
    const char *progname = "smdfix";
    if (argc > 0) progname = argv[0];
    if (argc != 2) {
        fprintf(stderr, "Usage:\n   %s <romname.bin>\n", progname);
        return 1;
    }
    return fixbin(argv[1]);
}
