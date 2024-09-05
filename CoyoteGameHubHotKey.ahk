#Requires AutoHotkey v2.0
#SingleInstance
Persistent

Tray := A_TrayMenu ; For convenience.

#Include "includes\Utils.ahk"
#Include "includes\JXON.ahk"
#Include "includes\GuiButtonIcon.ahk"
#Include "includes\CoyoteGameHubSDK.ahk"

global CoyoteControllerURL := "http://127.0.0.1:8920"
global CoyoteTargetClientId := "all"

global HotKeyList := [
    ["^F6", "setStrength", "0"],
    ["^F7", "addStrength", "1"],
    ["^F8", "subStrength", "1"],
    ["^F9", "fire", "20,5"]
]

global HotKeyCallbackList := []

global ActionLabelDefine := Map()
ActionLabelDefine["setStrength"] := "设置强度"
ActionLabelDefine["addStrength"] := "增加强度"
ActionLabelDefine["subStrength"] := "减少强度"
ActionLabelDefine["setRandomStrength"] := "设置随机强度"
ActionLabelDefine["addRandomStrength"] := "增加随机强度"
ActionLabelDefine["subRandomStrength"] := "减少随机强度"
ActionLabelDefine["fire"] := "一键开火"
ActionLabelDefine["setPulse"] := "设置波形"

OnPressHotKeyFactory(param)
{
    OnPressHotKey(*)
    {
        action := param[2]
        value := param[3]

        if (action = "setStrength")
        {
            return CoyoteSetStrength(value)
        }
        else if (action = "addStrength")
        {
            return CoyoteAddStrength(value)
        }
        else if (action = "subStrength")
        {
            return CoyoteSubStrength(value)
        }
        else if (action = "setRandomStrength")
        {
            return CoyoteSetRandomStrength(value)
        }
        else if (action = "addRandomStrength")
        {
            return CoyoteAddRandomStrength(value)
        }
        else if (action = "subRandomStrength")
        {
            return CoyoteSubRandomStrength(value)
        }
        else if (action = "fire")
        {
            values := StrSplit(value, ",")
            return CoyoteFire(values[1], values[2])
        }
        else if (action = "setPulse")
        {
            return CoyoteSetPulseId(value)
        }
    }

    return OnPressHotKey
}

UnregisterHotKeys()
{
    global HotKeyList
    
    loop HotKeyList.Length
    {
        value := HotKeyList[A_Index]
        keyCode := value[1]

        if (keyCode = "")
        {
            continue
        }

        callback := HotKeyCallbackList[A_Index]

        Hotkey(keyCode, callback, "Off")
    }
}

RegisterHotKeys()
{
    global HotKeyList, HotKeyCallbackList

    HotKeyCallbackList := []

    loop HotKeyList.Length
    {
        value := HotKeyList[A_Index]

        keyCode := value[1]
        action := value[2]
        param := value[3]

        if (keyCode = "" or action = "" or param = "")
        {
            continue
        }

        callback := OnPressHotKeyFactory(value)

        HotKeyCallbackList.Push(callback)

        OutputDebug("Register HotKey: " . keyCode . " -> " . action . "(" . param . ")")
        Hotkey(keyCode, callback, "On t1")
    }
}

; 读取配置文件
LoadSettingFile()
{
    global CoyoteControllerURL, CoyoteTargetClientId
    global HotKeyList
    
    FilePath := A_ScriptDir . "\config.ini"
    if !FileExist(FilePath)
    {
        return
    }

    CoyoteControllerURL := IniRead(FilePath, "CoyoteGameHubHotKey", "ControllerUrl", CoyoteControllerURL)
    CoyoteTargetClientId := IniRead(FilePath, "CoyoteGameHubHotKey", "ClientId", CoyoteTargetClientId)

    HotKeyList := []

    loop 100
    {
        keyCode := IniRead(FilePath, "HotKey" . A_Index, "keycode", "")
        if (keyCode = "")
        {
            break
        }

        action := IniRead(FilePath, "HotKey" . A_Index, "action", "")
        param := IniRead(FilePath, "HotKey" . A_Index, "param", "")

        HotKeyList.Push([keyCode, action, param])
    }
}

; 保存配置文件
SaveSettingFile()
{
    global CoyoteControllerURL, CoyoteTargetClientId

    FilePath := A_ScriptDir . "\config.ini"
    ; 删除配置文件
    if (FileExist(FilePath))
    {
        FileDelete(FilePath)
    }

    IniWrite(CoyoteControllerURL, FilePath, "CoyoteGameHubHotKey", "ControllerUrl")
    IniWrite(CoyoteTargetClientId, FilePath, "CoyoteGameHubHotKey", "ClientId")

    loop HotKeyList.Length
    {
        value := HotKeyList[A_Index]

        keyCode := value[1]
        action := value[2]
        param := value[3]

        IniWrite(keyCode, FilePath, "HotKey" . A_Index, "keycode")
        IniWrite(action, FilePath, "HotKey" . A_Index, "action")
        IniWrite(param, FilePath, "HotKey" . A_Index, "param")
    }
}

; ==================== GUI ====================================================

; =============================================================================
; 设置窗口
; =============================================================================
SettingGui := Gui(, "Coyote Game Hub HotKey 参数设置")
SettingGui.SetFont(, "MS Sans Serif")
SettingGui.SetFont(, "Segoe UI")

SettingGui.Add("Text",, "控制器地址:")
SettingGui.Add("Text",, "客户端ID:")

inputCoyoteControllerUrl := SettingGui.Add("Edit", "vControllerUrl ym w200 r1",)  ; The ym option starts a new column of controls.
inputCoyoteTargetClientId := SettingGui.Add("Edit", "vClientId r1 w200",)

UpdateSettingGui()
{
    global CoyoteControllerURL, CoyoteTargetClientId
    inputCoyoteControllerUrl.Value := CoyoteControllerURL
    inputCoyoteTargetClientId.Value := CoyoteTargetClientId
}

OnSaveSetting(*)
{
    global CoyoteControllerURL, CoyoteTargetClientId

    Saved := SettingGui.Submit()  ; Save the contents of named controls into an object.
    
    CoyoteControllerURL := Saved.ControllerUrl
    CoyoteTargetClientId := Saved.ClientId

    SaveSettingFile()
}
SettingGui.Add("Button", "default", "保存 (&S)").OnEvent("Click", OnSaveSetting)

OnOpenSettingMenu(*)
{
    UpdateSettingGui()
    SettingGui.Show()
}

Tray.Insert("1&", "参数设置", OnOpenSettingMenu, )

#Include "includes\HotKeyConfigForm.ahk"

; =============================================================================
; 初始化
; =============================================================================
LoadSettingFile()
RegisterHotKeys()