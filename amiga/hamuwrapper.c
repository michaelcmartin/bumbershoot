#include <proto/dos.h>

void open_amiga_console(const char *console_spec);
void close_amiga_console(void);

int AmigaMain(int argc, char **argv);

int main(int argc, char **argv)
{
    int retcode;
    if (argc == 0) {
        open_amiga_console("CON:10/12/620/170/Hamurabi");
    }
    retcode = AmigaMain(argc, argv);
    if (argc == 0) {
        close_amiga_console();
    }
    return retcode;
}

#define main AmigaMain
#include "../full/hamurabi.c"