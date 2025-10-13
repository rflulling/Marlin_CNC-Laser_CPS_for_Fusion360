# Developer Notes: Marlin Fusion360 Post Processors

## Authorship & License

- **Primary Maintainer:** rflulling
- **Copilot/GPT-4.1**: core code generation and iteration (always credited in headers)
- **License:** MIT (SPDX-License-Identifier: MIT)

---

## Version History (All Files)

| Version | File             | Date         | Changes/Fixes                                             |
|---------|------------------|--------------|-----------------------------------------------------------|
| 1.5.0   | MultiMode only   | 2025-10-13   | **TMC Driver Setup**: Optional user-supplied M-codes at startup for advanced Marlin TMC driver configuration. Header and docs updated. |
| 1.4.0   | All              | 2025-10-12   | Startup/shutdown config, device start options, header docs|
| 1.3.0   | All              | 2025-10-12   | Header, units, positioning, zeroing, custom code, ext fix |
| 1.2.0   | All              | 2025-10-11   | Real toolpath output; interface fixes                     |
| 1.1.x   | All              | 2025-10-10   | Mode/speed options, UI, structure bugfixes                |
| 1.0.x   | Minimal only     | 2025-10-09   | First working minimal output                              |

---

## File Overview

- **marlin_mode_minimal.cps**:  
  Clean, basic, real Marlin output. Use as a template for new posts or for debugging.
- **marlin_multimode.cps**:  
  Full-featured. User can choose mode (FDM, CNC, Laser), speed logic, startup/shutdown, and **TMC driver setup for power users**.
- **marlin_magic_speed.cps**:  
  Like MultiMode, but adds “Magic” experimental per-move speed/accel/jerk logic.

---

## Major Features

- **Header block:**  
  - Outputs vendor, version, credits, config summary, units, positioning, zeroing, device start/stop, TMC config, custom code
- **Units & Positioning:**  
  - Outputs `G21`/`G20` and `G90` at top of file (always absolute for Marlin)
- **Zeroing:**  
  - User can select: None, Auto (G92 X0 Y0 Z0), or Custom (G92 with user offsets)
- **Spindle/Router/Laser Start:**  
  - User can select startup: Automatic (insert M3/M106), Operator, or Hardware (comment only)
- **Shutdown:**  
  - Default (Z retract, OFF, Y home, X home), Custom, or None
- **TMC Driver Setup** (MultiMode only):  
  - Optional, advanced-use property to insert custom Marlin TMC M-codes at startup (e.g., for current, mode, hybrid threshold, etc)
  - All code and settings clearly commented in header for traceability
- **Custom startup/header/end code:**  
  - User-supplied, output verbatim before toolpath or at end
- **File extension:**  
  - User can select `.gcode` (default) or `.nc`
- **Warnings:**  
  - E axis moves in non-FDM modes are flagged

---

## Best Practices

- **Increment version and update this file on any change.**
- **Keep README and DEV_NOTES in sync with file structure and features.**
- **Header block should always reflect actual config and last edit/version.**
- **All user-facing strings should be clear and accurate.**
- **Only add startup/shutdown code needed for Marlin or user’s specific workflow.**
- **TMC driver setup is for advanced users only; warn and document in header.**

---

## To Do / Ideas

- Allow user to save/restore property presets.
- Add estimated print/cut time (if available from Fusion360 API).
- Expand “Magic” mode with segment-aware logic (length/radius/type/etc).
- Add tool and material info to header if available.
- Add unit tests or output file tests.

---

For feature requests, bug reports, or help, contact **rflulling** or open an issue on GitHub.