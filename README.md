# Marlin Fusion360 Post Processors

This repository contains three fully operational Fusion360 post processors for Marlin firmware, maintained by **rflulling** and developed with the assistance of **GitHub Copilot GPT-4.1**.

## Post Processors Included

- **Marlin Minimal**  
  A minimal, clean, real G-code post with mode selection, output rules, and concise configuration.
- **Marlin MultiMode**  
  Full support for FDM, CNC, and Laser. User-selectable speed control and startup/shutdown options.
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
- All user choices are echoed in header comments for traceability.

---

## Version History (Summary)

### Minimal

- **1.4.0** (2025-10-12)
    - Added spindle/laser/router start method property and logic.
    - Added shutdown sequence property, default now: Z retract, OFF, Y home, X home.
    - All settings documented in header.
    - All prior config and bugfixes retained.

### MultiMode

- **1.4.0** (2025-10-12)
    - All above features, plus:
    - Mode (FDM/CNC/Laser) and speed control as before.
    - Full startup/shutdown customization.

### Magic Speed

- **1.4.0** (2025-10-12)
    - All above features, plus:
    - "Magic" mode for segment-aware speed/accel/jerk logic.

---

## Usage

1. **Install the .cps file** in Fusion360 as a custom post processor.
2. **Set properties as desired**:
    - Mode (FDM/CNC/Laser), speed control, zeroing, spindle/laser start method, shutdown sequence, custom code, etc.
3. **Generate NC/gcode output** from your Fusion360 project.
4. **Review header and startup/shutdown code** in output file; edit as needed for your workflow.

---

## License and Authorship

- **SPDX-License-Identifier:** MIT
- **Copyright:** (c) 2025 rflulling
- **Developed with:** GitHub Copilot GPT-4.1

For developer workflow and advanced notes, see [DEV_NOTES.md](./DEV_NOTES.md).