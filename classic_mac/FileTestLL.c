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

static ParamBlockRec paramBlock;
static QDGlobals qd;

static char hexits[16] = {
	'0', '1', '2', '3', '4', '5', '6', '7',
	'8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
};

static OSErr writeLine(int val, unsigned long hexVal)
{
	ParmBlkPtr ioReq = &paramBlock;
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

	ioReq->ioParam.ioReqCount = 14;
	ioReq->ioParam.ioBuffer = buf;
	PBWriteSync(ioReq);
	return ioReq->ioParam.ioResult;
}

void main()
{
	ParmBlkPtr ioReq = &paramBlock;
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

	/* Clear out the parameter block. Memset requires the C runtime,
	 * which are aren't bothering to link, so do this by hand */
	for (i = 0; i < sizeof(ParamBlockRec); ++i) {
		((unsigned char *)ioReq)[i] = 0;
	}

	/* Ask the user where to put the results */
	pickerLoc.h = (qd.screenBits.bounds.right + qd.screenBits.bounds.left) >> 1;
	pickerLoc.v = (qd.screenBits.bounds.top + qd.screenBits.bounds.bottom) >> 1;
	pickerLoc.h -= 150;
	pickerLoc.v -= 50;
	SFPutFile(pickerLoc, "\pSelect Test Output Location", "\pTest Output", nil, &reply);
	if (!reply.good) {
		return;  /* User canceled */
	}

	/* Create and set type of the file. It's OK if it already exists. */
	ioReq->fileParam.ioVRefNum = reply.vRefNum;
	ioReq->fileParam.ioNamePtr = reply.fName;
	ioReq->fileParam.ioFVersNum = 0;
	PBCreateSync(ioReq);
	if (ioReq->fileParam.ioResult != noErr && ioReq->fileParam.ioResult != dupFNErr) {
		return;
	}
	ioReq->fileParam.ioFDirIndex = 0; /* Keep using name pointer/version */
	PBGetFInfoSync(ioReq);
	ioReq->fileParam.ioFlFndrInfo.fdType = 'TEXT';
	ioReq->fileParam.ioFlFndrInfo.fdCreator = 'ttxt';
	PBSetFInfoSync(ioReq);

	/* Open the file. Most IOReq arguments are all still fine */
	ioReq->ioParam.ioPermssn = fsWrPerm;
	PBOpenSync(ioReq);
	if (ioReq->fileParam.ioResult != noErr) {
		return;
	}

	/* Truncate the file if it existed before */
	ioReq->ioParam.ioMisc = 0;
	PBSetEOFSync(ioReq);

	/* Set our write mode to match normal file operation */
	ioReq->ioParam.ioPosMode = fsAtMark;
	ioReq->ioParam.ioPosOffset = 0;

	/* Output our test data */
	XSSSeedRandom(1);
	for(i = 0; i < 100; ++i) {
		writeLine(i+1, XSSRandom());
	}

	/* Force the write and close everything down */
	PBCloseSync(ioReq);
	ioReq->volumeParam.ioNamePtr = nil;
	PBFlushVolSync(ioReq);
	return;
}
