#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void
convert(FILE *dest, FILE *src, const char *progname, int load_addr, int start_addr)
{
    int i, chk;
    unsigned char block[256];
    char realprogname[8];

    /* Create the filename as it will appear in the tape header */
    for (i = 0; i < 8; ++i) {
        realprogname[i] = 0x20;
    }
    for (i = 0; i < 8; ++i) {
        if (progname[i] && isalnum(progname[i])) {
            realprogname[i] = toupper(progname[i]);
        } else {
            break;
        }
    }

    /* This macro will handle the tedious bits of the checksumming we
     * have to do. Bytes that don't participate in checksums will be
     * emitted with fputc as usual */
#define WRITE_CHECKED_BYTE(c) fputc(c, dest); chk += c

    /* Write first tape leader */
    for (i = 0; i < 256; ++i) {
        fputc(0x55, dest);
    }

    /* Write the filename block */
    chk = 0;
    fputc(0x55, dest);
    fputc(0x3c, dest);
    WRITE_CHECKED_BYTE(0x00);
    WRITE_CHECKED_BYTE(0x0f);
    for (i = 0; i < 8; ++i) {
        WRITE_CHECKED_BYTE(realprogname[i]);
    }
    WRITE_CHECKED_BYTE(0x02);
    WRITE_CHECKED_BYTE(0x00);
    WRITE_CHECKED_BYTE(0x00);
    WRITE_CHECKED_BYTE((start_addr >> 8) & 0xff);
    WRITE_CHECKED_BYTE(start_addr & 0xff);
    WRITE_CHECKED_BYTE((load_addr >> 8) & 0xff);
    WRITE_CHECKED_BYTE((load_addr & 0xff));
    fputc(chk & 0xff, dest);
    fputc(0x55, dest);

    /* Write the second tape leader. */
    for (i = 0; i < 256; ++i) {
        fputc(0x55, dest);
    }

    /* Write the actual program data. */
    while (!feof(src) && !ferror(src)) {
        for (i = 0; i < 255; ++i) {
            int c = fgetc(src);
            if (c < 0) {
                break;
            }
            block[i] = (unsigned char)c;
        }
        if (i > 0) {
            int j;
            chk = 0;
            fputc(0x55, dest);
            fputc(0x3c, dest);
            WRITE_CHECKED_BYTE(0x01);
            WRITE_CHECKED_BYTE(i);
            for (j = 0; j < i; ++j) {
                WRITE_CHECKED_BYTE(block[j]);
            }
            fputc(chk & 0xff, dest);
            fputc(0x55, dest);
        }
    }

    /* Write the end of file data. */
    chk = 0;
    fputc(0x55, dest);
    fputc(0x3c, dest);
    WRITE_CHECKED_BYTE(0xff);
    WRITE_CHECKED_BYTE(0x00);
    fputc(chk & 0xff, dest);
    fputc(0x55, dest);
}

static void
replace_ext(char *s, const char *ext)
{
    int last_dot = -1, i = 0;
    while (s[i]) {
        if (s[i] == '.') {
            last_dot = i;
        }
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
        fprintf(stderr, "Error: %s address just a hex prefix\n", name);
        return 0;
    }
    while (*addr) {
        char c = *addr++;
        val *= 16;
        if (c >= '0' && c <= '9') {
            val += c - '0';
        } else if (c >= 'A' && c <= 'F') {
            val += c - 'A' + 10;
        } else if (c >= 'a' && c <= 'f') {
            val += c - 'a' + 10;
        } else {
            fprintf(stderr, "Error: %s address has invalid character '%c'\n", name, c);
            return 0;
        }
        if (val > 0xFFFF) {
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
    /* Create the output file name. This is at most four characters
     * longer than the original, and less if it has an extension of
     * its own. Since the input file will normally have an extension
     * of .bin, there will *usually* be no change, but we don't take
     * chances here. */
    outfilename = malloc(strlen(argv[1]) + 5);
    if (!outfilename) {
        fprintf(stderr, "Flagrant System Error: memory is broken\n");
        return 1;
    }
    strcpy(outfilename, argv[1]);
    replace_ext(outfilename, "cas");
    if (!strcmp(argv[1], outfilename)) {
        fprintf(stderr, "Input is already a .cas file\n");
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
