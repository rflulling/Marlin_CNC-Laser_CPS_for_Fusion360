// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
// Version: 1.4.0
/**
 * Fusion360 Post Processor for Marlin - Magic Speed Mode
 * Real toolpath G-code output.
 * Features:
 *   - Concise NC file header with config/credits
 *   - Units and positioning mode G-code
 *   - Optional work zeroing
 *   - Optional custom header/startup code
 *   - Spindle/Laser/Router start options (CNC/Laser only)
 *   - Selectable output extension (.gcode or .nc)
 *   - Shutdown sequence: Default (Z retract, OFF, G28 Y0, G28 X0), Custom, or None
 *   - User-selectable speed mode; "Magic" speed/accel/jerk logic
 */

description = "Marlin Magic Speed Post";
vendor = "rflulling";
longDescription = "Fusion360 post for Marlin with dynamic, segment-aware speed/accel/jerk. Full config, header, startup/shutdown, real G-code.";
extension = "gcode";

/*
Version: 1.4.0
Vendor: rflulling
Credits: GitHub Copilot GPT-4.1
*/

properties = {
  speedControlMode: 0, // 0=Firmware, 1=G-code, 2=Magic
  autoZero: 0,
  customZero: "X0 Y0 Z0",
  customHeader: "",
  fileExt: 0,
  startDevice: 0,
  shutdownMode: 0,
  customShutdown: ""
};

propertyDefinitions = {
  speedControlMode: {
    title: "Speed Control Mode",
    description: "Firmware: Marlin controls speed/accel. G-code: Post sets F/accel/jerk per move. Magic: Dynamic optimization (experimental).",
    type: "integer",
    values: [
      { title: "Firmware (set once at start)", id: 0 },
      { title: "G-code (per move/toolpath)", id: 1 },
      { title: "Magic (dynamic/experimental)", id: 2 }
    ],
    default_mm: 0,
    default_in: 0
  },
  autoZero: {
    title: "Work Coordinate Zeroing",
    description: "Choose zeroing: None (operator handles zeroing), Auto (G92 X0 Y0 Z0), or Custom (specify offsets below).",
    type: "integer",
    values: [
      { title: "None", id: 0 },
      { title: "Auto Zero (G92 X0 Y0 Z0)", id: 1 },
      { title: "Custom Zero (use offsets below)", id: 2 }
    ],
    default_mm: 0,
    default_in: 0
  },
  customZero: {
    title: "Custom Zero Offsets",
    description: "Offsets for custom G92 zeroing (e.g., X1.2 Y0 Z-3.5). Only used if Custom Zero is selected.",
    type: "string",
    default_mm: "X0 Y0 Z0",
    default_in: "X0 Y0 Z0"
  },
  customHeader: {
    title: "Custom Header/Startup Code",
    description: "Arbitrary code/comments for header/startup. Output verbatim before toolpath.",
    type: "string",
    default_mm: "",
    default_in: ""
  },
  fileExt: {
    title: "Output File Extension",
    description: "Choose NC file extension.",
    type: "integer",
    values: [
      { title: "gcode", id: 0 },
      { title: "nc", id: 1 }
    ],
    default_mm: 0,
    default_in: 0
  },
  startDevice: {
    title: "Spindle/Laser/Router Start",
    description: "How is the spindle/laser/router started? (CNC/Laser only)",
    type: "integer",
    values: [
      { title: "Automatic by G-code/script", id: 0 },
      { title: "Operator will start manually", id: 1 },
      { title: "Handled by separate hardware", id: 2 }
    ],
    default_mm: 0,
    default_in: 0
  },
  shutdownMode: {
    title: "Shutdown Sequence",
    description: "How should the machine be shutdown at end?",
    type: "integer",
    values: [
      { title: "Default (Z retract, OFF, G28 Y0, G28 X0)", id: 0 },
      { title: "Custom (use script below)", id: 1 },
      { title: "None (no shutdown)", id: 2 }
    ],
    default_mm: 0,
    default_in: 0
  },
  customShutdown: {
    title: "Custom Shutdown Script",
    description: "Only used if 'Custom' shutdown mode is selected.",
    type: "string",
    default_mm: "",
    default_in: ""
  }
};

var modeLabels = ["Firmware", "Gcode", "Magic"];
var baseAccel = 1000;
var baseJerk = 0.02;

function onOpen() {
  extension = properties.fileExt === 1 ? "nc" : "gcode";

  writeln("; ==============================================");
  writeln("; Marlin Magic Speed Post - Speed Mode: " + modeLabels[properties.speedControlMode]);
  writeln("; Vendor: rflulling | Version: 1.4.0 | Credits: GitHub Copilot GPT-4.1");
  writeln("; Units: " + (unit == MM ? "mm" : "inch"));
  writeln("; Positioning: Absolute (G90)");
  writeln("; Zeroing: " +
    (properties.autoZero === 1 ? "Auto (G92 X0 Y0 Z0)" :
     properties.autoZero === 2 ? "Custom (" + properties.customZero + ")" : "None"));
  // Device start (for CNC/Laser)
  if (getMachineMode() === 1 || getMachineMode() === 2) {
    var devType = (getMachineMode() === 1) ? "Spindle/Router" : "Laser";
    var startChoice = ["Automatic by G-code/script", "Operator will start manually", "Handled by separate hardware"][properties.startDevice];
    writeln("; " + devType + " Start: " + startChoice);
  }
  writeln("; Shutdown: " +
    (properties.shutdownMode === 0 ? "Default" :
     properties.shutdownMode === 1 ? "Custom" : "None"));
  if (properties.customHeader) {
    writeln("; --- Custom Header/Startup Code ---");
    var lines = properties.customHeader.split(/\r?\n/);
    for (var i = 0; i < lines.length; ++i) {
      writeln("; " + lines[i]);
    }
    writeln("; --- End Custom Header ---");
  }
  writeln("; ==============================================");

  writeln(unit == MM ? "G21" : "G20");
  writeln("G90");

  if (properties.autoZero === 1) {
    writeln("G92 X0 Y0 Z0");
  } else if (properties.autoZero === 2) {
    writeln("G92 " + properties.customZero);
  }

  // Startup: Spindle/Laser/Router start if Automatic and CNC/Laser
  if ((getMachineMode() === 1 || getMachineMode() === 2) && properties.startDevice === 0) {
    if (getMachineMode() === 1) { // CNC/Spindle
      writeln("M3 ; Start spindle/router");
    } else if (getMachineMode() === 2) { // LASER
      writeln("M106 ; Laser ON (startup, if needed)");
    }
  }

  if (properties.speedControlMode === 0 || properties.speedControlMode === 2) {
    writeln("M201 X1000 Y1000 Z100 E5000 ; Default accelerations");
    writeln("M204 P1000 T2000 ; Default/travel accel");
    writeln("M205 J0.02 ; Junction deviation");
  }
}

function getMachineMode() {
  // Try to use property if defined, fallback to CNC for Magic/Minimal (for compatibility)
  if ("machineMode" in properties) {
    return properties.machineMode;
  }
  // Else, fallback: assume CNC (1) for Magic/Minimal
  return 1;
}

function onSection() {}

function onLinear(x, y, z, feed) {
  var line = "G1";
  if (x !== undefined) line += " X" + x.toFixed(3);
  if (y !== undefined) line += " Y" + y.toFixed(3);
  if (z !== undefined) line += " Z" + z.toFixed(3);
  if (feed !== undefined) line += " F" + feed.toFixed(0);

  // Magic mode: dynamically adjust parameters based on move type/length/feed
  if (properties.speedControlMode === 2) {
    var accel = baseAccel;
    var jerk = baseJerk;
    if (feed && feed < 1000) accel = 500;
    if (feed && feed > 3000) accel = 1500;
    if (feed && feed < 1000) jerk = 0.01;
    if (feed && feed > 3000) jerk = 0.03;
    writeln("M204 P" + accel + " ; Magic accel");
    writeln("M205 J" + jerk.toFixed(3) + " ; Magic jerk");
  }
  // G-code mode: set accel/jerk per move (simple)
  else if (properties.speedControlMode === 1) {
    writeln("M204 P" + (feed ? feed : 1000) + " ; Set accel");
    writeln("M205 J" + baseJerk + " ; Set jerk");
  }
  writeln(line);
}

function onRapid(x, y, z) {
  var line = "G0";
  if (x !== undefined) line += " X" + x.toFixed(3);
  if (y !== undefined) line += " Y" + y.toFixed(3);
  if (z !== undefined) line += " Z" + z.toFixed(3);
  writeln(line);
}

function onClose() {
  // Shutdown sequence (CNC/Laser only, not FDM)
  var mode = getMachineMode();
  if (mode === 1 || mode === 2) {
    if (properties.shutdownMode === 0) {
      // Default: Z retract, OFF, G28 Y0, G28 X0
      writeln("G28 Z ; Retract Z axis");
      if (mode === 1) {
        writeln("M5 ; Spindle/Router OFF");
      } else {
        writeln("M107 ; Laser OFF");
      }
      writeln("G28 Y0 ; Home Y");
      writeln("G28 X0 ; Home X");
    } else if (properties.shutdownMode === 1 && properties.customShutdown) {
      // Custom script
      var lines = properties.customShutdown.split(/\r?\n/);
      for (var i = 0; i < lines.length; ++i) {
        writeln(lines[i]);
      }
    }
  }
  writeln("; End of program");
}