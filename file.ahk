#Requires AutoHotkey v2.0
#Include _JXON.ahk

class fs {
    static load(path) {
        if (FileExist(path)) {
            try {
                content := FileRead(path)
                log.verbose("Read config file contents: " . content)
                loaded := Jxon_Load(&content)
                if (IsObject(loaded) && loaded.Count > 0) {
                    log.verbose("Groups loaded successfully")
                    return loaded
                }
            } catch as err {
                log.error("Error loading groups: " . err.Message)
            }
        }
        log.verbose("No groups loaded, returning empty Map")
        return Map()
    }

    static save(groups, path) {
        if (groups.Count == 0) {
            log.verbose("No groups to save")
            return false
        }

        try {
            SplitPath(path, &name, &dir)
            log.verbose("Saving to directory: " . dir)
            log.verbose("File name: " . name)

            if (!DirExist(dir)) {
                log.verbose("Directory does not exist, attempting to create")
                DirCreate(dir)
            }

            if (!DirExist(dir)) {
                log.error("Failed to create directory: " . dir)
                return false
            }

            json := Jxon_Dump(groups)

            if (FileExist(path)) {
                log.verbose("Existing file found, attempting to delete")
                FileDelete(path)
            }

            log.verbose("Attempting to write to file: " . path)
            FileAppend(json, path)

            if (!FileExist(path)) {
                log.error("File was not created: " . path)
                return false
            }

            log.verbose("Groups saved successfully to " . path)
            return true
        } catch as err {
            log.error("Error saving groups: " . err.Message . " (Code: " . err.Extra . ")")
            return false
        }
    }

}
