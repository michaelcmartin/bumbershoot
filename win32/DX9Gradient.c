#include <windows.h>
#include <tchar.h>

#define PIXMAP_WIDTH 640
#define PIXMAP_HEIGHT 480

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);

int APIENTRY
_tWinMain(HINSTANCE hInstance, HINSTANCE ignored, LPTSTR cmdLine, int nCmdShow)
{
	WNDCLASSEX wc;
	ZeroMemory(&wc, sizeof(WNDCLASSEX));
	wc.cbSize = sizeof(WNDCLASSEX);
	wc.style = CS_HREDRAW | CS_VREDRAW;
	wc.lpfnWndProc = WindowProc;
	wc.hInstance = hInstance;
	wc.hCursor = LoadCursor(NULL, IDC_ARROW);
	wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
	wc.lpszClassName = _T("DX9Pixmap");
	RegisterClassEx(&wc);

	RECT winRect;
	winRect.left = 0;
	winRect.top = 0;
	winRect.right = PIXMAP_WIDTH;
	winRect.bottom = PIXMAP_HEIGHT;
	AdjustWindowRect(&winRect, WS_OVERLAPPEDWINDOW, FALSE);

	HWND hWnd = CreateWindow(_T("DX9Pixmap"), _T("DX9 Pixmap Shell"),
			WS_OVERLAPPEDWINDOW,
			0, 0,
			winRect.right - winRect.left, winRect.bottom - winRect.top,
			NULL, NULL, hInstance, NULL);
	ShowWindow(hWnd, SW_SHOWDEFAULT);

	MSG msg;
	do {
		if (GetMessage(&msg, NULL, 0, 0) < 0) {
			break;
		}
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	} while (msg.message != WM_QUIT);
	return (int)msg.wParam;
}

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message) {
	case WM_CLOSE:
	case WM_DESTROY:
		PostQuitMessage(0);
		return 0;
	default:
		break;
	}
	return DefWindowProc(hWnd, message, wParam, lParam);
}
