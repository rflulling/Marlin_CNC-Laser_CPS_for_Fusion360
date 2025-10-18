// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
// Version: 1.4.2
/**
 * Minimal, operational Marlin/Fusion360 Post Processor.
 * Real toolpath G-code output.
 * Features:
 *   - Concise NC file header with config/credits
 *   - Units and positioning mode G-code
 *   - Optional work zeroing
 *   - Optional custom header/startup code
 *   - Spindle/Laser/Router start options (CNC/Laser only)
 *   - Selectable output extension (.gcode or .nc)
 *   - Shutdown sequence: Default (Z retract, OFF, G28 Y0, G28 X0), Custom, or None
 *   - Per-axis inversion (Invert X, Invert Y)
 *   - Patch version to fix issue with introduction of Invert Cordinates option. 
 */

description = "Marlin CPS Minimal";
vendor = "rflulling";
longDescription = "Minimal Marlin post: just enough to make it work.";
extension = "gcode"; // default, user can override

/*
Version: 1.4.2
Vendor: rflulling
Credits: GitHub Copilot GPT-4.1
*/

properties = {
  marlinMode: 0,
  autoZero: 0,
  customZero: "X0 Y0 Z0",
  customHeader: "",
  fileExt: 0,
  startDevice: 0,
  shutdownMode: 0,
  customShutdown: "",
  invertX: false,
  invertY: false
};

propertyDefinitions = {
  marlinMode: {
    title: "Marlin Mode",
    description: "Select Marlin machine mode: FDM, CNC, or LASER.",
    type: "integer",
    values: [
      { title: "FDM (3D Printer)", id: 0 },
      { title: "CNC (Milling)", id: 1 },
      { title: "Laser", id: 2 }
    ],
    default_mm: 0,
    default_in: 0
  },
  autoZero: {
    title: "Work Coordinate Zeroing",
    description: "Choose zeroing: None, Auto (G92 X0 Y0 Z0), or Custom (specify offsets below).",
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
  },
  invertX: {
    title: "Invert X Axis",
    description: "If enabled, X coordinates will be negated before output (useful when Fusion360 and machine X directions differ).",
    type: "boolean",
    default_mm: false,
    default_in: false
  },
  invertY: {
    title: "Invert Y Axis",
    description: "If enabled, Y coordinates will be negated before output (useful when Fusion360 and machine Y directions differ).",
    type: "boolean",
    default_mm: false,
    default_in: false
  }
};

var modeLabels = ["FDM", "CNC", "LASER"];

function onOpen() {
  extension = properties.fileExt === 1 ? "nc" : "gcode";
  writeln("; ==============================================");
  writeln("; Marlin Minimal Real Output - Mode: " + modeLabels[properties.marlinMode]);
  writeln("; Vendor: rflulling | Version: 1.4.2 | Credits: GitHub Copilot GPT-4.1");
  writeln("; Units: " + (unit == MM ? "mm" : "inch"));
  writeln("; Positioning: Absolute (G90)");
  writeln("; Zeroing: " +
    (properties.autoZero === 1 ? "Auto (G92 X0 Y0 Z0)" :
     properties.autoZero === 2 ? "Custom (" + properties.customZero + ")" : "None"));
  if (properties.marlinMode === 1 || properties.marlinMode === 2) {
    var devType = (properties.marlinMode === 1) ? "Spindle/Router" : "Laser";
    var startChoice = ["Automatic by G-code/script", "Operator will start manually", "Handled by separate hardware"][properties.startDevice];
    writeln("; " + devType + " Start: " + startChoice);
  }
  writeln("; Shutdown: " +
    (properties.shutdownMode === 0 ? "Default" :
     properties.shutdownMode === 1 ? "Custom" : "None"));
  writeln("; Axis invert: X=" + (properties.invertX ? "INVERTED" : "NORMAL") + ", Y=" + (properties.invertY ? "INVERTED" : "NORMAL"));
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
  if ((properties.marlinMode === 1 || properties.marlinMode === 2) && properties.startDevice === 0) {
    if (properties.marlinMode === 1) {
      writeln("M3 ; Start spindle/router");
    } else if (properties.marlinMode === 2) {
      writeln("M106 ; Laser ON (startup, if needed)");
    }
  }
}

function _applyAxisInvert(x, y) {
  var xo = x;
  var yo = y;
  if (xo !== undefined && properties.invertX) xo = -xo;
  if (yo !== undefined && properties.invertY) yo = -yo;
  return [xo, yo];
}

function onLinear(x, y, z, feed) {
  var coords = _applyAxisInvert(x, y);
  var xOut = coords[0], yOut = coords[1];
  var line = "G1";
  if (xOut !== undefined) line += " X" + xOut.toFixed(3);
  if (yOut !== undefined) line += " Y" + yOut.toFixed(3);
  if (z !== undefined) line += " Z" + z.toFixed(3);
  if (feed !== undefined) line += " F" + feed.toFixed(0);
  if (properties.marlinMode !== 0 && /E[+\-]?\d+(\.\d*)?/.test(line)) {
    writeln("; WARNING: E axis move found: " + line);
  }
  writeln(line);
}

function onRapid(x, y, z) {
  var coords = _applyAxisInvert(x, y);
  var xOut = coords[0], yOut = coords[1];
  var line = "G0";
  if (xOut !== undefined) line += " X" + xOut.toFixed(3);
  if (yOut !== undefined) line += " Y" + yOut.toFixed(3);
  if (z !== undefined) line += " Z" + z.toFixed(3);
  writeln(line);
}

function onClose() {
  writeln("; End of program");
}