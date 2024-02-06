#Requires AutoHotkey v2.0

; ****************************
; credits go to Seven0528 here https://www.autohotkey.com/boards/viewtopic.php?t=116104
; ****************************

class MonitorInfo {   
    
    MonitorInfos:=Map()
    ; MonitorInfos[MonitorIndex].DeviceString - monitor name as it appears in Device Manager
    ; MonitorInfos[MonitorIndex].DeviceID - uniquely identifies monitor
    
    __New(INI_File){
        this.ReadSystemMonitors()
        for k,v in this.MonitorInfos{
            monitorExists:=IniRead(INI_File,v.DeviceID,,-1)
            if monitorExists = -1 {
                ; initialize monitor section
                IniWrite(v.DeviceName,INI_File,v.DeviceID,"DeviceName")
                IniWrite(v.DeviceString,INI_File,v.DeviceID,"DeviceString")
                IniWrite(v.GPUName,INI_File,v.DeviceID,"GPUName")
                IniWrite("",INI_File,v.DeviceID,"FriendlyName")
            }
            else{
                ; read FriendlyName from INI
                friendlyName:=IniRead(INI_File, v.DeviceID, "FriendlyName","")                
                this.MonitorInfos[k].FriendlyName:=friendlyName                
            }
        }
    }
    
    ; reads system mon information to MonitorInfos map
    ReadSystemMonitors(){
        moninfo:={}
        While this.EnumDisplayDevices(A_Index-1, &DISPLAY_DEVICEA0)    {
            if !DISPLAY_DEVICEA0["StateFlags"]
                continue

            ;1. EnumDisplayDevices
            For k,v in DISPLAY_DEVICEA0 {
                  
                if k="DeviceName"
                    moninfo.DeviceName:=v
                if k="DeviceString"
                    moninfo.GPUName:=v
            }

            ;2. EnumDisplayDevices with EDD_GET_DEVICE_INTERFACE_NAME
            this.EnumDisplayDevices(A_Index-1, &DISPLAY_DEVICEA1, 1)

            For k,v in DISPLAY_DEVICEA1 {       
                if k="DeviceString" ; monitor name as it appears in Device Manager
                    moninfo.DeviceString:=v
                if k="DeviceID" ; uniquely identifies monitor
                    moninfo.DeviceID:=v
            }

            if moninfo.DeviceString != "" {
                loop (MonitorGetCount())
                    if MonitorGetName(A_Index) = moninfo.DeviceName
                        moninfo.MonitorNumber:=A_Index
                
                this.MonitorInfos[moninfo.MonitorNumber]:=moninfo
        
            }
            moninfo:={}
        }
    }
    /*
    EnumDisplayDevicesW function (winuser.h)
        https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumdisplaydevicesw
    DISPLAY_DEVICEA structure (wingdi.h)
        https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-display_devicea
    Get display name that matches that found in display settings
        https://stackoverflow.com/questions/7486485/get-display-name-that-matches-that-found-in-display-settings
    Secondary Monitor
        https://www.autohotkey.com/board/topic/20084-secondary-monitor/
    */
    EnumDisplayDevices(iDevNum, &DISPLAY_DEVICEA:="", dwFlags:=0)    {
        Static   EDD_GET_DEVICE_INTERFACE_NAME := 0x00000001
                ,byteCount              := 4+4+((32+128+128+128)*2)
                ,offset_cb              := 0
                ,offset_DeviceName      := 4                            ,length_DeviceName      := 32
                ,offset_DeviceString    := 4+(32*2)                     ,length_DeviceString    := 128
                ,offset_StateFlags      := 4+((32+128)*2)
                ,offset_DeviceID        := 4+4+((32+128)*2)             ,length_DeviceID        := 128
                ,offset_DeviceKey       := 4+4+((32+128+128)*2)         ,length_DeviceKey       := 128

        DISPLAY_DEVICEA:=""
        if (iDevNum~="\D" || (dwFlags!=0 && dwFlags!=EDD_GET_DEVICE_INTERFACE_NAME))
            return false
        lpDisplayDevice:=Buffer(byteCount,0)            ,Numput("UInt",byteCount,lpDisplayDevice,offset_cb)
        if !DllCall("EnumDisplayDevices", "Ptr",0, "UInt",iDevNum, "Ptr",lpDisplayDevice.Ptr, "UInt",0)
            return false
        if (dwFlags==EDD_GET_DEVICE_INTERFACE_NAME)
        {
            DeviceName:=StrGet(lpDisplayDevice.Ptr+offset_DeviceName, length_DeviceName)
            lpDisplayDevice.__New(byteCount,0)          ,Numput("UInt",byteCount,lpDisplayDevice,offset_cb)
            lpDevice:=Buffer(length_DeviceName*2,0)     ,StrPut(DeviceName, lpDevice,length_DeviceName)
            DllCall("EnumDisplayDevices", "Ptr",lpDevice.Ptr, "UInt",0, "Ptr",lpDisplayDevice.Ptr, "UInt",dwFlags)
        }
        For k in (DISPLAY_DEVICEA:=Map("cb",0,"DeviceName","","DeviceString","","StateFlags",0,"DeviceID","","DeviceKey",""))
        {
            Switch k
            {
                case "cb","StateFlags":                 DISPLAY_DEVICEA[k]:=NumGet(lpDisplayDevice, offset_%k%,"UInt")
                default:                                DISPLAY_DEVICEA[k]:=StrGet(lpDisplayDevice.Ptr+offset_%k%, length_%k%)
            }
        }
        return true
    }
}


