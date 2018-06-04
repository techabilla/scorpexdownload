DetectHiddenWindows,On

Gui,+LastFound

hwnd:=WinExist()

WinSet,Trans,20,ahk_id %hwnd%

gui,Show,w100 h100

OnMessage(0x200,"WM_MOUSEFIRST")

OnMessage(0x2A2,"WM_NCMOUSELEAVE")

Return

GuiClose:

ExitApp

WM_MOUSEFIRST(w,l,m){

	global

	WinSet,Trans,Off,ahk_id %hwnd%

	SetTimer,Hide

}

Hide:

MouseGetPos,,,win

If (win=hwnd)

	return

SetTimer,Hide,Off

WinSet,Trans,20,ahk_id %hwnd%

Return