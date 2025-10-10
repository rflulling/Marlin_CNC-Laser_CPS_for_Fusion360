// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling


## Motion & Speed Control Options

This post processor supports three speed/acceleration control modes:

- **Firmware:** Marlin 2.1x manages acceleration, jerk, and smoothing. Post sets machine parameters at start, then outputs standard G-code.
- **G-code:** The post processor sets feedrate (F), acceleration (M204), and jerk (M205) per move/toolpath, based on Fusion360's output.
- **Magic:** The post analyzes each G-code segment (length, arc radius, move type) and dynamically adjusts speed, acceleration, and jerk for best results—using both Fusion360’s foresight and Marlin's runtime control.

**Magic mode may increase post-processing time and G-code file size, but aims to dramatically improve print/cut quality and reliability by taking advantages of services offered by both Fusion360 and Marlin 2.1x**

> See DEV_NOTES.md for details and implementation rationale.
