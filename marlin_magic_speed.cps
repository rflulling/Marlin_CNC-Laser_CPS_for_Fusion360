// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
// Version: 1.4.2
/**
 * Fusion360 Post Processor for Marlin - Magic Speed Mode
 * Real toolpath G-code output with dynamic speed logic and per-axis invert options.
 */

description = "Marlin Magic Speed Post";
vendor = "rflulling";
longDescription = "Fusion360 post for Marlin with dynamic, segment-aware speed/accel/jerk. Now includes per-axis inverted X/Y options.";
extension = "gcode";

/*
Version: 1.4.2
Vendor: rflulling
Credits: GitHub Copilot GPT-4.1
*/

properties = {
  invertX: false,
  invertY: false
};

propertyDefinitions = {
  invertX: {
    title: "Invert X Axis",
    description: "Negate X coordinates before output (use if Fusion360 X is opposite to machine X).",
    type: "boolean",
    default_mm: false,
    default_in: false
  },
  invertY: {
    title: "Invert Y Axis",
    description: "Negate Y coordinates before output (use if Fusion360 Y is opposite to machine Y).",
    type: "boolean",
    default_mm: false,
    default_in: false
  }
};

// ... (your other property definitions and variables go here as in previous versions)

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
  // ... (your other logic here as in previous version)
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

// ... (the rest of your Magic post logic)