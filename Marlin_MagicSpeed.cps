// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling

/**
 * Fusion360 Post Processor for Marlin - Dynamic (Magic) Speed Control Sample
 * 
 * - Analyzes each move/segment for length, arc, type.
 * - UI option for "Speed Control Mode": Firmware / G-code / Magic
 * - Magic mode: dynamically adjusts F, acceleration, jerk and/or firmware parameters per segment for optimal results.
 * - Notifies user of extra processing time and disk use in Magic mode.
 */

description = "Marlin Dynamic Speed Control Sample (Magic)";
vendor = "rflulling";
longDescription = "Fusion360 post for Marlin: dynamic speed, acceleration, and jerk control per segment or toolpath. 'Magic' mode for optimal hybrid control.";

properties = {
  speedControlMode: {
    title: "Speed Control Mode",
    description: "Choose how speed/acceleration are managed: Firmware (Marlin), G-code (per move), or Magic (dynamic hybrid).",
    type: "list",
    values: [
      {value: "Firmware", title: "Firmware (let Marlin manage motion, set parameters at start)"},
      {value: "Gcode",    title: "G-code (post sets F/accel/jerk per move or toolpath)"},
      {value: "Magic",    title: "Magic (analyze, optimize, and dynamically blend both approaches)"}
    ],
    value: "Firmware"
  }
};

var mode = null;

function onOpen() {
  mode = properties.speedControlMode;
  writeComment("Marlin Post - Speed Mode: " + mode);
  if (mode === "Magic") {
    writeComment("WARNING: Magic mode may require more processing time and larger G-code files.");
  }
  // Optionally, output firmware config block at start
  if (mode === "Firmware" || mode === "Magic") {
    writeBlock("M201 X1000 Y1000 Z100 E5000 ; Default accelerations");
    writeBlock("M204 P1000 T2000 ; Default/Travel accel");
    writeBlock("M205 J0.02 ; Junction deviation");
    writeComment("Firmware speed/accel/jerk set at program start.");
  }
}

function onSection() {
  // Simulated toolpath: replace with actual Fusion360 section moves
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
    var warn = "";
    // --- FIRMWARE: Output simple move, let firmware handle motion ---
    if (mode === "Firmware") {
      outLine = makeMove(seg, seg.F);
    }
    // --- GCODE: Output move with explicit F, M204/M205 as needed ---
    else if (mode === "Gcode") {
      if (seg.accel) writeBlock("M204 P" + seg.accel + " ; Set acceleration");
      if (seg.jerk)  writeBlock("M205 J" + seg.jerk  + " ; Set junction deviation");
      outLine = makeMove(seg, seg.F);
    }
    // --- MAGIC: Dynamically optimize per segment ---
    else if (mode === "Magic") {
      // Example: Slow for short lines or tight arcs, speed up for long/straight
      var F = seg.F;
      if (seg.length < 1.0) {
        F = Math.max(500, seg.F * 0.4);
        warn = " (short move, slowed)";
      }
      if (seg.type === "arc" && seg.radius < 5.0) {
        F = Math.max(600, seg.F * 0.5);
        warn = " (tight arc, slowed)";
      }
      if (seg.type === "ramp") {
        F = Math.min(seg.F, 700);
        writeBlock("M204 P" + seg.accel + " ; Set ramp acceleration");
        warn = " (ramp, special acceleration)";
      }
      if (seg.length > 30.0) {
        F = Math.min(5000, seg.F * 1.3);
        warn = " (long move, sped up)";
      }
      // Optionally, adjust jerk for tight moves
      if (seg.jerk && (seg.type === "arc" || seg.length < 2.0)) {
        writeBlock("M205 J" + (seg.jerk * 0.7).toFixed(3) + " ; Reduce jerk for detail");
      }
      outLine = makeMove(seg, F);
    }
    if (warn) writeComment("MAGIC: " + warn);
    writeBlock(outLine);
  }
}

// Helper: format a move line for G-code (simulate G1 X/Y/E/F)
function makeMove(seg, F) {
  // For simplicity, just output G1 F... (add X/Y/etc for real post)
  return "G1 F" + Math.round(F);
}

function writeBlock(str) {
  writeLine(str);
}
function writeComment(msg) {
  writeLine("; " + msg);
}
function onClose() {
  writeComment("End of program");
}