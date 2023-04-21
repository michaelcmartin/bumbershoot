#include <Types.h>
#include <ToolUtils.h>
#include <Quickdraw.h>
#include <Windows.h>
#include <Dialogs.h>
#include <TextEdit.h>
#include <Menus.h>
#include <Devices.h>
#include <Traps.h>
#include <DateTimeUtils.h>
#include <LowMem.h>

#include "SimEvoResources.h"
#include "SimEvo.h"

extern pascal void XSSSeedRandom(unsigned long seed);
extern pascal unsigned long XSSRandom(void);

QDGlobals qd;
SysEnvRec environ;

int hasWNEvent;
int hasColor;
int useColor;
int useGarden;
int warpMode;
int simActive;
int simPaused;
UInt32 lastUpdate;

Handle EvoState;
DialogPtr seedDialog;

/* Implementations of the core simulation callbacks. */
/* WARNING 1: EvoState must be HLocked before calling anything that calls these! */
/* WARNING 2: The graphics port must be set before calling anything that calls these! */

void report_bug(const evo_state_t *state, int bug_num, const char *action)
{
	/* This is a no-op */
	(void) state;
	(void) bug_num;
	(void) action;
}

void report_birth(const evo_state_t *state, int parent, int child_1, int child_2)
{
	/* This is a no-op */
	(void) state;
	(void) parent;
	(void) child_1;
	(void) child_2;
}

void erase_bug(int x, int y)
{
	Rect r;
	SetRect(&r, x << 1, y << 1, (x << 1) + 6, (y << 1) + 6);
	EraseRect(&r);
}

void draw_bug(int x, int y)
{
	Rect r;
	SetRect(&r, x << 1, y << 1, (x << 1) + 6, (y << 1) + 6);
	if (useColor) {
		ForeColor(whiteColor);
	}
	FillRect(&r, &qd.black);
}

void draw_plankton(int x, int y)
{
	Rect r;
	SetRect(&r, x << 1, y << 1, (x << 1) + 2, (y << 1) + 2);
	if (useColor) {
		ForeColor(greenColor);
		FillRect(&r, &qd.black);
	} else {
		FillRect(&r, &qd.gray);
	}
}

unsigned long rand_int(unsigned long range)
{
	return XSSRandom() % range;
}

/**********************************************************************/

static void ClearWindow(WindowPtr wnd)
{
	if (useColor) {
		BackColor(blueColor);
	} else {
		ForeColor(blackColor);
		BackColor(whiteColor);
	}
	EraseRect(&wnd->portRect);
}

/* Redraw over all the bugs so they don't partially erase each other for long */
static void FixBugs(WindowPtr wnd)
{
	int i;
	evo_state_t *state;
	if (simActive) {
		SetPort(wnd);
		HLock(EvoState);
		state = (evo_state_t *)(*EvoState);
		for (i = 0; i < state->num_bugs; ++i) {
			draw_bug(state->bugs[i].x, state->bugs[i].y);
		}
		HUnlock(EvoState);
	}
}

static void AppendULong(unsigned long val, StringPtr str)
{
	unsigned char buf[16];
	unsigned char n, dest;
	n = 0;
	dest = str[0] + 1;
	do {
		buf[n++] = val % 10;
		val /= 10;
	} while ((val > 0) && (n < 16));
	do {
		str[dest++] = buf[--n] + '0';
	} while (n > 0);
	str[0] = dest - 1;
}

static unsigned long StrToULong(StringPtr str)
{
	unsigned long result = 0;
	unsigned char i;
	for (i = 1; i <= str[0]; ++i) {
		if (str[i] >= '0' && str[i] <= '9') {
			result *= 10;
			result += str[i]-'0';
		}
	}
	return result;
}

static void StrCopy(StringPtr dest, StringPtr src)
{
	unsigned char i;
	for (i = 0; i <= src[0]; ++i) {
		dest[i] = src[i];
	}
}

static void PrepareMenus(void)
{
	MenuHandle menu;
	menu = GetMenuHandle(mSettings);
	if (hasColor) {
		EnableItem(menu, iColor);
		CheckItem(menu, iColor, useColor);
	} else {
		DisableItem(menu, iColor);
		CheckItem(menu, iColor, 0);
	}
	CheckItem(menu, iPaused, simPaused);
	CheckItem(menu, iGarden, useGarden);
	CheckItem(menu, iWarp, warpMode);

	menu = GetMenuHandle(mFile);
	if (simActive) {
		DisableItem(menu, iNew);
		DisableItem(menu, iNewFrom);
		EnableItem(menu, iClose);
	} else {
		EnableItem(menu, iNew);
		EnableItem(menu, iNewFrom);
		DisableItem(menu, iClose);
	}
}

static int TrapAvailable(short tNumber, TrapType tType)
{
	if ((tType == ToolTrap) &&
		(environ.machineType > envMachUnknown) &&
		(environ.machineType < envMacII)) {	/* 512KE, Plus, or SE */
		tNumber = tNumber & 0x3FF;
		if (tNumber > 0x01FF) {				/* which means the tool traps */
			tNumber = _Unimplemented;		/* only go to 0x01FF */
		}
	}
	return NGetTrapAddress(tNumber, tType) != NGetTrapAddress(_Unimplemented, ToolTrap);
}

static void DetectCapabilities(void)
{
	SysEnvirons(1, &environ);
	if (environ.machineType < 0) {
		hasWNEvent = 0;
		hasColor = 0;
		useColor = 0;
		return;
	}

	hasWNEvent = TrapAvailable(_WaitNextEvent, ToolTrap);
	if (!environ.hasColorQD) {
		/* If we don't have Color QuickDraw, we *definitely* don't have a color screen */
		hasColor = 0;
	} else {
		hasColor = TestDeviceAttribute(GetMainDevice(), gdDevType);
	}
	useColor = hasColor;
	useGarden = 1;
	warpMode = 0;
	simPaused = 0;
}

static void InitSimulation(WindowPtr wnd, unsigned long seed)
{
	evo_state_t *state;
	Str255 titleStr;

	ClearWindow(wnd);
	XSSSeedRandom(seed);
	HLock(EvoState);
	state = (evo_state_t *)(*EvoState);
	initialize(state);
	HUnlock(EvoState);
	simActive = 1;
	lastUpdate = LMGetTicks();
	StrCopy(titleStr, "\pSimulated Evolution #");
	AppendULong(seed, titleStr);
	SetWTitle(wnd, titleStr);
}

static void RedrawWorld(WindowPtr wnd)
{
	int x, y, i;
	evo_state_t *state;
	ClearWindow(wnd);
	HLock(EvoState);
	state = (evo_state_t *)(*EvoState);
	i = 0;
	for (y = 0; y < 100; ++y) {
		for (x = 0; x < 150; ++x) {
			if (state->plankton[i++]) {
				draw_plankton(x, y);
			}
		}
	}
	for (i = 0; i < state->num_bugs; ++i) {
		draw_bug(state->bugs[i].x, state->bugs[i].y);
	}
	HUnlock(EvoState);
}

static pascal Boolean SeedDialogFilter(DialogRef theDialog, EventRecord *theEvent, DialogItemIndex *itemHit)
{
	if (theEvent->what == keyDown && !(theEvent->modifiers & cmdKey)) {
		char c = theEvent->message & charCodeMask;
		if (c == 0x0D) {   /* RETURN hit? */
			if (itemHit) *itemHit = 1;   /* If so, that's ENTER */
			return TRUE;
		}
		if ((c >= 32 && c < '0') || (c > '9' && c <= 255)) {
			/* Typed a key that they shouldn't have typed */
			theEvent->message = nullEvent;
		}
	}
	(void)theDialog; /* Unused argument */
	return FALSE;
}

void HandleMenuEvent(WindowPtr window, long event)
{
	int item = LoWord(event);
	int menu = HiWord(event);
	InitCursor();
	switch (menu) {
	case mApple:
		if (item == 1) {
			Alert(rAboutAlert, nil);
		} else {
			MenuRef mRef = GetMenuHandle(mApple);
			Str255 accName;

			GetMenuItemText(mRef, item, accName);
			OpenDeskAcc(accName);
			SetPort(window);
		}
		break;
	case mFile:
		if (item == iNew) {
			unsigned long seed;
			GetDateTime(&seed);
			InitSimulation(window, seed);
			ShowWindow(window);
		}
		if (item == iNewFrom) {
			Str255 seedStr;
			unsigned long seed;
			Handle dlgItem;
			short choice, dlgItemType;
			Rect dlgItemRect;
			GetDateTime(&seed);
			seedStr[0] = 0;
			AppendULong(seed, seedStr);
			SetPort(seedDialog);
			ForeColor(blackColor);
			BackColor(whiteColor);
			GetDialogItem(seedDialog, 4, &dlgItemType, &dlgItem, &dlgItemRect);
			SetDialogItemText(dlgItem, seedStr);
			SelectDialogItemText(seedDialog, 4, 0, 32767);
			ShowWindow(seedDialog);
			SelectWindow(seedDialog);
			GetDialogItem(seedDialog, 1, &dlgItemType, &dlgItem, &dlgItemRect);
			PenSize(3,3);
			InsetRect(&dlgItemRect, -4, -4);
			FrameRoundRect(&dlgItemRect, 16, 16);
			PenSize(1,1);
			do {
				ModalDialog(SeedDialogFilter, &choice);
			} while (choice != 1 & choice != 2);
			HideWindow(seedDialog);
			if (choice == 1) {
				GetDialogItem(seedDialog, 4, &dlgItemType, &dlgItem, &dlgItemRect);
				GetDialogItemText(dlgItem, seedStr);
				seed = StrToULong(seedStr);
				InitSimulation(window, seed);
				ShowWindow(window);
			}
		}
		if (item == iClose) {
			simActive = 0;
			HideWindow(window);
		}
		if (item == iQuit) {
			HiliteMenu(0);
			ExitToShell();
		}
		break;
	case mSettings:
		if (item == iPaused) {
			simPaused = !simPaused;
		}
		if (item == iColor) {
			useColor = !useColor;
			SetPort(window);
			RedrawWorld(window);
		}
		if (item == iGarden) {
			useGarden = !useGarden;
		}
		if (item == iWarp) {
			warpMode = !warpMode;
		}
		break;
	default:
		break;
	}
	HiliteMenu(0);
}

void main (void)
{
	WindowPtr wnd, clickWnd;
	MenuBarHandle mbar;
	Rect windowRect, dragRect;
	EventRecord myEvent;
	int done = 0;
	int clickLoc = 0;
	unsigned long seed;

	InitGraf(&qd.thePort);
	InitFonts();
	InitWindows();
	InitMenus();
	TEInit();
	InitDialogs(nil);
	InitCursor();

	DetectCapabilities();

	SetRect(&windowRect, 10, 40, 310, 240);
	SetRect(&dragRect, -32767, -32767, 32767, 32767);

	mbar = GetNewMBar(rMenuBar);
	SetMenuBar(mbar);
	DisposeHandle(mbar);
	AppendResMenu(GetMenuHandle(mApple), 'DRVR'); /* Add DeskAccs to Apple menu */
	DrawMenuBar();

	wnd = NewWindow(nil, &windowRect, "\pSimulated Evolution", true,
			noGrowDocProc, (WindowPtr)-1L, true, 0);
	seedDialog = GetNewDialog(rNewFrom, nil, nil);

	EvoState = NewHandleClear(sizeof(evo_state_t));
	SetPort(wnd);
	ClearWindow(wnd);
	GetDateTime(&seed);
	InitSimulation(wnd, seed);

	while (!done) {
		int doTick = 0;
		if (hasWNEvent) {
			int tickWait = warpMode ? 0 : (simPaused ? 1000 : 1);
			if (!WaitNextEvent(everyEvent, &myEvent, tickWait, nil)) {
				doTick = 1;
			}
		} else {
			SystemTask();
			if (!GetNextEvent(everyEvent, &myEvent)) {
				doTick = 1;
			}
		}
		if (doTick) {
			if (simActive && !simPaused && (warpMode || (LMGetTicks() != lastUpdate))) {
				do {
					evo_state_t *state;
					lastUpdate = LMGetTicks();
					HLock(EvoState);
					state = (evo_state_t *)(*EvoState);
					run_cycle(state);
					if (useGarden) {
						seed_garden(state);
					}
					HUnlock(EvoState);
				} while (warpMode && !EventAvail(everyEvent, &myEvent));
			}
			continue;
		}

		switch (myEvent.what) {
		case mouseDown:
			clickLoc = FindWindow(myEvent.where, &clickWnd);
			switch (clickLoc) {
			case inSysWindow:
				SystemClick(&myEvent, clickWnd);
				break;
			case inContent:
				if (clickWnd != FrontWindow()) {
					SelectWindow(clickWnd);
				}
				break;
			case inDrag:
				FixBugs(wnd);
				DragWindow(clickWnd, myEvent.where, &dragRect);
				break;
			case inGoAway:
				if (TrackGoAway(clickWnd, myEvent.where)) {
					simActive = 0;
					HideWindow(wnd);
				}
				break;
			case inMenuBar:
				FixBugs(wnd);
				PrepareMenus();
				HandleMenuEvent(wnd, MenuSelect(myEvent.where));
				break;
			default:
				break;
			}
			break;
		case keyDown:
			if (myEvent.modifiers & cmdKey) {
				FixBugs(wnd);
				PrepareMenus();
				HandleMenuEvent(wnd, MenuKey(myEvent.message & charCodeMask));
			}
			break;
		case updateEvt:
			SetPort(wnd);
			BeginUpdate(wnd);
			/* TODO: RedrawWorld should draw to an offscreen graphics world, and this should just blit from it as needed */
			RedrawWorld(wnd);
			EndUpdate(wnd);
			break;
		default:
			/* We'd catch kOSEvent and look for kSuspendResumeMessage, but we
			   don't actually do anything exciting on activation, so it's a no-op
			   for us */
			break;
		}
	}

	DisposeHandle(EvoState);
	DisposeWindow(wnd);
}
