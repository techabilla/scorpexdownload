/*

    Change History

    0.1     Initial version.
    0.2     Commented out all OutputDebug statements
            Change all Win... commands to use AR_Group
    0.3     Added code to update chorus_position based on dialog control


    Known Issues

    Improvements

    * Move parameters to INI file
    * Remember parameters on a per-filename basis

*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Set initial parameters / declare globals

; The offset of the chorus - this is to allow for chord charts with URLs in the title block that Acrobat turns into 'focussable' links
chorus_position := 1

; Number of seconds before scrolling begins, after it is activated.
scroll_delay := 5

; Default scroll speed.
default_scroll_speed := 2

default_zoom_level := 100
gui_hidden_opacity := 25

scroll_speed := default_scroll_speed
scroll_state := 0

; Set global options
ini_file := A_ScriptDir . "\PDFUTIL.INI"

AR_TitleStringRemove := "- Adobe Reader"
SetKeyDelay, 5
DetectHiddenWindows,On
GroupAdd, AR_Group, ahk_class AcrobatSDIWindow

; Build the GUI
Gui, +AlwaysOnTop +SysMenu +Owner +LastFound +ToolWindow
hwnd:=WinExist()
WinSet,Trans,%gui_hidden_opacity%,ahk_id %hwnd%
Gui, Margin, 2, 4
Gui, Add, Text, , Chorus
Gui, Add, Edit, vgui_chorus_position ggui_chorus_position_change Limit1 -Multi Number w45, %chorus_position%
Gui, Add, UpDown, vgui_updown_chorus_pos range1-8, %chorus_position%
Gui, Add, Text, vGuiText, Status: n/a
Gui, Add, Button, W50 H50, Jump
Gui, Add, Text, , scroll spd
Gui, Add, Edit, vgui_scroll_speed ggui_scroll_speed_change Limit1 -Multi Number w45, %scroll_speed%
Gui, Add, UpDown, vgui_updown_scroll_speed range0-9, %scroll_speed%
Gui, Add, Text, , scrl delay
Gui, Add, Edit, vgui_scroll_delay ggui_scroll_delay_change Limit5 -Multi Number w45, %scroll_delay%
Gui, Add, UpDown, vgui_updown_scroll_delay range0-60, %scroll_delay%
Gui, Add, Button, W50 H50 gButtonScroll, Auto Scroll
Gui, Add, Button, W50 H50 gButton1, >
Gui, Add, Button, W50 H50 gButton2, >>
Gui, Add, Button, W50 H50 gButton3, >>>
Gui, Add, Text, , Zoom
; Gui, Add, Edit, Vgui_zoom_level Limit4 -Multi Number w45, %default_zoom_level%
Gui, Add, DropDownList, vgui_zoom_level ggui_zoom_level_change W50 choose5, 50|75|80|90|100|110|120|130|140|150|160|170|180
Gui, Add, Button, W50 H50 gButtonFullScreen, Full Screen
Gui, Add, Button, W50 H50 gButtonReset, Reset
Gui, Add, Button, W50 H50 gButtonEsc, Escape
Gui, Add, Button, W50 H50 gButtonTest, Test

Gui, Show, X2 Y100 NoActivate, PDF

OnMessage(0x200,"WM_MOUSEFIRST")
OnMessage(0x2A2,"WM_NCMOUSELEAVE")

sleep, 500

; Apply initial parameters
gosub, ButtonReset

; Limit hotkey actions to Acrobat Reader window
#IfWinActive, ahk_group AR_Group

space::

    Gosub, DoJump

return

/*
escape::

    Gosub, ButtonReset

Return
*/

DoJump:

    if ( current_position = chorus_position )
    {
        send,{F5}
        loop, % next_verse_position
            send,{tab}
        current_position := next_verse_position
        next_verse_position := next_verse_position + 1

        Gosub,UpdateUI

        return
    }

    ; jump to chorus
    send, {F5}
    loop, % chorus_position
        send, {tab}
    current_position := chorus_position
    
    Gosub, UpdateUI

return

ButtonReset:

    ;OutputDebug, ButtonReset ENTRY scroll_delay=%scroll_delay%

    ; reset current_position so that next jump will be to the Chorus
    current_position := 0
    next_verse_position := chorus_position + 1

    ; initial scroll speed
    scroll_speed := 2
    ; scroll_delay := 5

    ; send ctl-end, ctrl-home to Acrobat, to stop scrolling

    WinActivate, ahk_group AR_Group
    send, ^{end}^{end}^{end}{PgDn}{PgDn}
    sleep, 250
    send, ^{home}
    scroll_state := 0

    gosub, UpdateUI

    ;OutputDebug, ButtonReset EXIT scroll_delay=%scroll_delay%

return

UpdateUI:

    ;OutputDebug, UpdateUI ENTRY scroll_speed=%scroll_speed%; scroll_delay=%scroll_delay%

    if ( current_position = chorus_position )
    {
        GuiControl, , GuiText, Next: V%next_verse_position%
    } else {
        GuiControl, , GuiText, Next: C
    }

    GuiControl, , gui_chorus_position, %chorus_position%
    GuiControl, , gui_scroll_speed, %scroll_speed%
    GuiControl, , gui_scroll_delay, %scroll_delay%

    ;OutputDebug, UpdateUI EXIT scroll_speed=%scroll_speed%; scroll_delay=%scroll_delay%

return

ButtonScroll:

    if ( scroll_state = 1 )
    {
        WinActivate, ahk_group AR_Group
        send, ^+h
        scroll_state := 0

    } else {

        WinActivate, ahk_group AR_Group

        if ( scroll_delay > 0 )
            sleep, % scroll_delay * 1000

        send, ^+h
        send, %scroll_speed%
        scroll_state := 1

    }

return

ButtonJump:

    WinActivate, ahk_group AR_Group
    
    gosub, DoJump

return

SendScrollSpeed:

    WinActivate, ahk_group AR_Group
    send, %scroll_speed%

return

Button1:

    scroll_speed := 1
    gosub,UpdateUI
    gosub,SendScrollSpeed

return

Button2:

    scroll_speed := 2
    gosub,UpdateUI
    gosub,SendScrollSpeed

return

Button3:

    scroll_speed := 3
    gosub,UpdateUI
    gosub,SendScrollSpeed

return

ButtonFullScreen:
    
    GuiControlGet, zoom_level, , gui_zoom_level
    
    ; Activate Acrobate Reader
    WinActivate, ahk_group AR_Group
    send, ^y
    WinWait, Zoom To
    ControlSetText, Edit1, %zoom_level%, Zoom To
    ControlClick, OK, Zoom To, , , 2
    WinActivate, ahk_group AR_Group
    send, ^l

    ; re-ativate gui to bring it back to the top
    WinActivate, ahk_class AutoHotkeyGUI

return

gui_chorus_position_change:

    GuiControlGet, chorus_position, , gui_chorus_position

return

gui_scroll_delay_change:

    ;OutputDebug, gui_scroll_delay_change ENTRY scroll_delay=%scroll_delay%

    GuiControlGet, scroll_delay, , gui_scroll_delay

    ;OutputDebug, gui_scroll_delay_change EXIT scroll_delay=%scroll_delay%

return

Gui_Scroll_Speed_Change:

    ;OutputDebug, Gui_Scroll_Speed_Change ENTRY scroll_speed = %scroll_speed%

    GuiControlGet, new_scroll_speed, , gui_scroll_speed
    
    if ( new_scroll_speed <> scroll_speed )
    {
        scroll_speed := new_scroll_speed
        gosub, SendScrollSpeed
    }

    ;OutputDebug, Gui_Scroll_Speed_Change EXIT scroll_speed = %scroll_speed%

return

gui_zoom_level_change:

    GuiControlGet, new_zoom_level, ,  gui_zoom_level

    OutputDebug, gui_zoom_level_change new zoom level = %new_zoom_level%

return

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

    WinSet,Trans,%gui_hidden_opacity%,ahk_id %hwnd%

Return

GuiClose:

    ExitApp

return

ButtonTest:
{
    t := GetPdfName()
    MsgBox,% t
}

GetPdfName()
{

    OutputDebug, Title = 'GetPdfName ENTRY'
    
    global AR_TitleStringRemove

    WinGetTitle, result, ahk_group AR_Group

    if ( StrLen(result) > 0 )
    {
        ; need to split off the ' - Adobe Reader' part of the title, to return the filename
        result := StrReplace( result, AR_TitleStringRemove, "" )

        ; strip any leading or trailing spaces
        result := trim( result, " " )

    }

    return result

}

ButtonEsc:

    WinActivate, ahk_group AR_Group

    send,{escape}

return