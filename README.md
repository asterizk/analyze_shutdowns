# Reboot Timeline Analyzer

A Zsh script that parses macOS's `last` log to display a timeline of system reboots, classifying them as **intentional** (if preceded by a shutdown), and calculating the **implied uptime** between reboots.

## Features

- ✅ Labels reboots as `[intentional]` if they follow a clean shutdown
- ✅ Omits labels for unintentional reboots, keeping the output minimal
- ✅ Calculates uptime as the time between one reboot and the next
- ✅ Properly handles year rollovers (e.g. Dec 2024 → Jan 2025)
- ✅ Ensures dates like `Mar 03` and `Apr 26` align visually
- ✅ Clean, single-line output format with tags and uptime aligned

## Example Output

```
=== Reboot Event Timeline ===
Jun 15 00:01     (0d 4h 16m uptime)
Jun 14 19:45     [intentional] (25d 11h 9m uptime)
May 20 08:36     [intentional] (7d 22h 31m uptime)
May 12 10:05     (0d 0h 3m uptime)
...
```

## How It Works

- Uses `last | grep -E 'shutdown|reboot'` to extract relevant events
- Infers the year from current date and month transitions in the log
- Tags only intentional reboots (those immediately following shutdown)
- Prints the timestamp (with zero-padded day), optional `[intentional]` tag, and uptime

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
- Assumes timestamps in the `last` output use current calendar year

## Limitations

- If `last` spans multiple years and months are omitted (rare), results could be off
- Does not account for system sleep/hibernate — only reboot gaps

## License

MIT License — feel free to modify or reuse.
