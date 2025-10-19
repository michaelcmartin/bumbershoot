#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint8_t rom_start[0x8000];
static uint32_t rom_size;
static uint32_t final_size;
static uint32_t product_code;
static uint16_t rom_checksum;
static uint8_t product_revision;

/* Next power of 2, algo courtesy https://graphics.stanford.edu/~seander/bithacks.html */
static uint32_t next_power_of_two(uint32_t n)
{
    --n;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return n + 1;
}

static void write_product_code(uint8_t *p)
{
    uint32_t n = product_code;
    /* First two bytes are little-endian BCD */
    *p++ = (n % 10) | (((n / 10) % 10) << 4);
    n /= 100;
    *p++ = (n % 10) | (((n / 10) % 10) << 4);
    n /= 100;
    *p = (n & 0x0f) << 4;
}

/* Compute ROM size codes, 8KB-1MB */
static uint8_t rom_size_code(uint32_t n)
{
    uint32_t test = 0x2000;
    uint8_t result = 10;
    while (test < n) {
        test <<= 1;
        ++result;
    }
    return result & 0x0f;
}

/* Returns true if the file is fixable. Returns false after printing an error
   if there's something wrong with it. On success, rom_start holds the first
   32KB of ROM with the header in place. */
static bool load_and_process(FILE *f)
{
    uint32_t i;
    /* Load the first 32KB into RAM, or the whole ROM if smaller */
    rom_size = 0;
    rom_checksum = 0;
    for (i = 0; i < 0x8000; ++i) {
        if (ferror(f) || feof(f)) break;
        int c = fgetc(f);
        if (c < 0) break;
        rom_start[i] = c;
        ++rom_size;
    }
    /* Fill the rest of rom_start with 0xFF bytes to cover any padding */
    for (i = rom_size; i < 0x8000; ++i) {
        rom_start[i] = 0xff;
    }
    /* Then scan, count, and checksum what's left in the ROM file */
    while (!ferror(f) && !feof(f)) {
        int c = fgetc(f);
        if (c < 0) break;
        ++rom_size;
        rom_checksum += c;
        if (rom_size > 0x100000) {
            fprintf(stderr, "ERROR: ROM file exceeds 1MB\n");
            return false;
        }
    }
    /* Compute intended ROM size */
    final_size = next_power_of_two(rom_size);
    if (final_size < 0x2000) final_size = 0x2000;
    printf("Input file is %u bytes, final file will be %u bytes\n", rom_size, final_size);
    /* Add contribution of any 0xFF bytes past 32KB to our checksum */
    for (i = 0x8000; i < final_size; ++i) {
        rom_checksum += 0xff;
    }
    /* Locate the header's space and ensure it is empty */
    uint32_t header_loc = final_size - 16;
    if (header_loc > 0x7FF0) header_loc = 0x7FF0;
    uint8_t first = rom_start[header_loc];
    for (i = 0; i < 16; ++i) {
        uint8_t c = rom_start[header_loc+i];
        if ((c != 0x00 && c != 0xff) || c != first) {
            fprintf(stderr, "ERROR: Header data at $%04X must be either all $00 or all $FF\n", header_loc);
            return false;
        }
    }
    /* Now add the contribution of all non-header pre-32KB data to checksum */
    for (i = 0; i < header_loc; ++i) {
        rom_checksum += rom_start[i];
    }
    printf("ROM checksum is $%04X\n", rom_checksum);
    /* Write the header data into place */
    strcpy((char *)rom_start + header_loc, "TMR SEGA  ");
    rom_start[header_loc + 10] = rom_checksum & 0xff;
    rom_start[header_loc + 11] = rom_checksum >> 8;
    write_product_code(rom_start + header_loc + 12);
    rom_start[header_loc + 14] |= product_revision;
    rom_start[header_loc + 15] = 0x40 | rom_size_code(final_size);
    return true;
}

static void write_changes(FILE *f)
{
    uint32_t i, header_loc;
    /* Write out padding bytes */
    for (i = rom_size; i < final_size; ++i) {
        fputc(0xff, f);
    }
    header_loc = final_size - 16;
    if (header_loc > 0x7ff0) header_loc = 0x7ff0;
    /* Copy header into appropriate location in file */
    fseek(f, header_loc, SEEK_SET);
    for (i = 0; i < 16; ++i) {
        fputc(rom_start[header_loc + i], f);
    }
}

static int usage(const char *exec_name)
{
    fprintf(stderr, "Usage:\n\t%s [--code CODE] [--rev REVISION] rom.sms\n\n"
            "\t-c, --code CODE\tProduct code (0-159999)\n"
            "\t-r, --rev  REVISION\tROM revision (0-15)\n", exec_name);
    return 1;
}

int main(int argc, char **argv)
{
    char *fname = NULL;
    product_code = 0;
    product_revision = 0;
    if (argc < 1) return usage("smsfix");
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--code") || !strcmp(argv[i], "-i")) {
            ++i;
            if (i >= argc) return usage(argv[0]);
            product_code = atoi(argv[i]);
            if (product_code < 0 || product_code >= 160000) return usage(argv[0]);
        }
        else if (!strcmp(argv[i], "--rev") || !strcmp(argv[i], "-r")) {
            ++i;
            if (i >= argc) return usage(argv[0]);
            product_revision = atoi(argv[i]);
            if (product_revision < 0 || product_revision >= 16) return usage(argv[0]);
        } else if (fname) {
            return usage(argv[0]);
        } else {
            fname = argv[i];
        }
    }

    FILE *f = fopen(fname, "r+b");
    if (!f) {
        perror(fname);
        return 1;
    }
    if (load_and_process(f))
        write_changes(f);
    fclose(f);
    return 0;
}
