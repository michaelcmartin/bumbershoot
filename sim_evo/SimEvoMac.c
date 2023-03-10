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

Handle EvoState;

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
	CheckItem(menu, iGarden, useGarden);
	DisableItem(menu, iWarp);  /* Until we implement it */

	menu = GetMenuHandle(mFile);
	DisableItem(menu, iClose);  /* Until we implement New and Close */
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
	hasColor = environ.hasColorQD; /* This isn't correct, but it will do for now */
	useColor = hasColor;
	useGarden = 1;
}

static void InitSimulation(unsigned long seed)
{
	evo_state_t *state;
	XSSSeedRandom(seed);
	HLock(EvoState);
	state = (evo_state_t *)(*EvoState);
	initialize(state);
	HUnlock(EvoState);
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
		if (item == iQuit) {
			HiliteMenu(0);
			ExitToShell();
		}
		break;
	case mSettings:
		if (item == iColor) {
			useColor = !useColor;
			SetPort(window);
			RedrawWorld(window);
		}
		if (item == iGarden) {
			useGarden = !useGarden;
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
	UInt32 lastUpdate;

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

	EvoState = NewHandleClear(sizeof(evo_state_t));
	SetPort(wnd);
	ClearWindow(wnd);
	GetDateTime(&seed);
	InitSimulation(seed);
	lastUpdate = LMGetTicks();

	while (!done) {
		if (hasWNEvent) {
			if (!WaitNextEvent(everyEvent, &myEvent, 1, nil)) {
				if (LMGetTicks() != lastUpdate) {
					evo_state_t *state;
					lastUpdate = LMGetTicks();
					HLock(EvoState);
					state = (evo_state_t *)(*EvoState);
					run_cycle(state);
					seed_garden(state);
					HUnlock(EvoState);
				}
				continue;
			}
		} else {
			SystemTask();
			if (!GetNextEvent(everyEvent, &myEvent)) {
				continue;
			}
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
				DragWindow(clickWnd, myEvent.where, &dragRect);
				break;
			case inGoAway:
				if (TrackGoAway(clickWnd, myEvent.where)) {
					done = 1;
				}
				break;
			case inMenuBar:
				PrepareMenus();
				HandleMenuEvent(wnd, MenuSelect(myEvent.where));
				break;
			default:
				break;
			}
			break;
		case keyDown:
			if (myEvent.modifiers & cmdKey) {
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
