#Requires AutoHotkey v2
#SingleInstance Force

; >>>>> Configure

; shortcut
PrintScreen:: TogglePTFullScreen()

; monitor to make pro tools full screen on
pt_Monitor:= MonitorGetPrimary()

; Configure <<<<<<

pt_IsFullscreen:=false
pt_main_hWnd:=0

ControlTimer(){
	if pt_main_hWnd = 0
		return
	pt_edit_hWnd:= GetMDIWindow(pt_main_hWnd, "Edit:")
    pt_mix_hWnd:= GetMDIWindow(pt_main_hWnd, "Mix:")    
	ToggleControl(pt_mix_hWnd)
    ToggleControl(pt_edit_hWnd)
}

TogglePTFullScreen(){
    global pt_IsFullscreen
    global pt_main_hWnd:= WinExist("ahk_class DigiAppWndClass","")
    
	if pt_main_hWnd == 0    
        return 0   
    
	ToggleMainWindow(pt_main_hWnd)  
	if pt_IsFullscreen
		SetTimer ControlTimer, 1000
	else
		SetTimer ControlTimer, -1000 ; negative means run once in specified interval
    
	; Send Ctrl + =  twice, force a redraw
    WinActivate pt_main_hWnd    
    Send "^="    
    Send "^="    
}

ToggleMainWindow(hWnd){
	global pt_IsFullscreen	
	global pt_Monitor
	if !WinExist(hWnd)
        return false	

    if !IsWindowStyled(hWnd){
        ToggleStyles hWnd        
		MonitorGetWorkArea(pt_Monitor, &Left, &Top, &Right, &Bottom)
        WinMove Left, Top, Right - Left, Bottom - Top, hWnd
		pt_IsFullscreen:=true
    }
    else{
        ToggleStyles hWnd
        WinRestore hWnd
		pt_IsFullscreen:=false
    }
}

ToggleControl(hWnd){
	global pt_IsFullscreen
    if !WinExist(hWnd)
        return false
	
	if pt_IsFullscreen {
		if !IsWindowStyled(hWnd) {
			WinMove 0,0,,,hWnd
			ToggleStyles hWnd
			WinRestore hWnd
			WinMaximize hWnd
		} 
	}
	else {
		if IsWindowStyled(hWnd){
        	ToggleStyles hWnd
			WinRestore hWnd
		}
    }
}

ToggleStyles(hWnd){
	WinSetStyle "^0x040000", hWnd ; WS_SIZEBOX    
	WinSetStyle "^0xC00000", hWnd ; WS_CAPTION
}

IsWindowStyled(hWnd){
	if !WinExist(hWnd)	
        return false
	   
	if WinGetStyle(hWnd) & 0x40000
			return false
		else    
			return true	
}

GetMDIWindow(hWnd, ID)
{
    try           
		return ControlGetHwnd(ID,hWnd)    
    catch 		
		return false   
}

