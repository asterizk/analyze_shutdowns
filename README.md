
# Reboot Timeline Analyzer

A Zsh script that parses macOS's `last` log to display a timeline of system reboots, classifying them as **intentional** (if preceded by a shutdown), and calculating the **implied uptime** between reboots.

## Features

- ✅ Labels reboots as `[intentional]` if they follow a clean shutdown
- ✅ Calculates uptime as the time between one reboot and the next
- ✅ Cross-references reboot timestamps with `softwareupdate --history` to identify nearby macOS updates
- ✅ Removes redundant version numbers from update names for cleaner output
- ✅ Properly handles year rollovers (e.g. Dec 2024 → Jan 2025)
- ✅ Formats timestamps with aligned columns and padded spacing (e.g. `Mar 03`, `Apr 26`)
- ✅ Clean, single-line output format with tags, uptime, and update info aligned

## Example Output

```
=== Reboot Event Timeline ===
Jun 15 00:01                 ( 0d  4h 16m uptime)
Jun 14 19:45   [intentional] (25d 11h  9m uptime)
May 20 08:36   [intentional] ( 7d 22h 31m uptime)  [macOS Sequoia 15.5]
Apr 26 12:48   [intentional] ( 0d 12h 42m uptime)  [Command Line Tools for Xcode 16.3]
...
```

## How It Works

- Uses `last | grep -E 'shutdown|reboot'` to extract reboot and shutdown events
- Determines if a reboot was preceded by a shutdown (marking it `[intentional]`)
- Infers year transitions by monitoring month rollovers
- Calls `softwareupdate --history` to pull all updates and timestamps
- Matches each reboot timestamp to nearby updates (within 10 minutes)
- Omits version numbers from update names when they are already embedded in the title

## Usage

1. Save the script as `analyze_shutdowns.sh`
2. Make it executable:
   ```bash
   chmod +x analyze_shutdowns.sh
   ```
3. Run it in a Zsh shell:
   ```bash
   ./analyze_shutdowns.sh
   ```

## Requirements

- macOS (tested on Sequoia 15.5)
- Zsh (default shell in macOS)
- Relies on accurate `last` output and `softwareupdate --history`

## Limitations

- Only considers system-level software updates from `softwareupdate` (not App Store apps)
- Requires recent log retention — `last` may truncate very old data
- Assumes that time zone and system clock were consistent over the observed timeline

## License

MIT License — feel free to modify or reuse.
