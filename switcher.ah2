#Requires AutoHotkey v2.0
#Include _JXON.ahk
#Include ui.ahk
#Include log.ahk
#Include file.ahk
#Include window.ahk
#SingleInstance Force

; Constants
CONFIG_FILE := A_ScriptDir . "\config.json"
MAX_GROUPS := 5
WINDOW_FILTER := "i)^(chrome|firefox|edge|explorer)\.exe$"


; Global variables
global windows := []
global groups := Map()
global currentGroup := 0

Main() {
    Init()
    SetHotkeys()
    log.verbose("Script initialized")
    OutputGroups()
}

Init() {
    global windows, groups
    windows := window.getAll()

    ; Load the configuration
    groups := fs.load(CONFIG_FILE)

    if (groups.Count > 0) {
        log.verbose("Loaded " . groups.Count . " groups from config")
    } else {
        log.verbose("No groups loaded from config")
    }
    ui.windows := windows  ; Make windows accessible to ui class
    ui.create(windows, groups)
}

SetHotkeys() {
    log.verbose("Setting up hotkeys")
    Hotkey("^+1", (*) => activateGroup(1))
    Hotkey("^+2", (*) => activateGroup(2))
    Hotkey("^+3", (*) => activateGroup(3))
    Hotkey("^+4", (*) => activateGroup(4))
    Hotkey("^+5", (*) => activateGroup(5))
    Hotkey("^``", CycleGroups)
    Hotkey("^+g", ui.toggle)
    log.verbose("Hotkeys set up")
}

activateGroup(num) {
    log.verbose("Activating group: " . num)
    if (groups.Has(String(num))) {
        for id in groups[String(num)] {
            win := window.find(windows, id)
            if (win) {
                log.verbose("Activating window: " . win.Process . " - " . win.Title)
                window.activate(id)
            } else {
                log.verbose("Window not found for ID: " . id)
            }
            Sleep 100
        }
    } else {
        log.verbose("Group " . num . " not found")
    }

}

CycleGroups(*) {
    global currentGroup, groups
    if (groups.Count == 0) {
        log.verbose("CycleGroups: No groups set")
        return
    }

    currentGroup := Mod(currentGroup, groups.Count) + 1
    log.verbose("CycleGroups: Activating group " . currentGroup)
    activateGroup(currentGroup)
}

OutputGroups() {
    if (!log.isVerbose) {
        return
    }
    output := "Current Group Structure:`n"
    output .= FormatMap(groups)
    log.verbose(output)
}

FormatMap(map, indent := "") {
    output := "{\n"
    for key, value in map {
        output .= indent . "  " . key . ": "
        if (IsObject(value)) {
            output .= FormatMap(value, indent . "  ")
        } else {
            output .= value . "`n"
        }
    }
    output .= indent . "}`n"
    return output
}

assignGroup(input, groupNumber) {
    groupNumberStr := String(groupNumber)
    log.verbose("Processing group assignment: Group " . groupNumberStr . ", Input: " . input)

    if (!RegExMatch(input, "^(\d+,)*\d+$")) {
        log.verbose("Invalid input format")
        return { success: false, errorMsg: "Invalid input format. Please use comma-separated numbers only."
        }
    }

    windowIndices := StrSplit(input, ",")

    ; Find the next available group number
    while (groups.Has(groupNumberStr)) {
        groupNumber++
        groupNumberStr := String(groupNumber)
    }

    groups[groupNumberStr] := []
    for indexStr in windowIndices {
        index := Integer(indexStr)

        if (index >= 1 && index <= windows.Length) {
            window := windows[index]
            if (window) {
                groups[groupNumberStr].Push(window.ID)
                log.verbose("added > g: [" . groupNumber . "] id: [" . window.ID . "] process: [" . window.Process .
                    "]")
            } else {
                log.verbose("Window not found at index: " . index)
                return { success: false, errorMsg: "Window not found at index: " . index
                }
            }
        } else {
            log.verbose("Invalid window index: " . indexStr)
            return { success: false, errorMsg: "Invalid window index: " . indexStr
            }
        }
    }

    log.verbose("Group " . groupNumber . " assignment successful")
    OutputGroups()
    return { success: true, errorMsg: ""
    }
}

Main()
