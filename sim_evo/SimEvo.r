#include "Types.r"
#include "SysTypes.r"
#include "SimEvoResources.h"

/* Menu-related resources. Constants are defined in HelloWorld.h. */

resource 'MBAR' (rMenuBar, preload) {
	{ mApple, mFile, mEdit, mSettings };
};

resource 'MENU' (mApple, preload) {
	mApple, textMenuProc,
	0b1111111111111111111111111111101, /* disable dashed line, */
	enabled, apple, /* enable About and DAs */
	{
		"About Simulated Evolution…",
			noicon, nokey, nomark, plain;
		"-",
			noicon, nokey, nomark, plain
	}
};

resource 'MENU' (mFile, preload) {
	mFile, textMenuProc,
	0b1111111111111111111111111101000, /* Enable only Quit */
	enabled, "File",
	{
		"New",
			noicon, "N", nomark, plain;
		"New From Seed…",
			noicon, nokey, nomark, plain;
		"-",
			noicon, nokey, nomark, plain;
		"Close",
			noicon, "W", nomark, plain;
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

resource 'MENU' (mSettings, preload) {
	mSettings, textMenuProc,
	0b11111111111111111111111111111111,
	enabled, "Settings",
	{
		"Paused",
			noicon, "P", nomark, plain;
		"Color",
			noicon, nokey, nomark, plain;
		"Garden of Eden",
			noicon, nokey, nomark, plain;
		"Warp Mode",
			noicon, nokey, nomark, plain;
	}
};

/* About dialog, adapted shamelessly from the MPW Sample Application */

resource 'ALRT' (rAboutAlert, purgeable) {
	{40, 20, 160, 310},
	rAboutAlert,
	{
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent
	},
	centerMainScreen
};

resource 'DITL' (rAboutAlert, purgeable) {
	{
		/* [1] */
		{88, 198, 108, 278},
		Button {
			enabled,
			"OK"
		},
		/* [2] */
		{8, 8, 24, 214},
		StaticText {
			disabled,
			"Simulated Evolution"
		},
		/* [3] */
		{32, 8, 48, 309},
		StaticText {
			disabled,
			"Copyright © Bumbershoot Software 2023"
		},
	}
};

resource 'DLOG' (rNewFrom, "New From Seed…") {
	{ 40, 40, 125, 340 },
	dboxProc, invisible, noGoAway, 0x0, rNewFrom, "New From Seed", centerMainScreen
};

resource 'DITL' (rNewFrom, purgeable) {
	{
		/* [1] */
		{ 52, 207, 72, 287 },
		Button {
			Enabled, "OK"
		},
		/* [2] */
		{ 52, 114, 72, 194 },
		Button {
			Enabled, "Cancel"
		},
		/* [3] */
		{ 13, 13, 29, 128 },
		StaticText {
			disabled,
			"Simulation Seed:"
		},
		/* [4] */
		{ 13, 141, 29, 287 },
		EditText {
			enabled, ""
		},
	}
};

/* Bundle/Icon information */

data 'ICN#' (128) {
	$"0007 E000 0018 1800 0010 0800 0018 1800"
	$"0017 E800 0010 0800 0010 0800 0010 0800"
	$"0010 0800 0010 0800 0010 0800 0010 0800"
	$"0020 0400 0040 0200 0040 0200 00BF FF00"
	$"01FF FF80 01DD DD80 02BF FEC0 0355 5540"
	$"06AA AAA0 0D55 5550 0AAA AAB0 1555 5558"
	$"2AAA AAAC 3555 5554 6BFF FFEA FF77 777F"
	$"FFFF FFFF DDDD DDDD 7FFF FFFE 03FF FFC0"
	$"0007 E000 001F F800 001F F800 001F F800"
	$"001F F800 001F F800 001F F800 001F F800"
	$"001F F800 001F F800 001F F800 001F F800"
	$"003F FC00 007F FE00 007F FE00 00FF FF00"
	$"01FF FF80 01FF FF80 03FF FFC0 03FF FFC0"
	$"07FF FFE0 0FFF FFF0 0FFF FFF0 1FFF FFF8"
	$"3FFF FFFC 3FFF FFFC 7FFF FFFE FFFF FFFF"
	$"FFFF FFFF FFFF FFFF 7FFF FFFE 03FF FFC0"
};

data 'icl4' (128) {
	$"0000 0000 0000 0FFF FFF0 0000 0000 0000"
	$"0000 0000 000F F000 000F F000 0000 0000"
	$"0000 0000 000F 0000 0000 F000 0000 0000"
	$"0000 0000 000F F000 000F F000 0000 0000"
	$"0000 0000 000F 0FFF FFF0 F000 0000 0000"
	$"0000 0000 000F 0000 0000 F000 0000 0000"
	$"0000 0000 000F 0000 0000 F000 0000 0000"
	$"0000 0000 000F 0000 0000 F000 0000 0000"
	$"0000 0000 000F 0000 0000 F000 0000 0000"
	$"0000 0000 000F 0000 0000 F000 0000 0000"
	$"0000 0000 000F 0000 0000 F000 0000 0000"
	$"0000 0000 000F 0000 0000 F000 0000 0000"
	$"0000 0000 00F0 0000 0000 0F00 0000 0000"
	$"0000 0000 0F00 0000 0000 00F0 0000 0000"
	$"0000 0000 0F66 6666 6666 60F0 0000 0000"
	$"0000 0000 6666 0666 0666 066F 0000 0000"
	$"0000 0006 6666 6666 6666 6666 F000 0000"
	$"0000 000F 6606 6606 6606 6667 F000 0000"
	$"0000 00F7 7766 6666 6666 6777 7F00 0000"
	$"0000 00F7 7707 7777 7777 7707 7F00 0000"
	$"0000 0F77 7777 7777 0777 7777 77F0 0000"
	$"0000 F777 7777 7707 7707 7777 777F 0000"
	$"0000 F777 0777 7777 7777 7777 077F 0000"
	$"000F 7777 7777 7077 7777 7777 777F F000"
	$"00F7 7777 7777 7777 7077 7707 7777 FF00"
	$"00F7 7077 7707 7777 7777 7777 7777 7F00"
	$"0F77 7766 6666 6666 6666 6666 6667 77F0"
	$"F666 6666 6666 6666 6660 6666 6666 666F"
	$"F666 6066 6666 6660 6666 6666 6066 606F"
	$"FF66 6666 6666 6666 6666 6606 6666 666F"
	$"0F6F FFF6 6606 6666 6066 6666 66FF FFF0"
	$"0000 00FF FFFF FFFF FFFF FFFF FF00 0000"
};

type 'BbSE' as 'STR ';

resource 'BbSE' (0) {
	"Simulated Evolution"
};

resource 'BNDL' (128) {
	'BbSE', 0,
	{
		'ICN#', { 0, 128 },
		'FREF', { 0, 128 }
	}
};

resource 'FREF' (128) {
	'APPL', 0, ""
};

/* System 7 information */

resource 'SIZE' (-1) {
	dontSaveScreen,
	acceptSuspendResumeEvents,
	enableOptionSwitch,
	canBackground,
	multiFinderAware,
	backgroundAndForeground,
	dontGetFrontClicks,
	ignoreChildDiedEvents,
	not32BitCompatible,
	reserved,
	reserved,
	reserved,
	reserved,
	reserved,
	reserved,
	reserved,
	131072,
	131072
};
