#Requires AutoHotkey v2
#SingleInstance Force

#Include includes\class_FullScreenWindow.ahk
#Include includes\class_MonitorInfo.ahk
#Include includes\class_RegStartup.ahk
/*
-------------------------------------
PT_FS_Video - Make Pro Tools video window borderless
Version: 1.1.0
-------------------------------------
*/

;>>> CONFIG

UsePrimaryMonitor:=false
TargetWindow  := "ahk_exe AvidVideoEngine.exe"

; shortcuts
^#Numpad0:: IdentifyMon_Click()

;<<< CONFIG

;>>> INIT
INI_Path:=A_ScriptDir "\"
INI_File:=INI_Path "PTFS_Video.ini"

INI_Section_General:="General"
INI_Section_Monitor:="Favorite"
INI_Key_FavMonitor:="FavMon"
INI_Key_AutoStart:="RunAtStartup"
INI_Key_AutoFullScreen:="AutoFullScreen"

FavMonitor:=IniRead(INI_File, INI_Section_Monitor, INI_Key_FavMonitor, -1)
if FavMonitor=-1
	IniWrite(FavMonitor := MonitorGetCount(), INI_File, INI_Section_Monitor, INI_Key_FavMonitor)

AutoFullScreen:=IniRead(INI_File, INI_Section_Monitor, INI_Key_AutoFullScreen, 0)

RunAtStartup:=IniRead(INI_File, INI_Section_General, INI_Key_AutoStart, 0)
rs:=RegStartup("PTFullScreen", A_ScriptFullPath)
rs.Set(RunAtStartup)

TraySetIcon(A_Windir "\system32\SHELL32.dll",116)
tray:=A_TrayMenu
NumberOfMonitors:=MonitorGetCount()
MonitorClicked:=false
MonitorMap:=Map()
fsw:=FullScreenWindow(-1)
Menu_Refresh()
;<<< INIT

SetTimer(MainLoop, 1000)

MainLoop(){
	global NumberOfMonitors
	global AutoFullScreen
	global FavMonitor
	global TargetWindow
	global hWnd
	global MonitorClicked
	global fsw

	; monitor config has changed
	If NumberOfMonitors != MonitorGetCount() {
		NumberOfMonitors := MonitorGetCount()
		AutoFullScreen:=false
		fsw.Restore()
		Menu_Refresh()
	}

	; video window presence
	if hWnd := WinExist(TargetWindow) {
		if !fsw.Matches(hWnd)
			fsw:=FullScreenWindow(hWnd)
	}
	else { ; video window not present
		fsw.hWnd := -1
		return
	}

	; user has clicked on menu monitor
	if !AutoFullScreen && MonitorClicked {
		fsw.MakeFullScreenOn(FavMonitor)
		MonitorClicked:=false
		return
	}

	; AutoFullscreen user option
	if AutoFullScreen
		fsw.MakeFullScreenOn(FavMonitor)
}

Menu_Refresh(){
	global MonitorMap
	global FavMonitor
	global tray
	global AutoFullScreen
	global RunAtStartup

	optionsMenu:=Menu()
	optionsMenu.Add("Auto full-screen", Auto_Click)
	if AutoFullScreen
		optionsMenu.Check("Auto full-screen")
	optionsMenu.Add("Restore", Restore_Click)
	optionsMenu.Add("Run at Startup", RunAtStartup_Click)
	if RunAtStartup
		optionsMenu.Check("Run at Startup")
	optionsMenu.Add("Edit INI file", EditINI_Click)

	tray.Delete()
	tray.Add("Identify monitors", IdentifyMon_Click)
	tray.Add()
	BuildMonitorsMenu(FavMonitor)
	tray.Add()
	tray.Add("Options", optionsMenu)
	tray.Add("Exit", ExitMenu_Click)
	tray.Default:= "Identify monitors"
}

BuildMonitorsMenu(FavMonitor){
	global MonitorMap
	global UsePrimaryMonitor
	global tray
	global INI_File
	global mi

	mon:= MonitorInfo(INI_File)
	mi:= mon.MonitorInfos
	primary_mon:= MonitorGetPrimary()
	MonitorMap:= Map()

	loop (MonitorGetCount()){
		menu_id:= ""
		MonitorItem:= {}
		if A_Index = primary_mon {
			if mi[A_Index].FriendlyName == ""
				menu_id:="Monitor" A_Index "(P)`t" mi[A_Index].DeviceManagerName
			else
				menu_id:="Monitor" A_Index "(P)`t" mi[A_Index].FriendlyName

			MonitorItem.Primary:=true
			MonitorItem.Checked:=(A_Index==FavMonitor) && UsePrimaryMonitor
		}
		else {
			if mi[A_Index].FriendlyName == ""
				menu_id:="Monitor" A_Index "`t" mi[A_Index].DeviceManagerName
			else
				menu_id:="Monitor" A_Index "`t" mi[A_Index].FriendlyName

			MonitorItem.Primary:=false
			MonitorItem.Checked:=(A_Index==FavMonitor)
		}
		MonitorItem.ID:=A_Index
		MonitorItem.Name:=menu_id
		MonitorMap[menu_id]:=MonitorItem
		MonitorMap[A_Index]:=MonitorItem
	}

	for k, v in MonitorMap{
		tray.Add(v.Name, Monitor_Click , "Radio")
		if v.Checked {
			;tray.Check(v.Name)
			tray.SetIcon(v.Name, A_Windir "\system32\SHELL32.dll",116)
		}
		;if v.Primary && !UsePrimaryMonitor {
		;	tray.Disable(v.Name)
		;}
	}
}

; toggle auto full-screen
Auto_Click(*){
	global AutoFullScreen

	AutoFullScreen:=!AutoFullScreen
	Menu_Refresh()
	IniWrite(AutoFullScreen, INI_File, INI_Section_Monitor, INI_Key_AutoFullScreen)
}

; restore window size and properties
Restore_Click(*){
	global fsw
	global AutoFullScreen

	fsw.Restore()
	AutoFullScreen:= false
	Menu_Refresh()
}

; toggle run at startup registry key
RunAtStartup_Click(*){
	global RunAtStartup

	RunAtStartup:= !RunAtStartup
	reg:= RegStartup("PTFullScreen", A_ScriptFullPath)
	reg.Set(RunAtStartup)
	IniWrite(RunAtStartup, INI_File, INI_Section_General, INI_Key_AutoStart)
	Menu_Refresh()
}

; toggle display of OSD monitor info
IdentifyMon_Click(*){
	static IDwindows:=[]
	static showOSD:=true
	global mi

	if showOSD=true {
		loop (NumberOfMonitors) {
			MonitorGet(A_Index, &Left, &Top, &Right, &Bottom)
			ID:= Gui()
			ID.BackColor:= "Blue"
			;ID.Add("Text",, Left " " Top " " Right " " Bottom )

			ID.SetFont("s100 cWhite w1000")
			ID.Add("Text","x0 y35 w200 Center", MonitorMap[A_Index].Primary ? A_Index "P": A_Index )
			ID.SetFont("s10 cWhite w1000")
			ID.Add("Text","x0 y175 w200 Center", MonitorGetName(A_Index))
			ID.Show( "X" Left " Y" Top " w200 h200 NoActivate" )
			ID.Opt("+AlwaysOnTop -Caption +ToolWindow")
			IDwindows.Push(ID)
		}
		showOSD:=false
	} else {
		loop(NumberOfMonitors){
			try {
			win:= IDwindows.Pop()
			win.Hide()
			win.Destroy()
			}
			catch {
				IDwindows:=[]
			}
		}
		showOSD:=true
	}
}

; activate selected monitor for fullscreen video window
Monitor_Click(ItemName, ItemPos, MenuName) {
	global FavMonitor
	global MonitorClicked

	; if monitor is shift-clicked, ask for Friendly Name for Monitor Number
	if (GetKeyState("LShift", "P")) {
		input:=InputBox("Enter friendly name for monitor " MonitorMap[ItemName].ID)
		if input.Result == "OK"	{
			IniWrite(input.Value, INI_File, mi[MonitorMap[ItemName].ID].DeviceID, "FriendlyName")
			Menu_Refresh()
		}
	}
	else {
		; switch monitor only if it's not primary or if UsePrimaryMonitor is true
		if MonitorMap.Has(ItemName) && (!MonitorMap[ItemName].Primary || UsePrimaryMonitor)	{
			FavMonitor:= MonitorMap[ItemName].ID
			IniWrite(FavMonitor, INI_File, INI_Section_Monitor, INI_Key_FavMonitor)
			MonitorClicked:=true
			Menu_Refresh()
		}
	}

}

EditINI_Click(*){
	RunWait INI_File
	Menu_Refresh()
}

; exit app
ExitMenu_Click(*) {
	global fsw

	fsw.Restore()
	ExitApp
}
