#Requires AutoHotkey v2

LeftOffset:=0
TopOffset:=0
RightOffset:=0
BottomOffset:=0


class FullScreenWindow {
    OriginDpi:=0
    TargetDpi:=0
    hWnd:=0
    Window:=Map()
    ID:=0

    ; CTOR
    __New(ID) {
		this.hWnd := ID
        if this.IsFullScreen()
            this.ToggleStyles()
	}

    Matches(ID){
        if (this.hWnd == ID)
            return true
        else
            return false
    }

    MakeFullScreenOn(monitor) {
        if !WinExist(this.hWnd) || monitor > MonitorGetCount()
            return false
        if this.IsOnMonitor()=monitor && this.IsFullScreen()
            return true
        if !this.CanRestore()
            this.SavePosition()
        MonitorGet(monitor, &MonLeft, &MonTop, &MonRight, &MonBottom)
        WinRestore this.hwnd ; clears artifacts below window
        WinMove(MonLeft,
                MonTop,
                MonRight - MonLeft,
                MonBottom - MonTop,
                this.hWnd)

        this.TargetDpi:=DllCall("User32\GetDpiForWindow", "Ptr", this.hWnd, "int")
        if !this.IsFullScreen()
            {
            this.ToggleStyles()
            }
        WinMaximize this.hWnd
        WinSetAlwaysOnTop(1, this.hwnd)
    }

    SavePosition(){
        this.Window:=Map()
        WinGetPos &x, &y, &w, &h, this.hWnd
        this.Window[this.hWnd] := [x, y, w, h]
        this.OriginDpi:=DllCall("User32\GetDpiForWindow", "Ptr", this.hWnd, "int")
    }

    Restore(){
        if !WinExist(this.hWnd) ||
           !this.CanRestore()
            return false
        this.Window[this.hWnd][3]*=this.TargetDpi / this.OriginDpi
        this.Window[this.hWnd][4]*=this.TargetDpi / this.OriginDpi
        WinRestore this.hWnd
        WinMove(this.Window[this.hWnd]*)        

        if this.IsFullScreen()
            this.ToggleStyles()
        
        WinSetAlwaysOnTop(0, this.hwnd)

        this.Window.Delete(this.hWnd)
    }

    IsFullScreen(){
        if !WinExist(this.hWnd)
            return false

        if WinGetStyle(this.hWnd) & 0x40000
            return false
        else
            return true
    }

    CanRestore(){
        if !WinExist(this.hWnd)
            return false
        if this.Window.Has(this.hWnd)
            return true
        else
            return false
    }

    IsOnMonitor(){
        if !WinExist(this.hWnd)
            return false
        WinGetPos(&x, &y, &w, &h, this.hWnd)
        mon:=0
        loop (MonitorGetCount()){
            MonitorGet(A_Index, &MonLeft, &MonTop, &MonRight, &MonBottom)
            if (x >= MonLeft + LeftOffset &&
                x < MonRight + RightOffset &&
                y >= MonTop + TopOffset &&
                y < MonBottom + BottomOffset)
                {
                    mon:=A_Index
                    break
                }
            }
        return mon
    }

    ToggleStyles(){
        if !WinExist(this.hWnd)
            return false
        WinSetStyle "^0x040000",this.hWnd ; WS_SIZEBOX

        ; needed on regular window, AvidVideoEngine is already borderless
        ;WinSetStyle "^0x800000",this.hWnd ; WS_BORDER

        WinSetStyle "^0xC00000",this.hWnd ; WS_CAPTION
    }
}