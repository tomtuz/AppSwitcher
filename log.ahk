class log {
    static list := []
    static isVerbose := true

    static verbose(msg) {
        if (this.isVerbose) {
            this.add("VERBOSE: " . msg)
            FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . " - VERBOSE: " . msg . "`n", "logs\verbose_log.txt")
            ui.updateDebugLog()
        }
    }

    static error(msg) {
        this.add("ERROR: " . msg)
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . " - ERROR: " . msg . "`n", "logs\error_log.txt")
        ui.updateDebugLog()
    }

    static add(msg) {
        this.list.Push(FormatTime(, "yyyy-MM-dd HH:mm:ss") . " - " . msg)
        if (this.list.Length > 100) {
            this.list.RemoveAt(1)
        }
    }

    static getAll() {
        text := ""
        for entry in this.list {
            text .= entry . "`n"
        }
        return text
    }

    static toggle() {
        this.isVerbose := !this.isVerbose
        this.add(this.isVerbose ? "Verbose logging enabled" : "Verbose logging disabled")
        ui.updateDebugLog()
    }
}
