```markdown
# Marlin Fusion360 Post Processors

This repository contains three fully operational Fusion360 post processors for Marlin firmware, maintained by **rflulling** and developed with the assistance of **GitHub Copilot GPT-4.1**.

## Post Processors Included

- **Marlin Minimal**  
  A minimal, clean, real G-code post with mode selection, output rules, and concise configuration.
- **Marlin MultiMode**  
  Full support for FDM, CNC, and Laser. User-selectable speed control, startup/shutdown options, and **TMC driver setup support** for advanced users. Includes optional dynamic TMC adjustments (v1.6.0).
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
- **Dynamic TMC Adjustments** (MultiMode v1.6.0):
    - Optional feature to emit TMC commands during the job based on feed thresholds to better utilize advanced driver features.
    - User-configurable templates, thresholds, and rate-limiting to avoid spamming the firmware.
- **Per-axis Inversion (all posts v1.4.1 / v1.6.1)**:
    - New properties to invert X and/or Y independently. Useful when Fusion360 axis orientation differs from machine wiring/firmware.

---

## Version History (Summary)

### Minimal

- **1.4.1** (2025-10-16)
    - Added per-axis Invert X/Invert Y options, header echo and applied inversion to all output moves.

### MultiMode

- **1.6.1** (2025-10-16)
    - Added per-axis Invert X/Invert Y options; applied to linear/rapid moves; header echo updated.
- **1.6.0** (2025-10-16)
    - Dynamic TMC adjustments: emit TMC M-codes (configurable templates and thresholds) during the job. Added conservative defaults, dedupe, and rate-limiting.
- **1.5.0** (2025-10-13)
    - TMC Driver Setup: optional, user-supplied M-codes (M906, M913, etc) for advanced configuration at program start.
- **1.4.0** (2025-10-12)
    - Spindle/laser/router start logic, shutdown options, header doc, bugfixes.

### Magic Speed

- **1.4.1** (2025-10-16)
    - Added per-axis Invert X/Invert Y options to match MultiMode/Minimal behavior.
- **1.4.0** (2025-10-12)
    - Spindle/laser/router start logic, shutdown options, header doc, bugfixes.

---

## Usage

1. **Install the .cps file** in Fusion360 as a custom post processor.
2. **Set properties as desired** (mode, speed, zeroing, device start/stop, TMC setup, dynamic TMC options, axis inversion, custom code, etc).
3. For TMC driver setup (MultiMode only):
    - Enable “TMC Driver Setup” in properties.
    - Enter your custom M-codes (one per line) for Marlin TMC configuration.
    - These will be output at the start of your NC file.
    - **Caution:** Requires Marlin to be configured to accept these commands. Use only if you understand TMC driver options.
4. For Dynamic TMC (MultiMode only):
    - Enable “Enable Dynamic TMC Adjustments”.
    - Configure your command template (e.g., `M906 X{X} Y{Y} Z{Z}`) and baseline/high currents.
    - Tune feed thresholds and the minimum interval between emitted commands.
    - The post will emit TMC commands before moves that meet configured thresholds.
    - **Caution:** Dynamic changes can be powerful and risky. Start with conservative values and test carefully.
5. **Axis inversion**:
    - Use the new Invert X / Invert Y booleans in each post if your Fusion360 model axes are opposite to your machine axes.
    - The post will negate X and/or Y coordinates at output. Verify with dry-runs before cutting.
6. **Generate NC/gcode output** from your Fusion360 project.
7. **Review header and startup/shutdown code** in output file; edit as needed for your workflow.

---

## License and Authorship

- **SPDX-License-Identifier:** MIT
- **Copyright:** (c) 2025 rflulling
- **Developed with:** GitHub Copilot GPT-4.1

For developer workflow and advanced notes, see [DEV_NOTES.md](./DEV_NOTES.md).