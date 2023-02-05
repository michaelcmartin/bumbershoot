#include <Types.h>
#include <ToolUtils.h>
#include <Quickdraw.h>
#include <Windows.h>
#include <Dialogs.h>
#include <TextEdit.h>
#include <Menus.h>
#include <Devices.h>

#include "HelloWorld.h"

/* The qd global has been removed from the libraries */
QDGlobals qd;

int HandleMenuEvent(WindowPtr window, long event)
{
	int item = LoWord(event);
	int menu = HiWord(event);
	InitCursor();
	switch (menu) {
	case mApple:
		if (item == 1) {
			/* Do the About Dialog, eventually */
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
		SystemTask();
		GetNextEvent(everyEvent, &myEvent);
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
			break;
		}
	}

	DisposeWindow(wnd);
}
