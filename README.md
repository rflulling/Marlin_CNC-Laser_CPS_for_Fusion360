# Marlin Fusion360 Post Processors

This repository contains three fully operational Fusion360 post processors for Marlin firmware, maintained by **rflulling** and developed with the assistance of **GitHub Copilot GPT-4.1**.

## Post Processors Included

- **Marlin Minimal**  
  A minimal, clean, real G-code post with mode selection, output rules, and concise configuration.
- **Marlin MultiMode**  
  Full support for FDM, CNC, and Laser. User-selectable speed control, startup/shutdown options, and **TMC driver setup support** for advanced users.
- **Marlin Magic Speed**  
  Experimental “magic” segment-aware speed/accel/jerk logic. Also supports basic and G-code modes.

---

## Features (All Posts)

- Concise, commented header in the NC/G-code file:
    - Mode, vendor, version, credits, units, positioning, zeroing, device start/stop, custom code
- G21/G20 (units) and G90 (absolute) output based on Fusion360 project
- Optional work coordinate zeroing:
    - None, Auto (G92 X0 Y0 Z0), or Custom offsets
- Optional custom startup/header code (output verbatim before toolpath)
- Output file extension: `.gcode` (default) or `.nc` (user-selectable)
- **Spindle/Laser/Router start options** (for CNC/Laser):
    - Automatic by code/script (startup command)
    - Operator starts manually (header comment only)
    - Handled by separate hardware (header comment only)
- **Shutdown sequence options** (for CNC/Laser):
    - Default: Z retract, OFF, home Y, home X
    - Custom shutdown script
    - No shutdown (only end comment)
- **TMC Driver Setup** (MultiMode only):
    - Optional, advanced-use property to insert custom Marlin TMC M-codes at startup (e.g., for current, mode, hybrid threshold, etc)
    - All code and settings clearly commented in header for traceability

---

## Version History (Summary)

### Minimal

- **1.4.0** (2025-10-12)
    - Spindle/laser/router start logic, shutdown options, header doc, bugfixes.

### MultiMode

- **1.5.0** (2025-10-13)
    - **NEW:** TMC Driver Setup: optional, user-supplied M-codes (M906, M913, etc) for advanced configuration at program start.
    - All prior features retained.

- **1.4.0** (2025-10-12)
    - Spindle/laser/router start logic, shutdown options, header doc, bugfixes.

### Magic Speed

- **1.4.0** (2025-10-12)
    - Spindle/laser/router start logic, shutdown options, header doc, bugfixes.
    - No real magic in here yet. Working on that. Though I may remove if I cannot get what I would like from this function.
    - once perfected will be integrated as an option under multimode. 

---

## Usage

1. **Install the .cps file** in Fusion360 as a custom post processor.
2. **Set properties as desired** (mode, speed, zeroing, device start/stop, TMC setup, etc).
3. For TMC driver setup (MultiMode only):  
    - Enable “TMC Driver Setup” in properties.
    - Enter your custom M-codes (one per line) for Marlin TMC configuration.
    - These will be output at the start of your NC file.
    - **Caution:** Requires Marlin to be configured to accept these commands. Use only if you understand TMC driver options.
4. **Generate NC/gcode output** from your Fusion360 project.
5. **Review header and startup/shutdown code** in output file; edit as needed for your workflow.

---

## License and Authorship

- **SPDX-License-Identifier:** MIT
- **Copyright:** (c) 2025 rflulling
- **Developed with:** GitHub Copilot GPT-4.1

For developer workflow and advanced notes, see [DEV_NOTES.md](./DEV_NOTES.md).
