#include <Types.h>
#include <Quickdraw.h>
#include <Windows.h>
#include <Dialogs.h>
#include <TextEdit.h>

/* The qd global has been removed from the libraries */
QDGlobals qd;

void main (void)
{
	WindowPtr wnd, clickWnd;
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
			default:
				break;
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
