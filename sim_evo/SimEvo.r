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

/*
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
*/

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
