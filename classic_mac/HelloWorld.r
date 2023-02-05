#include "Types.r"
#include "SysTypes.r"

#include "HelloWorld.h"

/* Our icon */

/* Fine-structured mask */

data 'ics#' (128) {
	$"0000 01F8 06A8 0D58 1AB0 3550 6AA0 5560"
	$"6AC0 55C0 6B60 5630 781A 688E 2214 0880"
	$"0000 01F8 07F8 0FF8 1FF0 3FF0 7FE0 7FE0"
	$"7FC0 7FC0 7FE0 7FF0 7FFA 7FFE 3FFC 0FF8"
};

data 'ICN#' (128) {
	$"0000 0000 0000 0000 0003 FF00 000F 77C0"
	$"003D DDC0 0077 7780 01DD DD80 0377 7780"
	$"03DD DD00 0777 7700 0DDD DD00 0F77 7600"
	$"1DDD DE00 1777 7400 1DDD DC00 3777 7800"
	$"3DDD D800 3777 7000 3FDD C000 3FF7 6000"
	$"3FFD F000 3FF7 3800 3FFE 1C00 3FFC 0E00"
	$"3FFA A700 3FF5 5398 1FAA A9CC 1F55 54EC"
	$"0AAA AA7C 0555 5538 002A AA80 0000 0000"
	$"0000 0000 0007 FF80 001F FFE0 007F FFE0"
	$"00FF FFE0 03FF FFE0 07FF FFC0 07FF FFC0"
	$"0FFF FFC0 1FFF FF80 1FFF FF80 3FFF FF80"
	$"3FFF FF00 3FFF FF00 7FFF FE00 7FFF FE00"
	$"7FFF FC00 7FFF FC00 7FFF F800 7FFF F800"
	$"7FFF FC00 7FFF FE00 7FFF FF00 7FFF FF80"
	$"7FFF FFFC 7FFF FFFF 7FFF FFFF 3FFF FFFF"
	$"1FFF FFFF 0FFF FFFF 007F FFFC 0000 0000"
};

/* Coarse-oval mask */
/*
data 'ics#' (128) {
	$"0000 01F8 06A8 0D58 1AB0 3550 6AA0 5560"
	$"6AC0 55C0 6B60 5630 781A 688E 2214 0880"
	$"1FF8 7FFE 7FFE FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF FFFF FFFF FFFF 7FFE 7FFE 1FF8"
};

data 'ICN#' (128) {
	$"0000 0000 0000 0000 0003 FF00 000F 77C0"
	$"003D DDC0 0077 7780 01DD DD80 0377 7780"
	$"03DD DD00 0777 7700 0DDD DD00 0F77 7600"
	$"1DDD DE00 1777 7400 1DDD DC00 3777 7800"
	$"3DDD D800 3777 7000 3FDD C000 3FF7 6000"
	$"3FFD F000 3FF7 3800 3FFE 1C00 3FFC 0E00"
	$"3FFA A700 3FF5 5398 1FAA A9CC 1F55 54EC"
	$"0AAA AA7C 0555 5538 002A AA80 0000 0000"
	$"1FFF FFF8 7FFF FFFE 7FFF FFFE FFFF FFFF"
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF 7FFF FFFF 7FFF FFFE 1FFF FFF8"
};
*/

/* Menu-related resources. Constants are defined in HelloWorld.h. */

resource 'MBAR' (rMenuBar, preload) {
	{ mApple, mFile, mEdit };
};

resource 'MENU' (mApple, preload) {
	mApple, textMenuProc,
	0b1111111111111111111111111111101, /* disable dashed line, */
	enabled, apple, /* enable About and DAs */
	{
		"About HelloWorld…",
			noicon, nokey, nomark, plain;
		"-",
			noicon, nokey, nomark, plain
	}
};

resource 'MENU' (mFile, preload) {
	mFile, textMenuProc,
	0b1111111111111111111111100000000, /* Enable only Quit */
	enabled, "File",
	{
		"New",
			noicon, "N", nomark, plain;
		"Open…",
			noicon, "O", nomark, plain;
		"-",
			noicon, nokey, nomark, plain;
		"Close",
			noicon, "W", nomark, plain;
		"Save",
			noicon, "S", nomark, plain;
		"Save As…",
			noicon, nokey, nomark, plain;
		"Revert",
			noicon, nokey, nomark, plain;
		"-",
			noicon, nokey, nomark, plain;
		"Quit",
			noicon, "Q", nomark, plain;
	}
};

resource 'MENU' (mEdit, preload) {
	mEdit, textMenuProc,
	0b1111111111111111111111110000000, /* Disable everything, this is for DeskAccs */
	enabled, "Edit",
	{
		"Undo",
			noicon, "Z", nomark, plain;
		"-",
			noicon, nokey, nomark, plain;
		"Cut",
			noicon, "X", nomark, plain;
		"Copy",
			noicon, "C", nomark, plain;
		"Paste",
			noicon, "V", nomark, plain;
		"Clear",
			noicon, nokey, nomark, plain;
	}
};

/* Bundle/Icon information */

type 'BbHW' as 'STR ';

resource 'BbHW' (0) {
	"Bumbershoot Software Hello World Application"
};

resource 'BNDL' (128) {
	'BbHW', 0,
	{
		'ICN#', { 0, 128 },
		'FREF', { 0, 128 }
	}
};

resource 'FREF' (128) {
	'APPL', 0, ""
};
