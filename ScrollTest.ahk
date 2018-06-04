#include <_Struct>
SI:=GetScrollInfo("ahk_class Notepad","Edit1")
MsgBox % SI.nPos "-" SI.nPage
SetScrollInfo("ahk_class Notepad","Edit1", 50)
return

ScrollInfo_Init(){ ; Need this init function because otherwise _SCROLLINFO would be empty when static vars are initialized
  global _SCROLLINFO := "cbSize,fMask,nMin,nMax,nPage,nPos,nTrackPos"
}
GetScrollInfo(window,control) {
  global _SCROLLINFO
  static init_struct:=ScrollInfo_Init()
  SI:=new _Struct(_SCROLLINFO)
  SI.cbSize:=sizeof(SI)
  SI.fMask := SIF_ALL := 0x17 ; (SIF_POS := 0x4)|(SIF_RANGE := 0x1)|(SIF_TRACKPOS := 0x10)|(SIF_PAGE := 0x2)
  ControlGet,Hwnd,HWND,,%control%,%window%
  If !DllCall("GetScrollInfo","PTR",Hwnd,"Int",SB_VERT := 0x1,"PTR",SI[""])
    Return false
  else Return SI
}

SetScrollInfo(window,control,ParamsObj,fMask=0x4) { ;fMask defaults to nPos so ParamsObj can be a digit to set position of ScrollBar
  global _SCROLLINFO
  ; SIF_POS := 0x4,SIF_RANGE := 0x1,SIF_TRACKPOS := 0x10,SIF_PAGE := 0x2, SIF_ALL := 0x17
  SI:=new _Struct(_SCROLLINFO)
  SI.cbSize:=sizeof(SI)
  SI.fMask := fMask
  If IsObject(ParamsObj){ ; e.g. {nPos:50,nPage:5}
    for k,v in ParamsObj
      SI[k]:=v
  } else SI.nPos  := ParamsObj
  ControlGet,Hwnd,HWND,,%control%,%window%
  Return DllCall("SetScrollInfo","PTR",Hwnd,"Int",SB_VERT := 0x1,"PTR",SI[""], "Int", 1)
}