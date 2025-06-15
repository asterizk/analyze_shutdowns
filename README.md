# Reboot Timeline Analyzer

A Zsh script that parses macOS's `last` log to display a timeline of system reboots, classifying them as **intentional** (if preceded by a shutdown), and calculating the **implied uptime** between each reboot and the next.

## Features

- ✅ Labels reboots as `[intentional]` if they immediately follow a logged shutdown
- ✅ Assumes reboots are **unintentional** by default unless tagged
- ✅ Calculates **implied system uptime** as the duration between one reboot and the next
- ✅ Shows full timestamp (`Mon Jan 1 HH:MM`) of each reboot
- ✅ Output is aligned and easy to scan

## Example Output

```
=== Reboot Event Timeline ===
Jun 15 00:01                 (0d 4h 16m uptime)
Jun 14 19:45  [intentional]  (25d 11h 9m uptime)
May 20 08:36  [intentional]  (8d 0h 2m uptime)
May 12 10:05                 (0d 0h 3m uptime)
May 12 10:02                 
```

## How It Works

- Parses `last` log entries for `reboot` and `shutdown`
- Each reboot is tagged as `[intentional]` only if it's immediately preceded by a shutdown
- Uptime is computed as the **difference between this reboot and the next one in time**, skipping over shutdown entries

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
- Zsh (default on modern macOS)
- Assumes timestamps in the `last` output are for the current calendar year

## Limitations

- If the `last` log includes reboots across December–January, uptime values may be off (as the year is inferred)
- Requires access to `last` command (usually present on macOS)
- Uptime is inferred and may differ slightly from real uptime due to sleep/hibernation

## License

MIT License — feel free to modify or reuse.
