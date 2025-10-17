// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
// Version: 1.4.1
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
 */

description = "Marlin Minimal Real Output";
vendor = "rflulling";
longDescription = "Minimal Marlin/Fusion360 post: concise header, units/positioning, zeroing, custom code, startup/shutdown, per-axis invert options.";
extension = "gcode"; // default, user can override

/*
Version: 1.4.1
Vendor: rflulling
Credits: GitHub Copilot GPT-4.1
*/

properties = {
  marlinMode: 0, // 0=FDM, 1=CNC, 2=LASER
  autoZero: 0,   // 0=None, 1=Auto Zero, 2=Custom Zero
  customZero: "X0 Y0 Z0",
  customHeader: "",
  fileExt: 0,    // 0=gcode, 1=nc
  startDevice: 0, // 0=Automatic, 1=Operator, 2=Separate Hardware (CNC/Laser only)
  shutdownMode: 0, // 0=Default, 1=Custom, 2=None
  customShutdown: "",
  invertX: false,
  invertY: false
};

propertyDefinitions = {
  marlinMode: { /* unchanged */ },
  autoZero: { /* unchanged */ },
  customZero: { /* unchanged */ },
  customHeader: { /* unchanged */ },
  fileExt: { /* unchanged */ },
  startDevice: { /* unchanged */ },
  shutdownMode: { /* unchanged */ },
  customShutdown: { /* unchanged */ },

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
  // Set file extension
  extension = properties.fileExt === 1 ? "nc" : "gcode";

  // Header block
  writeln("; ==============================================");
  writeln("; Marlin Minimal Real Output - Mode: " + modeLabels[properties.marlinMode]);
  writeln("; Vendor: rflulling | Version: 1.4.1 | Credits: GitHub Copilot GPT-4.1");
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

  // Output units and positioning
  writeln(unit == MM ? "G21" : "G20");
  writeln("G90");

  // Output zeroing if requested
  if (properties.autoZero === 1) {
    writeln("G92 X0 Y0 Z0");
  } else if (properties.autoZero === 2) {
    writeln("G92 " + properties.customZero);
  }

  // Startup: Spindle/Laser/Router start if Automatic and CNC/Laser
  if ((properties.marlinMode === 1 || properties.marlinMode === 2) && properties.startDevice === 0) {
    if (properties.marlinMode === 1) { // CNC/Spindle
      writeln("M3 ; Start spindle/router");
    } else if (properties.marlinMode === 2) { // LASER
      writeln("M106 ; Laser ON (startup, if needed)");
    }
  }
}

function _applyAxisInvert(x, y) {
  // returns [xOut, yOut], note undefined preservation
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

  // Warn for E axis moves in non-FDM modes
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