
# Reboot Timeline Analyzer

A Zsh script that parses macOS's `last` log to display a timeline of system reboots, classifying them as **intentional** (if preceded by a shutdown), and calculating the **implied uptime** between reboots.

## Features

- ✅ Labels reboots as `[intentional]` if triggered by user
- ✅ Calculates uptime as the time between one reboot and the next
- ✅ Cross-references reboot timestamps with `softwareupdate --history` to identify nearby macOS updates
- ✅ Displays **multiple software updates per reboot**, formatted as `[Update 1, Update 2]`
- ✅ Removes redundant version numbers from update names for cleaner output
- ✅ Properly handles year rollovers (e.g. Dec 2024 → Jan 2025)
- ✅ Configurable time window for matching reboots to updates (`MATCH_WINDOW_SEC`, default 1800s)

## Example Output

```
=== Reboot Event Timeline ===
Jun 15 00:01                 ( 0d  4h 16m uptime)
Jun 14 19:45   [intentional] (25d 11h  9m uptime)
May 20 08:36   [intentional] ( 7d 22h 31m uptime)  [macOS Sequoia 15.5]
Aug 02 11:49   [intentional] (28d  3h 36m uptime)  [macOS Sequoia 15.6]
Apr 26 12:48   [intentional] ( 0d 12h 42m uptime)  [Command Line Tools for Xcode 16.3, macOS Sequoia 15.4.1]
...
```

## How It Works

- Uses `last | grep -E '^(reboot|shutdown)'` to extract reboot and shutdown events only
- Determines if a reboot was preceded by a clean shutdown (marking it `[intentional]`)
- Infers year transitions by monitoring month rollovers
- Calls `softwareupdate --history` to pull all updates and timestamps, accepting either:
  - combined `MM/DD/YYYY, HH:MM:SS` in one column, or
  - date and time split across adjacent columns
- Matches each reboot timestamp to all nearby updates (within `MATCH_WINDOW_SEC`, default 30 minutes)
- Omits version numbers from update names when they are already embedded in the title
- Joins multiple updates as a comma-separated list in square brackets

## Usage

1. Save the script as `analyze_shutdowns.sh`
2. Make it executable:
   ```bash
   chmod +x analyze_shutdowns.sh
   ```
+4. (Optional) Adjust the match window:
+   ```bash
+   MATCH_WINDOW_SEC=1800 ./analyze_shutdowns.sh   # 30 minutes
+   ```
3. Run it in a Zsh shell:
   ```bash
   ./analyze_shutdowns.sh
   ```
+4. (Optional) Adjust the match window:
+   ```bash
+   MATCH_WINDOW_SEC=1800 ./analyze_shutdowns.sh   # 30 minutes
+   ```

## Requirements

- macOS (tested on Sequoia 15.5–15.6)
- Zsh (default shell in macOS)
- Relies on accurate `last` output and `softwareupdate --history`

## Limitations

- Only considers system-level software updates from `softwareupdate` (not App Store apps)
- Requires recent log retention — `last` may truncate very old data
- Assumes that time zone and system clock were consistent over the observed timeline
+ - Parsing is sensitive to locale/date formatting; ensure `softwareupdate --history` prints
+   dates as `MM/DD/YYYY, HH:MM:SS` or the classic split columns. If your locale differs,
+   you may need to adjust the `date -j -f` format string.

## License

MIT License — feel free to modify or reuse.

## Troubleshooting
- **No updates ever match:** increase `MATCH_WINDOW_SEC` (e.g., 1800) to account for reboots
  that happen well after the update finishes.
- **Weird/empty dates:** run `softwareupdate --history | sed -n '1,5p'` to inspect actual
  column layout and date format on your system, then adjust parsing if needed.
