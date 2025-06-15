# Reboot Timeline Analyzer

A Zsh script that parses macOS's `last` log to display a timeline of system reboots, classifying them as **intentional** or **unintentional**, and calculating the **implied uptime** (how long the system was running) before each reboot.

## Features

- ✅ Labels reboots as `[intentional]` if they follow a clean shutdown
- ✅ Assumes unintentional if no shutdown is found prior
- ✅ Shows full date and time of each reboot
- ✅ Calculates and displays the uptime between each reboot and the next one in the log
- ✅ Output is neatly aligned for readability

## Example Output

```
=== Reboot Event Timeline ===
Jun 15 00:01                 (0d 4h 16m uptime)
Jun 14 19:45  [intentional]  (25d 11h 9m uptime)
May 20 08:36  [intentional]  (0d 0h 2m uptime)
May 12 10:05                 (0d 0h 3m uptime)
May 12 10:02                 
```

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
- Zsh (default shell in modern macOS versions)
- Assumes timestamps in the `last` command output are in the current calendar year

## Limitations

- If system logs span across calendar years, the uptime calculation may be off by a year
- Requires access to the system logs via the `last` command
- Uptime is inferred from log order and may not reflect total time awake if the system slept

## License

MIT License — feel free to modify or reuse.
