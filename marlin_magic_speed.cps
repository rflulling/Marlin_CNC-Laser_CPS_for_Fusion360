// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
// Version: 1.4.1
/**
 * Fusion360 Post Processor for Marlin - Magic Speed Mode
 * Real toolpath G-code output with dynamic speed logic and per-axis invert options.
 */

description = "Marlin Magic Speed Post";
vendor = "rflulling";
longDescription = "Fusion360 post for Marlin with dynamic, segment-aware speed/accel/jerk. Now includes per-axis inverted X/Y options.";
extension = "gcode";

/*
Version: 1.4.1
Vendor: rflulling
Credits: GitHub Copilot GPT-4.1
*/

properties.invertX = false;
properties.invertY = false;

propertyDefinitions.invertX = {
  title: "Invert X Axis",
  description: "Negate X coordinates before output (use if Fusion360 X is opposite to machine X).",
  type: "boolean",
  default_mm: false,
  default_in: false
};
propertyDefinitions.invertY = {
  title: "Invert Y Axis",
  description: "Negate Y coordinates before output (use if Fusion360 Y is opposite to machine Y).",
  type: "boolean",
  default_mm: false,
  default_in: false
};

// existing magic speed variables and functions remain; below are the small changes to apply inversion

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

  // Magic speed adjustments, TMC behavior, warnings, etc. (existing implementation)
  // ...
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