// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling

## Motion Coordination, Dynamic Speed, and the "Magic" Option

### Rationale

- Marlin's firmware now supports advanced kinematics: junction deviation, S-curve, dynamic lookahead, and runtime g-code overrides (M204/M205/M220/M221/M104).
- For the best results, especially in FDM and adaptive CNC, neither the firmware nor the G-code should "fight" for control. Instead, combine both tools.
- This post processor now includes a "Speed Control Mode" with three settings:
    - **Firmware:** User sets acceleration/jerk in Marlin, G-code is simple.
    - **G-code:** The post processor sets F/accel/jerk per move/toolpath.
    - **Magic:** The post analyzes each segment (length, radius, type), dynamically adjusting F, acceleration, and jerk for best print/cut quality and material/tool safety.
- Magic mode uses both Fusion360's geometric knowledge and Marlin's runtime capabilities for optimally smooth and safe motion.

### Implementation Notes

- The "Magic" mode may increase post-processing time and G-code size, and use more MCU resources.
- User is warned in G-code comments when Magic is active.
- All logic is extensible for future material, tool, or firmware-specific optimizations.
- Segment analysis is done in the post for demo; can be adapted to real Fusion360 toolpath APIs.

### Future Work

- Add user-tunable thresholds for segment length, arc radius, ramp/feed factors.
- Allow material/tool lookup for optimal chip load/feedrate in CNC.
- Document how to tune Marlin and post settings for best results.
