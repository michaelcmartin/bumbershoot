#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void
write_lead(FILE *dest)
{
    int i;
    for (i = 0; i < 100; ++i)
        fputc(0, dest);
    fputc(1, dest);
}

static void
write_chunk(unsigned char *buf, size_t n, FILE *dest)
{
    uint8_t crc = 0;
    size_t i;
    for (i = 0; i < n; ++i)
    {
        fputc(buf[i], dest);
        crc = (buf[i] - crc) ^ 0xff;
    }
    fputc(crc, dest);
}

static void
convert(FILE *dest, FILE *src, const char *progname, uint16_t load_addr, uint16_t start_addr)
{
    static uint8_t buffer[49152];
    static uint8_t header[16];
    static size_t buffer_size = 0;
    int i, j;
    const char *name;
    /* Load source file into buffer */
    while ((i = fgetc(src)) >= 0)
        buffer[buffer_size++] = (uint8_t)i;
    /* Find start of filename by finding the last / or \ in the path */
    i = 0;
    for (j = 0; progname[j] != 0; ++j) {
        if (progname[j] == '/' || progname[j] == '\\') {
            i = j+1;
        }
    }
    /* Create on-tape filename */
    for (j = 0; j < 5; ++j) {
        if(progname[i] != 0 && progname[i] != '.') {
            header[j] = toupper(progname[i]);
            ++i;
        } else {
            header[j] = 32;
        }
    }
    /* Fill in the remainder of the header */
    header[5] = 0x55;                   /* File Header ID */
    header[6] = 0x00;                   /* Filetype (runnable machine code) */
    header[7] = buffer_size & 0xff;     /* File size */
    header[8] = (buffer_size >> 8) & 0xff;
    header[9] = load_addr & 0xff;       /* Load address */
    header[10] = (load_addr >> 8) & 0xff;
    header[11] = start_addr & 0xff;     /* Exec address */
    header[12] = (start_addr >> 8) & 0xff;
    header[13] = 0x00;                  /* Buffer padding */
    header[14] = 0x00;
    header[15] = 0x00;

    /* Now write out the full tape image */
    write_lead(dest);
    write_chunk(header, 16, dest);
    write_lead(dest);
    i = 0;
    while (i < buffer_size) {
        j = i + 256;
        if (j > buffer_size)
            j = buffer_size;
        write_chunk(buffer + i, j - i, dest);
        i = j;
    }
}

static void
replace_ext(char *s, const char *ext)
{
    int last_dot = -1, i = 0;
    while (s[i]) {
        if (s[i] == '.') last_dot = i;
        ++i;
    }
    if (last_dot == -1) {
        /* No extension, add a dot at the end */
        s[i] = '.';
        last_dot = i;
    }
    /* Then put the new extension on */
    strcpy(s+last_dot+1, ext);
}

static int
parse_addr(const char *name, const char *addr, int *result)
{
    int val = 0;
    /* First skip any hex-y prefixes the user typed out of habit */
    if (addr[0] == '$') {
        ++addr;
    } else if (addr[0] == '0' && addr[1] == 'x') {
        addr += 2;
    }
    if (*addr == 0) {
        fprintf(stderr, "Error: %s just a hex prefix\n", name);
        return 0;
    }
    while (*addr) {
        char c = *addr++;
        val *= 16;
        if (c >= '0' && c <= '9') {
            val += c- '0';
        } else if (c >= 'A' && c <= 'F') {
            val += c - 'A' + 10;
        } else if (c >= 'a' && c <= 'f') {
            val += c- 'a' + 10;
        } else {
            fprintf(stderr, "Error: %s address has invalid character '%c'\n", name, c);
            return 0;
        }
        if (val > 0xffff) {
            fprintf(stderr, "Error: %s address out of range (0000-FFFF)\n", name);
            return 0;
        }
    }
    *result = val;
    return 1;
}

int
main(int argc, char **argv)
{
    int load_addr, start_addr;
    char *outfilename;
    FILE *binfile, *outfile;
    if ((argc < 3) || (argc > 4)) {
        fprintf(stderr, "Usage:\n\t%s <binary file> <load address> [<start address>]\n", argv[0]);
        fprintf(stderr, "Load addresses are in hex.\n");
        return 1;
    }
    if (!parse_addr("Load", argv[2], &load_addr)) {
        return 1;
    }
    if (argc == 4) {
        if (!parse_addr("Start", argv[3], &start_addr)) {
            return 1;
        }
    } else {
        start_addr = load_addr;
    }
    /* Create the output file name. This is at most five characters
     * longer than the original, and less if it has an extension of
     * its own. */
    outfilename = malloc(strlen(argv[1]) + 6);
    if (!outfilename) {
        fprintf(stderr, "Flagrant System Error: memory is broken\n");
        return 1;
    }
    strcpy(outfilename, argv[1]);
    replace_ext(outfilename, "tape");
    if (!strcmp(argv[1], outfilename)) {
        fprintf(stderr, "Input is already a .tape file\n");
        free(outfilename);
        return 1;
    }

#if VERBOSE
    printf("Source: %s\nDestination: %s\nLoad address: %d ($%04x)\nStart address: %d ($%04x)\n", argv[1], outfilename, load_addr, load_addr, start_addr, start_addr);
#endif

    /* Now try to create the files we read from and write to. */
    binfile = fopen(argv[1], "rb");
    if (!binfile) {
        perror(argv[1]);
        free(outfilename);
        return 1;
    }

    outfile = fopen(outfilename, "wb");
    if (!outfile) {
        perror(outfilename);
        fclose(binfile);
        free(outfilename);
        return 1;
    }
    free(outfilename);

    /* Setup was OK! */
    convert(outfile, binfile, argv[1], load_addr, start_addr);
    fclose(binfile);
    fclose(outfile);
    return 0;
}
