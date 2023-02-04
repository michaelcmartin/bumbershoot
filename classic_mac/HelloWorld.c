#include <Types.h>
#include <Quickdraw.h>
#include <Windows.h>
#include <Dialogs.h>
#include <TextEdit.h>

/* The qd global has been removed from the libraries */
QDGlobals qd;

void main (void)
{
	WindowPtr wnd;
	Rect windowRect;
	short fontNumber;

	InitGraf(&qd.thePort);
	InitFonts();
	InitWindows();
	InitMenus();
	TEInit();
	InitDialogs(nil);
	InitCursor();

	windowRect.left = 10;
	windowRect.top = 40;
	windowRect.right = 310;
	windowRect.bottom = 240;

	wnd = NewCWindow(nil, &windowRect, "\pHello, World", true,
			noGrowDocProc, (WindowPtr)-1L, true, 0);

	SetPort(wnd);
	GetFNum("\pChicago", &fontNumber);
	TextFont(fontNumber);
	TextSize(12);
	MoveTo(10, 12);
	DrawString("\pHello, World, from Bumbershoot Software!");

	do {
		SystemTask();
	} while (!Button());

	DisposeWindow(wnd);
}

