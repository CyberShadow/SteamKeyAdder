module steamkeyadder;

import std.exception;
import std.string;
import std.stdio;

import ae.sys.windows;
import ae.sys.clipboard;
import win32.windows;

enum GAMES_X = 163;
enum GAMES_Y =  16;

void click(HWND hwnd, uint x, uint y)
{
	POINT point;
	GetCursorPos(&point);
	scope(exit) SetCursorPos(point.x, point.y);

	RECT rect;
	GetWindowRect(hwnd, &rect);
	SetCursorPos(rect.left+x, rect.top+y);
	Sleep(100);
	SendMessage(hwnd, WM_LBUTTONDOWN, 0, 0);
	Sleep(100);
	SendMessage(hwnd, WM_LBUTTONUP  , 0, 0);
	Sleep(100);
}

string tryGetClipboardText()
{
	try
		return getClipboardText().strip();
	catch
		return null;
}

void main()
{
	string last = tryGetClipboardText();
	writeln("Make sure the Steam window is visible and unobscured.");
	writeln("Copy a key to the clipboard to add it to Steam.");
	while (true)
	{
		auto curr = tryGetClipboardText();
		if (curr && curr != last)
		{
			if (looksLikeAKey(curr))
			{
				writeln("Adding key: ", curr);
				addKey();
			}
			else
				writeln("Ignoring clipboard text - doesn't look like a Steam key");
		}
		last = curr;
		Sleep(100);
	}
}

bool looksLikeAKey(string s)
{
	bool[256] chars;
	foreach (c; '0'..'9'+1) chars[c] = true;
	foreach (c; 'A'..'Z'+1) chars[c] = true;
	chars['-'] = true;

	if (s.length <= 8 || s.length >= 40)
		return false;
	foreach (char c; s)
		if (!chars[c])
			return false;
	return true;
}

/// Adds key from clipboard.
void addKey()
{
	HWND steamMain;

	bool[void*] oldWindows;
	foreach (h; windowIterator(null, null))
		if (IsWindowVisible(h))
		{
			oldWindows[h] = true;
			if (h.getWindowText() == "Steam" && h.getClassName().startsWith("USurface_"))
				steamMain = h;
		}

	enforce(steamMain, "Can't find Steam window");
	click(steamMain, GAMES_X, GAMES_Y);

	HWND menu;
	foreach (h; windowIterator(null, null))
		if (IsWindowVisible(h) && h !in oldWindows && h.getClassName().startsWith("USurfaceShadowed_"))
			menu = h;
	enforce(menu, "Can't find menu");

	click(menu, 35, 35);

	HWND dialog;
	foreach (h; windowIterator(null, null))
		if (IsWindowVisible(h) && h !in oldWindows && h.getWindowText() == "Product Activation" && h.getClassName().startsWith("USurface_"))
			dialog = h;
	enforce(dialog, "Can't find dialog");
	forceSetForegroundWindow(dialog);

	Sleep(100);
	pressOn(dialog, 13);
	Sleep(100);
	pressOn(dialog, 13);
	Sleep(100);

	keyDown(VK_SHIFT);
	Sleep(50);
	pressOn(dialog, VK_INSERT);
	Sleep(50);
	keyUp(VK_SHIFT);

	pressOn(dialog, 13);
	Sleep(100);

	HWND working;
	foreach (h; windowIterator(null, null))
		if (IsWindowVisible(h) && h !in oldWindows && h.getWindowText() == "Steam - Working" && h.getClassName().startsWith("USurface_"))
			working = h;
	enforce(working, "Can't find working dialog");

	writeln("Waiting...");
	while (IsWindow(working) && IsWindowVisible(working)) Sleep(100);
	writeln("Done.");

	Sleep(1000);
	SetForegroundWindow(dialog);

	Sleep(100);
	pressOn(dialog, VK_ESCAPE);
	Sleep(100);
	pressOn(dialog, 13);
	Sleep(100);
	pressOn(dialog, VK_ESCAPE);
}

void forceSetForegroundWindow(HWND hWnd)
{
	if(!IsWindow(hWnd)) return;

	BYTE[256] keyState;
	//to unlock SetForegroundWindow we need to imitate Alt pressing
	if (GetKeyboardState(keyState.ptr))
	{
		if (!(keyState[VK_MENU] & 0x80))
		{
			keybd_event(VK_MENU, 0, KEYEVENTF_EXTENDEDKEY | 0, 0);
		}
	}

	SetForegroundWindow(hWnd);

	if (GetKeyboardState(keyState.ptr))
	{
		if (!(keyState[VK_MENU] & 0x80))
		{
			keybd_event(VK_MENU, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
		}
	}
}
