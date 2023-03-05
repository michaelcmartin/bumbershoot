#include <Types.h>
#include <ToolUtils.h>
#include <Quickdraw.h>
#include <Windows.h>
#include <Dialogs.h>
#include <TextEdit.h>
#include <Menus.h>
#include <Devices.h>
#include <Files.h>
#include <StandardFile.h>

extern pascal void XSSSeedRandom(unsigned long seed);
extern pascal unsigned long XSSRandom(void);

static QDGlobals qd;

static char hexits[16] = {
	'0', '1', '2', '3', '4', '5', '6', '7',
	'8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
};

static OSErr writeLine(short fileNum, int val, unsigned long hexVal)
{
	long count = 14;
	char buf[14];
	buf[0] = ' ';
	buf[1] = ' ';
	buf[2] = hexits[val % 10];
	if (val >= 10) {
		val /= 10;
		buf[1] = hexits[val % 10];
		if (val >= 10) {
			val /= 10;
			buf[0] = hexits[val % 10];
		}
	}
	buf[ 3] = '.';
	buf[ 4] = ' ';
	buf[ 5] = hexits[(hexVal >> 28) & 0x0F];
	buf[ 6] = hexits[(hexVal >> 24) & 0x0F];
	buf[ 7] = hexits[(hexVal >> 20) & 0x0F];
	buf[ 8] = hexits[(hexVal >> 16) & 0x0F];
	buf[ 9] = hexits[(hexVal >> 12) & 0x0F];
	buf[10] = hexits[(hexVal >>  8) & 0x0F];
	buf[11] = hexits[(hexVal >>  4) & 0x0F];
	buf[12] = hexits[(hexVal      ) & 0x0F];
	buf[13] = '\n';

	return FSWrite(fileNum, &count, buf);
}

void main()
{
	short fileNum = 0;
	OSErr err;
	Point pickerLoc;
	SFReply reply;
	int i;

	/* Initialize Toolbox */
	InitGraf(&qd.thePort);
	InitFonts();
	InitWindows();
	InitMenus();
	TEInit();
	InitDialogs(nil);
	InitCursor();

	/* Ask the user where to put the results */
	pickerLoc.h = (qd.screenBits.bounds.right + qd.screenBits.bounds.left) >> 1;
	pickerLoc.v = (qd.screenBits.bounds.top + qd.screenBits.bounds.bottom) >> 1;
	pickerLoc.h -= 150;
	pickerLoc.v -= 50;
	SFPutFile(pickerLoc, "\pSelect Test Output Location", "\pTest Output", nil, &reply);
	if (!reply.good) {
		return;  /* User canceled */
	}

	/* Create and open the file. It's OK if it already exists. */
	err = Create(reply.fName, reply.vRefNum, 'ttxt', 'TEXT');
	if (err != noErr && err != dupFNErr) {
		return;
	}
	err = FSOpen(reply.fName, reply.vRefNum, &fileNum);
	if (err != noErr) {
		return;
	}

	/* Truncate the file if it existed before */
	SetEOF(fileNum, 0);

	/* Output our test data */
	XSSSeedRandom(1);
	for(i = 0; i < 100; ++i) {
		writeLine(fileNum, i+1, XSSRandom());
	}

	/* Force the write and close everything down */
	FSClose(fileNum);
	FlushVol(nil, reply.vRefNum);
	return;
}
