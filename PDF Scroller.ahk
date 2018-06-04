#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; NB - Ensure Acrobat option 'Fill screen with one page at a time' is NOT set

; KNOWN ISSUES
; 
;   

; Global Variables - Script behaviour & user preferences

; basic zoom level to apply; 0=page, 1=actual, 2=fit width, 3=fit visible
zoom_level := 3

; if set, this overrides zoom_level  
zoom_percent := 66

; delay in milliseconds before scrolling starts after being activated
pre_scroll_delay := 2000

; 1 = switch to full screen mode; 0 = don't
full_screen_mode = 0

; target scrolling speed
scroll_speed := 2

; Global Vars - internal status

; if scroll_speed has a fractional component (e.g. 2.5), the speed will be regulated by switching between the nearest speeds that are slower and faster
; e.g. a speed of 2.8 will result in a repeating cycle of speed 3 for 800 ms then speed 2 for 200 ms.
scroll_speed_pwm := ( scroll_speed - floor(scroll_speed) ) * 1000

; keep track of current speed so that PWM can adjust accordingly
scroll_speed_current := 0

; keep track of scrolling status. Not perfect since it cannot detect actual status if overriden by user pressing CTRL-SHIFT-H, or reaching end of document.
scroll_status := 0

; record the window title when scrolling is activated; then used to prevent keypresses going to any other window
window_title := ""

; Following command prevents the hotkey assignments from firing unless the active window is the Acrobat viewer
#IfWinActive, ahk_class AcrobatSDIWindow

space::

   ; scrolling is inactive; activate full screen and scale to width of page. Start timer to begin scrolling.
   if ( scroll_status = 0 )
   {    
      TrayTip,PDF Scroll,PDF Scrolling Started,10
      WinGetTitle,window_title
      gosub, StartScroll
      new_scroll_status = 1
    }

   ; scrolling is already active; toggle scrolling.
   if (scroll_status = 1 or scroll_status = 2)
   {
      send,^+h
      new_scroll_status := 3 - scroll_status
   }

   scroll_status := new_scroll_status
   OutputDebug, Scroll Status = %scroll_status%

Return

; if user presses Escape key, toggle scrolling & full screen
esc::

   if ( scroll_speed_pwm > 0 )
      setTimer,ScrollSpeedPWM,Off

   if ( scroll_status = 1 ) 
      send,^+h

   send,{esc}

   scroll_status := 0
   OutputDebug, Scroll Status = %scroll_status%

return

up::

    if ( scroll_status = 1 ) and ( scroll_speed <= 8.5 ) 
    {
        scroll_speed := scroll_speed + 0.5
        Gosub,SetScrollSpeed
    } else {
        send,{up}
    }

return

down::

    if ( scroll_status = 1 ) and ( scroll_speed >= 0.5 )
    {
        scroll_speed := scroll_speed - 0.5
        Gosub,SetScrollSpeed
    } else {
        send,{down}
    }

return

PgUp::

    if ( scroll_status = 1 )
    {
        send,+{PgUp}
    } else {
        send,{PgUp}
    }

return

PgDn::

    if ( scroll_status = 1 )
    {
        send,{tab}
    } else {
        send,{PgDn}
    }

return

StartScroll:

    ; only called by a hot-key, so no need to check active window

    if ( full_screen_mode )
        send,^l
    
    OutputDebug,Zoom Percent = '%zoom_percent%', Zoom Level = '%zoom_level%'

    if ( zoom_percent ) 
    {

        OutputDebug, Setting zoom level %zoom_percent% percent
        send,^y%zoom_percent%{enter}

    } else {

        if ( zoom_level )
            OutputDebug, Setting zoom level %zoom_level%
            send,^%zoom_level%
    }

    ; wait for a couple of seconds 
    sleep, %pre_scroll_delay%

    ; start scrolling
    send,^+h

    ; Set the initial scroll speed
    gosub, SetScrollSpeed

return

SetScrollSpeed:

    ; NB - Assumes scrolling already active

    ; Determine if PWM control is required
    scroll_speed_pwm := ( scroll_speed - floor(scroll_speed) ) * 1000

    ; set an initial speed
    scroll_speed_current := ceil(scroll_speed)
    send,%scroll_speed_current%

    ; if scroll_speed is non-integer, enable the PWM control logic
    if scroll_speed_pwm = 0
    {
        setTimer,ScrollSpeedPWM,Off
    } else {
        setTimer,ScrollSpeedPWM,% scroll_speed_pwm
    }  

    OutputDebug, Scroll speed set to %scroll_speed%

return

ScrollSpeedPWM:

    ; Send scroll speed control buttons to regulate scroll speed when a non-integral number is specified.

    if ( WinActive(window_title) = 0 or scroll_status <> 1 ) 
        return

   new_scroll_speed := ceil(scroll_speed) - scroll_speed_current + floor(scroll_speed)
   if ( scroll_status = 1 ) 
   {
      send,%new_scroll_speed%
   }
   scroll_speed_current := new_scroll_speed
   scroll_speed_pwm := (1000 - scroll_speed_pwm)
   setTimer,ScrollSpeedPWM,% scroll_speed_pwm

   OutputDebug, ScrollSpeedPWM set speed to %new_scroll_speed%

return