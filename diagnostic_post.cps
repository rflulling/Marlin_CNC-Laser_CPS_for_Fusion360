// SPDX-License-Identifier: MIT
// Diagnostic Post for Fusion360 Post Processor Syntax/Property Issues
// Version: 1.0.0
/**
 * Loads all property types, helper function, and a test onOpen/onLinear/onRapid/onClose.
 * Does NOT generate real toolpath but will confirm property UI and function syntax are valid.
 */

description = "Fusion360 Post Diagnostic Utility";
vendor = "rflulling";
longDescription = "Diagnostic Fusion360 post: validates property syntax, function loading, and basic output.";
extension = "gcode";

properties = {
  boolTest: false,
  intTest: 0,
  strTest: "default",
  invertX: false,
  invertY: false
};

propertyDefinitions = {
  boolTest: {
    title: "Test Boolean",
    description: "Test boolean property.",
    type: "boolean",
    default_mm: false,
    default_in: false
  },
  intTest: {
    title: "Test Integer",
    description: "Test integer property.",
    type: "integer",
    default_mm: 0,
    default_in: 0
  },
  strTest: {
    title: "Test String",
    description: "Test string property.",
    type: "string",
    default_mm: "default",
    default_in: "default"
  },
  invertX: {
    title: "Invert X Axis",
    description: "Negate X coordinates before output.",
    type: "boolean",
    default_mm: false,
    default_in: false
  },
  invertY: {
    title: "Invert Y Axis",
    description: "Negate Y coordinates before output.",
    type: "boolean",
    default_mm: false,
    default_in: false
  }
};

function writeln(line) { /* Make sure to output something to preview window */ }

function onOpen() {
  writeln("; Diagnostic Post Loaded Successfully.");
  writeln("; Property boolTest: " + properties.boolTest);
  writeln("; Property intTest: " + properties.intTest);
  writeln("; Property strTest: " + properties.strTest);
  writeln("; Property invertX: " + properties.invertX);
  writeln("; Property invertY: " + properties.invertY);
}

function onLinear(x, y, z, feed) {
  var xo = x;
  var yo = y;
  if (xo !== undefined && properties.invertX) xo = -xo;
  if (yo !== undefined && properties.invertY) yo = -yo;
  var line = "G1";
  if (xo !== undefined) line += " X" + xo;
  if (yo !== undefined) line += " Y" + yo;
  if (z !== undefined) line += " Z" + z;
  if (feed !== undefined) line += " F" + feed;
  writeln("; Diagnostic: " + line);
}

function onRapid(x, y, z) {
  var xo = x;
  var yo = y;
  if (xo !== undefined && properties.invertX) xo = -xo;
  if (yo !== undefined && properties.invertY) yo = -yo;
  var line = "G0";
  if (xo !== undefined) line += " X" + xo;
  if (yo !== undefined) line += " Y" + yo;
  if (z !== undefined) line += " Z" + z;
  writeln("; Diagnostic: " + line);
}

function onClose() {
  writeln("; Diagnostic Post End of Program.");
}