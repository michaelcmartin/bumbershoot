#include <Types.h>
#include <ToolUtils.h>
#include <Quickdraw.h>
#include <Windows.h>
#include <Dialogs.h>
#include <TextEdit.h>
#include <Menus.h>
#include <Devices.h>
#include <Sound.h>
#include <Traps.h>

#include <limits.h>
#include "HelloWorld.h"

QDGlobals qd;
SysEnvRec environ;
int hasWNEvent;

int TrapAvailable(short tNumber, TrapType tType)
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

int HandleMenuEvent(WindowPtr window, long event)
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
			return 1;
		}
		break;
	default:
		break;
	}
	HiliteMenu(0);
	return 0;
}

void main (void)
{
	WindowPtr wnd, clickWnd;
	MenuBarHandle mbar;
	Rect windowRect, dragRect;
	short fontNumber;
	EventRecord myEvent;
	int done = 0;
	int clickLoc = 0;

	InitGraf(&qd.thePort);
	InitFonts();
	InitWindows();
	InitMenus();
	TEInit();
	InitDialogs(nil);
	InitCursor();

	SysEnvirons(1, &environ);
	if (environ.machineType < 0) {
		/* We're a Mac 128K, 512K, or XL; we need to at least be a 512Ke to run */
		SysBeep(60);
		return;
	}

	hasWNEvent = TrapAvailable(_WaitNextEvent, ToolTrap);

	SetRect(&windowRect, 10, 40, 310, 240);
	SetRect(&dragRect, -32767, -32767, 32767, 32767);

	mbar = GetNewMBar(rMenuBar);
	SetMenuBar(mbar);
	DisposeHandle(mbar);
	AppendResMenu(GetMenuHandle(mApple), 'DRVR'); /* Add DeskAccs to Apple menu */
	DrawMenuBar();

	wnd = NewWindow(nil, &windowRect, "\pHello, World", true,
			noGrowDocProc, (WindowPtr)-1L, true, 0);

	while (!done) {
		if (hasWNEvent) {
			if (!WaitNextEvent(everyEvent, &myEvent, LONG_MAX, nil)) {
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
				done = HandleMenuEvent(wnd, MenuSelect(myEvent.where));
				break;
			default:
				break;
			}
			break;
		case keyDown:
			if (myEvent.modifiers & cmdKey) {
				done = HandleMenuEvent(wnd, MenuKey(myEvent.message & charCodeMask));
			}
			break;
		case updateEvt:
			SetPort(wnd);
			BeginUpdate(wnd);
			GetFNum("\pChicago", &fontNumber);
			TextFont(fontNumber);
			TextSize(12);
			MoveTo(10, 12);
			EraseRect(&wnd->portRect);
			DrawString("\pHello, World, from Bumbershoot Software!");
			EndUpdate(wnd);
			break;
		default:
			/* We'd catch kOSEvent and look for kSuspendResumeMessage, but we
			   don't actually do anything exciting on activation, so it's a no-op
			   for us */
			break;
		}
	}

	DisposeWindow(wnd);
}
