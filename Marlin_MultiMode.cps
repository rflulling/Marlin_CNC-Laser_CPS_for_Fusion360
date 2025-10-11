// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
/**
 * Fusion360 Post Processor for Marlin (FDM/CNC/Laser) - Multi-Mode
 * 
 * - Mode selection: FDM, CNC, Laser
 * - Speed Control Mode: Firmware / G-code / Magic (placeholder)
 * - Extensible for advanced segment-aware logic
 */

description = "Marlin Multi-Mode (FDM/CNC/Laser) with Speed Control Placeholder";
vendor = "Open Source";
vendorUrl = "https://marlinfw.org/";
longDescription = "Fusion360 post processor for Marlin FDM, CNC, and Laser. Speed control selectable: Firmware, G-code, or Magic (future advanced hybrid mode).";

// Default property values (integers for dropdowns)
properties = {
  machineMode: 0,        // 0=FDM, 1=CNC, 2=LASER
  speedControlMode: 0    // 0=Firmware, 1=G-code, 2=Magic
};

// UI property definitions for dropdowns
propertyDefinitions = {
  machineMode: {
    title: "Machine Mode",
    description: "Select Marlin machine mode: FDM (3D printing), CNC (milling), Laser",
    type: "integer",
    values: [
      { title: "FDM (3D Printer)", id: 0 },
      { title: "CNC (Milling)", id: 1 },
      { title: "Laser", id: 2 }
    ],
    default_mm: 0,
    default_in: 0
  },
  speedControlMode: {
    title: "Speed Control Mode",
    description: "Firmware: Let Marlin manage motion. G-code: Per-move feed/accel/jerk. Magic: [Placeholder] Advanced dynamic hybrid.",
    type: "integer",
    values: [
      { title: "Firmware (set once at start)", id: 0 },
      { title: "G-code (per move/toolpath)", id: 1 },
      { title: "Magic (future: advanced dynamic)", id: 2 }
    ],
    default_mm: 0,
    default_in: 0
  }
};

var machineModeLabels = ["FDM", "CNC", "LASER"];
var speedModeLabels = ["Firmware", "Gcode", "Magic"];

function onOpen() {
  writeln("; Post processor: Marlin Multi-Mode v0.2");
  writeln("; Selected mode: " + machineModeLabels[properties.machineMode]);
  writeln("; Speed Control: " + speedModeLabels[properties.speedControlMode]);
  if (properties.speedControlMode === 2) {
    writeln("; NOTICE: Magic mode is not yet implemented. When enabled in the future, this will perform dynamic, segment-aware feed/accel/jerk optimization for highest quality.");
    writeln("; Magic mode will increase post-processing time and G-code size, but may deliver superior performance for complex prints and cuts.");
  }
  // Firmware mode: set machine parameters at start
  if (properties.speedControlMode === 0 || properties.speedControlMode === 2) {
    writeln("M201 X1000 Y1000 Z100 E5000 ; Default accel");
    writeln("M204 P1000 T2000 ; Default/travel accel");
    writeln("M205 J0.02 ; Junction deviation");
    writeln("; Firmware speed/accel/jerk set at program start.");
  }
}

function onSection() {
  // Placeholder toolpath segment array for demonstration/testing
  var toolpath = [
    {type: "line",   length: 20.0, F: 3000, accel: 1000, jerk: 0.02},
    {type: "arc",    length: 5.0,  radius: 2.0, F: 1500, accel: 800, jerk: 0.01},
    {type: "line",   length: 0.8,  F: 1000, accel: 600, jerk: 0.01},
    {type: "ramp",   length: 6.0,  F: 500,  accel: 500, jerk: 0.01},
    {type: "line",   length: 50.0, F: 4000, accel: 1200, jerk: 0.03}
  ];
  for (var i = 0; i < toolpath.length; ++i) {
    var seg = toolpath[i];
    var outLine = "";
    // --- FIRMWARE: Output simple move, let firmware handle motion ---
    if (properties.speedControlMode === 0) {
      outLine = makeMove(seg, seg.F);
    }
    // --- GCODE: Output move with explicit F, M204/M205 as needed ---
    else if (properties.speedControlMode === 1) {
      if (seg.accel) writeln("M204 P" + seg.accel + " ; Set accel");
      if (seg.jerk)  writeln("M205 J" + seg.jerk  + " ; Set junction deviation");
      outLine = makeMove(seg, seg.F);
    }
    // --- MAGIC: Placeholder only ---
    else if (properties.speedControlMode === 2) {
      writeln("; MAGIC MODE PLACEHOLDER: In future, this segment will be dynamically analyzed and optimized.");
      outLine = makeMove(seg, seg.F); // Fallback for now
    }
    writeln(outLine);
  }
}

function makeMove(seg, F) {
  // For demo: just output G1 F... (add X/Y/Z/E for real post)
  return "G1 F" + Math.round(F);
}

function onClose() { writeln("; End of program"); }