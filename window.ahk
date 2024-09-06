#Requires AutoHotkey v2.0

class window {
    static getAll() {
        list := WinGetList()
        windows := []
        for id in list {
            try {
                title := WinGetTitle("ahk_id " id)
                proc := WinGetProcessName("ahk_id " id)
                if (title != "") {
                    windows.Push({Title: title, Process: proc, ID: id})
                }
            } catch as err {
                log.verbose("Skipped window due to error: " . err.Message)
            }
        }
        this.sort(windows)
        return windows
    }

    ; bubble lol
    static sort(windows) {
        n := windows.Length
        loop n - 1 {
            swapped := false
            loop n - A_Index {
                if (StrCompare(windows[A_Index].Process, windows[A_Index + 1].Process) > 0) {
                    temp := windows[A_Index]
                    windows[A_Index] := windows[A_Index + 1]
                    windows[A_Index + 1] := temp
                    swapped := true
                }
            }
            if (!swapped) {
                break
            }
        }
    }

    static find(windows, id) {
        for win in windows {
            if (win.ID == id) {
                return win
            }
        }
        return ""
    }

    static activate(id) {
        WinActivate("ahk_id " . id)
    }

    static isValid(id) {
        return WinExist("ahk_id " . id)
    }

    static getTitle(id) {
        return WinGetTitle("ahk_id " . id)
    }

    static getProcess(id) {
        return WinGetProcessName("ahk_id " . id)
    }
}
