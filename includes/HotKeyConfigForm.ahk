KeyCodeToKeyName(keyCode)
{
    keyCode := StrReplace(keyCode, "+", "Shift + ")
    keyCode := StrReplace(keyCode, "^", "Ctrl + ")
    keyCode := StrReplace(keyCode, "#", "Win + ")
    keyCode := StrReplace(keyCode, "!", "Alt + ")

    return keyCode
}

global PulseList := []

RefreshPulseList()
{
    global PulseList

    response := CoyoteGetPulseList()
    data := Jxon_Load(&response)
    if (data = "")
    {
        MsgBox("获取脉冲列表失败")
    }
    else if (data["status"] != 1)
    {
        MsgBox("获取脉冲列表失败: " . data["message"])
    }

    PulseList := data["pulseList"]
}

; =============================================================================
; 快捷键设置窗口
; =============================================================================
KeyConfigGui := Gui(, "Coyote Game Hub HotKey 快捷键设置")

KeyConfigGui.SetFont(, "MS Sans Serif")
KeyConfigGui.SetFont(, "Segoe UI")

ButtonAddKeyConfig := KeyConfigGui.Add("Button", "w80", "新增 (&N)")
GuiButtonIcon(ButtonAddKeyConfig, "compstui.dll", 7, "a0 l10")

ButtonDeleteKeyConfig := KeyConfigGui.Add("Button", "w80 ym", "删除 (&D)")
GuiButtonIcon(ButtonDeleteKeyConfig, "compstui.dll", 6, "a0 l10")

KeyConfigListView := KeyConfigGui.Add("ListView", "r20 w700 xm", ["快捷键", "功能", "参数"])

KeyConfigListView.ModifyCol(1, 100)
KeyConfigListView.ModifyCol(2, 100)
KeyConfigListView.ModifyCol(3, 100)

; 刷新快捷键列表
UpdateKeyConfigListView()
{
    global KeyConfigListView, HotKeyList, ActionLabelDefine, PulseList

    if (KeyConfigListView = "")
    {
        return
    }

    KeyConfigListView.Delete()

    loop HotKeyList.Length
    {
        value := HotKeyList[A_Index]

        keyCode := value[1]
        action := value[2]
        param := value[3]

        if (keyCode != "")
        {
            keyCode := KeyCodeToKeyName(keyCode)
        }

        if (action != "")
        {
            actionLabel := ActionLabelDefine[action]
        }
        else
        {
            actionLabel := ""
        }

        if (action = "fire")
        {
            params := StrSplit(param, ",")
            param := params[1] . ", " . params[2] . "s"
        }
        else if (action = "setPulse")
        {
            loop PulseList.Length
            {
                pulse := PulseList[A_Index]
                if (pulse["id"] = param)
                {
                    param := pulse["name"]
                    break
                }
            }
        }

        KeyConfigListView.Add("", keyCode, actionLabel, param)
    }
}

; 启用快捷键设置窗口
EnableKeyConfigGui()
{
    KeyConfigGui.Opt("-Disabled")
}

; 打开编辑快捷键的窗口
OnOpenKeyEditMenu(index, parentWindow := "")
{
    global HotKeyList, ActionLabelDefine

    isAdd := index = 0

    if (isAdd)
    {
        hotKeyConfig := ["", "", ""]
    }
    else
    {
        hotKeyConfig := HotKeyList[index]
    }

    formTitle := "编辑快捷键"
    if (isAdd)
    {
        formTitle := "新增快捷键"
    }

    form := Gui(, formTitle)

    form.Opt("-MinimizeBox -MaximizeBox")

    if (parentWindow != "")
    {
        form.Opt("+Owner" . parentWindow.Hwnd)
    }

    form.SetFont(, "MS Sans Serif")
    form.SetFont(, "Segoe UI")

    form.Add("Text", "w60", "快捷键:")
    form.Add("Text", "w60", "功能:")
    form.Add("Text", "w60", "强度:")
    form.Add("Text", "w60", "时间 (秒):")
    form.Add("Text", "w60", "波形:")

    ; 转换action列表为下拉框数据
    actionName := hotKeyConfig[2]
    actionList := []
    actionLabelList := []
    actionSelected := 1

    for key, value in ActionLabelDefine
    {
        actionList.Push(key)
        actionLabelList.Push(value)
    }

    if (actionName != "")
    {
        actionSelected := ArraySearch(actionList, actionName, 1)
    }

    ; 转换脉冲列表为下拉框数据
    pulseIdList := []
    pulseLabelList := []

    loop PulseList.Length
    {
        pulse := PulseList[A_Index]
        pulseIdList.Push(pulse["id"])
        pulseLabelList.Push(pulse["name"])
    }

    inputKeyCode := form.Add("Hotkey", "vKeyCode w100 ym", hotKeyConfig[1])
    dropdownAction := form.Add("DropDownList", "vAction w100 Choose" . actionSelected, actionLabelList)
    inputStrength := form.Add("Edit", "vStrength w100 Number", "")
    inputTime := form.Add("Edit", "vTime w100 Disabled", "")
    dropdownPulse := form.Add("DropDownList", "vPulseId w100", pulseLabelList)

    ; 在功能选择变化时，判断是否显示时间输入框
    OnActionChange(*)
    {
        action := actionList[dropdownAction.Value]

        if (action = "fire")
        {
            inputStrength.Enabled := false
            inputTime.Enabled := true
            dropdownPulse.Enabled := true
        }
        else if (action = "setPulse")
        {
            inputStrength.Enabled := false
            inputTime.Enabled := false
            dropdownPulse.Enabled := true
        }
        else
        {
            inputStrength.Enabled := true
            inputTime.Enabled := false
            dropdownPulse.Enabled := false
        }
    }
    OnActionChange()
    dropdownAction.OnEvent("Change", OnActionChange)

    ; 如果是开火功能，显示时间输入框
    if (actionName = "fire")
    {
        params := StrSplit(hotKeyConfig[3], ",")
        inputStrength.Text := params[1]
        inputTime.Text := params[2]

        if (params.Length >= 3) ; 指定波形
        {
            selectedPulse := ArraySearch(pulseIdList, params[3], 1)
            dropdownPulse.Choose(selectedPulse)
        }
    }
    ; 如果是设置波形功能，显示波形选择框
    else if (actionName = "setPulse")
    {
        selectedPulse := ArraySearch(pulseIdList, hotKeyConfig[3], 1)
        dropdownPulse.Choose(selectedPulse)
    }
    else
    {
        inputStrength.Text := hotKeyConfig[3]
    }

    OnSaveKeyConfig(*)
    {
        if (inputKeyCode.Value = "")
        {
            MsgBox("请输入快捷键")
            return
        }

        actionIndex := dropdownAction.Value
        pulseIndex := dropdownPulse.Value

        if (parentWindow != "")
        {
            EnableKeyConfigGui()
        }

        Saved := form.Submit()

        form.Destroy()

        keyCode := Saved.KeyCode

        action := actionList[actionIndex]
        strength := Saved.Strength
        time := Saved.Time

        if (action = "")
        {
            MsgBox("请选择功能")
            return
        }

        if (action != "fire" and action != "setPulse" and inputStrength.Value = "")
        {
            MsgBox("请输入强度")
            return
        }

        if (action = "fire")
        {
            if (time = "")
            {
                time := 5 ; 默认 5 秒
            }
            param := strength . "," . time
        }
        else if (action = "setPulse")
        {
            pulseId := pulseIdList[pulseIndex]
            param := pulseId
        }
        else
        {
            param := strength
        }

        if (isAdd)
        {
            HotKeyList.Push([keyCode, action, param])
        }
        else
        {
            HotKeyList[index] := [keyCode, action, param]
        }

        ; 保存配置
        SaveSettingFile()

        ; 刷新列表
        UpdateKeyConfigListView()
    }
    ButtonSave := form.Add("Button", "w80", "保存 (&S)").OnEvent("Click", OnSaveKeyConfig)

    OnCloseKeyEdit(*)
    {
        EnableKeyConfigGui()
        form.Destroy()
    }
    form.OnEvent("Close", OnCloseKeyEdit)

    form.Show()
}

; 双击列表项时，打开编辑窗口
OnKeyListViewDoubleClick(ListView, Index)
{
    KeyConfigGui.Opt("+Disabled")
    OnOpenKeyEditMenu(Index, KeyConfigGui)
}
KeyConfigListView.OnEvent("DoubleClick", OnKeyListViewDoubleClick)

; 新增快捷键
OnBtnAddKeyConfigClick(*)
{
    OnOpenKeyEditMenu(0, KeyConfigGui)
}
ButtonAddKeyConfig.OnEvent("Click", OnBtnAddKeyConfigClick)

; 删除快捷键
OnBtnDeleteKeyConfigClick(*)
{
    selectedIndex := KeyConfigListView.GetNext(0, "F")
    if (selectedIndex = 0)
    {
        MsgBox("请选择要删除的快捷键")
        return
    }

    if (MsgBox("确定要删除选中的快捷键吗？", "提示", "0x1") = "Cancel")
    {
        return
    }

    HotKeyList.RemoveAt(selectedIndex)

    ; 保存配置
    SaveSettingFile()

    ; 刷新列表
    UpdateKeyConfigListView()
}
ButtonDeleteKeyConfig.OnEvent("Click", OnBtnDeleteKeyConfigClick)

; 关闭单个快捷键设置窗口时，启用快捷键设置窗口
OnCloseKeyConfig(*)
{
    ; 关闭窗口时恢复快捷键绑定
    RegisterHotKeys()
}
KeyConfigGui.OnEvent("Close", OnCloseKeyConfig)

OnOpenKeyConfigMenu(*)
{
    ; 打开窗口时取消快捷键绑定，防止无法输入快捷键
    UnregisterHotKeys()

    ; 刷新波形列表
    RefreshPulseList()

    UpdateKeyConfigListView()

    KeyConfigGui.Show()
}

Tray.Insert("1&", "快捷键设置", OnOpenKeyConfigMenu, )
