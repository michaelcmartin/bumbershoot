#include <stdio.h>

int main(int argc, char **argv)
{
    FILE *f, *o;
    int ok, val, block_skip, block_size, i, dword[4];
    if (argc < 2) {
        fprintf(stderr, "Usage: %s {LZ4 file}\n", argc > 0 ? argv[0] : "lz4_unframe");
        return 1;
    }
    f = fopen(argv[1], "rb");
    if (!f) {
        perror(argv[1]);
        return 1;
    }
    /* Rely on short-circuiting to stop reading if the magic number
     * ever goes awry */
    if (fgetc(f) != 0x04 || fgetc(f) != 0x22 || fgetc(f) != 0x4d || fgetc(f) != 0x18) {
        fprintf(stderr, "%s: Not an LZ4 file\n", argv[1]);
        fclose(f);
        return 1;
    }
    val = fgetc(f);
    if (val < 0) {
        fprintf(stderr, "%s: Invalid header\n", argv[1]);
        fclose(f);
        return 1;
    }
    if ((val & 0xc0) != 0x40) {
        fprintf(stderr, "%s: Incompatible LZ4 version\n", argv[1]);
        fclose(f);
        return 1;
    }

    block_skip = 1;
    if (val & 0x01) block_skip += 4;
    if (val & 0x08) block_skip += 8;

    val = fgetc(f);
    if (val < 0) {
        fprintf(stderr, "%s: Invalid header\n", argv[1]);
        fclose(f);
        return 1;
    }
    if ((val & 0x70) != 0x40) {
        fprintf(stderr, "%s: Block size > 64KB\n", argv[1]);
        fclose(f);
        return 1;
    }
    for (i = 0; i < block_skip; ++i) {
        val = fgetc(f);
        if (val < 0) {
            fprintf(stderr, "%s: Invalid header\n", argv[1]);
            fclose(f);
            return 1;
        }
    }
    for (i = 0; i < 4; ++i) {
        dword[i] = fgetc(f);
        if (dword[i] < 0) {
            fprintf(stderr, "%s: Invalid block size\n", argv[1]);
            fclose(f);
            return 1;
        }
    }
    block_size = dword[0] | (dword[1] << 8) | (dword[2] << 16) | (dword[3] << 24);
    if (block_size & 0x80000000) {
        fprintf(stderr, "%s: Incompressible source data\n", argv[1]);
        fclose(f);
        return 1;
    }
    if (block_size > 0xfffe) {
        fprintf(stderr, "%s: Block too large (%d)\n", argv[1], block_size);
        fclose(f);
        return 1;
    }

    o = fopen("compressed.bin", "wb");
    if (!o) {
        perror("Output file");
        fclose(f);
        return 1;
    }
    ok = 1;
    for (i = 0; i < block_size; ++i) {
        val = fgetc(f);
        if (val < 0) {
            fprintf(stderr, "%s: File truncated\n", argv[1]);
            ok = 0;
            break;
        }
        fputc(val, o);
    }
    if (ok) {
        fputc(0, o);
        fputc(0, o);
    }
    fclose(o);
    fclose(f);
    return 1 - ok;
}
