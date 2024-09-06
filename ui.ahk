#Requires AutoHotkey v2.0

class ui {
    static gui := ""
    static groupCount := ""
    static errorText := ""
    static verboseCheck := ""
    static groupList := ""
    static input := ""
    static debugLogGui := ""
    static debugLogEdit := ""
    static filterCheck := ""
    static windowLV := ""

    ; Main UI creation and update functions
    static create(windows, groups) {
        if (IsObject(this.gui)) {
            this.gui.Show()
            return
        }

        this.initGui()
        this.addControls(windows)
        this.setGuiEvents()
        this.update()
        this.gui.Show()
    }

    static initGui() {
        this.gui := Gui()
        this.gui.Opt("+Resize")
        this.gui.Title := "Window Group Manager"
    }

    static addControls(windows) {
        this.addFilterCheck()
        this.addWindowList(windows)
        this.addGroupControls()
        this.addGroupList()
        this.addMiscControls()
    }

    static addFilterCheck() {
        this.filterCheck := this.gui.Add("Checkbox", "xm", "Filter Windows")
        this.filterCheck.OnEvent("Click", (*) => this.toggleFilter())
    }

    static setGuiEvents() {
        this.gui.OnEvent("Close", (*) => this.gui.Hide())
        this.gui.OnEvent("Escape", (*) => this.gui.Hide())
    }

    static update() {
        this.updateGroupList()
        this.updateGroupCount()
        log.verbose("GUI updated")
    }

    static addWindowList(windows) {
        this.gui.Add("Text", "xm", "Available Windows:")
        this.windowLV := this.gui.Add("ListView", "r20 w500 xm", ["Index", "Process ID", "Process", "Title"
        ])
        this.updateWindowList(windows)
        this.windowLV.OnEvent("DoubleClick", (LV, RowNumber) => this.addToInput(LV, RowNumber))
    }

    static updateWindowList(windows, filter := "") {
        this.windowLV.Delete()
        for index, win in windows {
            if (filter = "" || RegExMatch(win.Process, filter)) {
                this.windowLV.Add(, index, win.ID, win.Process, win.Title)
            }
        }
        this.windowLV.ModifyCol(3, 130)
        this.windowLV.ModifyCol(4, "AutoHdr")
    }

    static toggleFilter() {
        if (this.filterCheck.Value) {
            filter := WINDOW_FILTER
        } else {
            filter := ""
        }
        this.updateWindowList(this.windows, filter)
    }

    static addGroupControls() {
        this.gui.Add("Text", "xm", "Double-click windows to add to group, then click 'Assign':")
        this.input := this.gui.Add("Edit", "r3 w500 xm vUserInput")
        assignBtn := this.gui.Add("Button", "w100 xm", "Assign")
        assignBtn.OnEvent("Click", (*) => this.assign())

        backBtn := this.gui.Add("Button", "x+10 yp w50", "←")
        backBtn.OnEvent("Click", (*) => this.removeLastInput())
    }

    static addGroupList() {
        this.gui.Add("Text", "xm", "Current Group Assignments (double-click to remove):")
        this.groupList := this.gui.Add("ListView", "r6 w500 xm", ["GID", "Process ID", "Process", "Title"
        ])
        this.groupList.ModifyCol(3, 110)
        this.groupList.OnEvent("DoubleClick", (LV, RowNumber) => this.removeFromGroup(RowNumber))
    }

    static addMiscControls() {
        configBtn := this.gui.Add("Button", "xm w100", "Export Config")
        configBtn.OnEvent("Click", (*) => this.exportConfig())

        clearBtn := this.gui.Add("Button", "x+10 yp w100", "Clear Groups")
        clearBtn.OnEvent("Click", (*) => this.clearGroups())

        saveBtn := this.gui.Add("Button", "x+10 yp w100", "Save settings")
        saveBtn.OnEvent("Click", (*) => this.saveGroups())

        this.groupCount := this.gui.Add("Text", "xm", "Groups set: 0")
        this.errorText := this.gui.Add("Text", "xm w500 cRed", "")

        this.addVerboseCheck()
        this.addDebugButton()
        this.addInfoButton()
    }

    ; Helper functions
    static addVerboseCheck() {
        this.verboseCheck := this.gui.Add("Checkbox", "xm", "Verbose Logging")
        this.verboseCheck.Value := log.isVerbose
        this.verboseCheck.OnEvent("Click", (*) => this.toggleVerbose())
    }

    static addDebugButton() {
        debugBtn := this.gui.Add("Button", "x+10 yp w100", "Show Debug Log")
        debugBtn.OnEvent("Click", (*) => this.showDebugLog())
    }

    static addInfoButton() {
        infoBtn := this.gui.Add("Button", "x+10 yp w30", "i")
        infoBtn.OnEvent("Click", (*) => this.showInfo())
    }

    static updateGroupList() {
        this.groupList.Delete()
        log.verbose("Updating GroupLV. Number of groups: " . groups.Count)
        for groupNum, processIDs in groups {
            log.verbose("Group " . groupNum . " has " . processIDs.Length . " windows")
            for processID in processIDs {
                win := window.find(windows, processID)
                if (win) {
                    this.groupList.Add(, groupNum, processID, win.Process, win.Title)
                    log.verbose("Added window to GroupLV: " . win.Process . " - " . win.Title)
                } else {
                    this.groupList.Add(, groupNum, processID, "N/A", "Window not found")
                    log.verbose("Window not found for processID: " . processID)
                }
            }
        }
    }

    static updateGroupCount() {
        this.groupCount.Value := "Groups set: " . groups.Count
    }

    static toggle() {
        if (WinExist("ahk_id " . this.gui.Hwnd)) {
            if (WinGetStyle("ahk_id " . this.gui.Hwnd) & 0x10000000) { ; WS_VISIBLE
                this.gui.Hide()
            } else {
                this.gui.Show()
            }
        } else {
            this.create(windows, groups)
        }
    }

    static addToInput(LV, RowNumber) {
        if (RowNumber > 0) {
            CurrentInput := this.input.Value
            if (CurrentInput != "")
                CurrentInput .= ","
            CurrentInput .= RowNumber
            this.input.Value := CurrentInput
        }
    }

    static assign() {
        global groups
        if (this.input.Value != "") {
            newGroupNumber := groups.Count + 1
            result := assignGroup(this.input.Value, newGroupNumber)
            if (result.success) {
                this.update()
                this.input.Value := ""
                this.errorText.Value := "Group " . newGroupNumber . " assigned successfully."
                this.errorText.Opt("cGreen")
            } else {
                this.errorText.Value := result.errorMsg
                this.errorText.Opt("cRed")
                log.error(result.errorMsg)
            }
        } else {
            this.errorText.Value := "No input provided. Please select windows first."
            this.errorText.Opt("cRed")
        }
    }

    static removeLastInput() {
        currentInput := this.input.Value
        if (currentInput != "") {
            inputArray := StrSplit(currentInput, ",")
            inputArray.Pop()
            newInput := ""
            for i, v in inputArray {
                if (i > 1) {
                    newInput .= ","
                }
                newInput .= v
            }
            this.input.Value := newInput
        }
    }

    static removeFromGroup(RowNumber) {
        global groups
        if (RowNumber > 0) {
            groupNum := this.groupList.GetText(RowNumber, 1)
            processID := this.groupList.GetText(RowNumber, 2)
            if (MsgBox("Remove this window from Group " . groupNum . "?", "Confirm Removal", 4) == "Yes") {
                if (groups.Has(groupNum)) {
                    newGroup := []
                    for id in groups[groupNum] {
                        if (id != processID) {
                            newGroup.Push(id)
                        }
                    }
                    if (newGroup.Length > 0) {
                        groups[groupNum] := newGroup
                    } else {
                        groups.Delete(groupNum)
                    }
                    this.update()
                    this.errorText.Value := "Window removed from Group " . groupNum
                    this.errorText.Opt("cGreen")
                }
            }
        }
    }

    static exportConfig() {
        if (!IsSet(CONFIG_FILE)) {
            this.errorText.Value := "Error: CONFIG_FILE not defined."
            this.errorText.Opt("cRed")
            log.error("CONFIG_FILE not defined when attempting to save config")
            return
        }
        log.verbose("Attempting to save config to: " . CONFIG_FILE)
        if (fs.save(groups, CONFIG_FILE)) {
            this.errorText.Value := "Config saved successfully."
            this.errorText.Opt("cGreen")
        } else {
            this.errorText.Value := "Error saving config. Check logs for details."
            this.errorText.Opt("cRed")
        }
    }

    static clearGroups() {
        global groups
        groups.Clear()
        this.update()
        this.errorText.Value := "All groups cleared."
        this.errorText.Opt("cGreen")
    }

    ; Update the SaveGroups function
    static SaveGroups() {
        this.lastSavedGroupCount := groups.Count
        this.update()
        this.ErrorText.Value := "App settings updated!"
        this.ErrorText.Opt("cGreen")
    }

    static toggleVerbose() {
        log.toggle()
        this.verboseCheck.Value := log.isVerbose
    }

    static showDebugLog() {
        if (!IsObject(this.debugLogGui)) {
            this.debugLogGui := Gui()
            this.debugLogGui.Opt("+Resize")
            this.debugLogGui.Title := "Debug Log"
            this.debugLogEdit := this.debugLogGui.Add("Edit", "r20 w600 vDebugLogContent ReadOnly")
            this.debugLogGui.OnEvent("Close", (*) => this.debugLogGui.Hide())
        }

        this.updateDebugLog()
        this.debugLogGui.Show()
    }

    static updateDebugLog() {
        if (IsObject(this.debugLogEdit)) {
            this.debugLogEdit.Value := log.getAll()
        }
    }

    static showInfo() {
        infoText := "Current Group List:`n`n"
        for groupNum, processIDs in groups {
            infoText .= "Group " . groupNum . ":`n"
            for processID in processIDs {
                win := window.find(windows, processID)
                if (win) {
                    infoText .= "id: [" . processID .
                        "]`nprocess: [" . win.Process .
                        "]`ntitle: [" . win.Title . "]`n" .
                        "-------------------------------`n"
                } else {
                    infoText .= "  - Unknown Window (ID: " . processID . ")`n"
                }
            }
            infoText .= "`n"
        }
        MsgBox(infoText, "Quick Group Information")
    }
}
