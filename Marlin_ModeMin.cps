// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
/**
 * Minimal Marlin/Fusion360 Post Processor
 * - Only checks for incompatible G-codes by mode
 * - Does not generate real G-code (for demo/testing only)
 * - Outputs a warning comment for each incompatible command found
 */

description = "Marlin Minimal Mode Checker";
vendor = "rflulling";
longDescription = "Minimal post: only checks for known-incompatible commands per Marlin mode.";

properties = {
  machineMode: {
    title: "Machine Mode",
    description: "FDM (3D printing), CNC, LASER",
    type: "list",
    values: [
      {value: "FDM", title: "FDM (3D Printer)"},
      {value: "CNC", title: "CNC (Milling)"},
      {value: "LASER", title: "Laser"}
    ],
    value: "FDM"
  }
};

var incompatibleGcodes = {
  FDM:   ["M3", "M4", "M5", "S", "G53", "G54", "G55", "G56", "G57", "G58", "G59"],
  CNC:   ["M104", "M109", "M140", "M190", "M600", "M125", "E", "G29"],
  LASER: ["M104", "M109", "M140", "M190", "M600", "M125", "E", "G29"]
};

function onOpen() {
  writeComment("Minimal Marlin Mode Checker - Mode: " + properties.machineMode);
}

function onSection() {
  // Simulate a G-code output for checking
  var sampleLines = [
    "G1 X10 Y10 E5",
    "M3 S1000",
    "M104 S200",
    "G29",
    "M5",
    "M140 S60",
    "G53",
    "G1 X20 Y20"
  ];
  for (var i = 0; i < sampleLines.length; ++i) {
    var line = sampleLines[i];
    var issues = checkForIncompatible(line, properties.machineMode);
    if (issues.length > 0) {
      writeComment("WARNING: " + issues.join(", ") + " found in line: " + line);
    }
    writeBlock(line);
  }
}

function checkForIncompatible(line, mode) {
  var list = incompatibleGcodes[mode];
  var found = [];
  for (var j = 0; j < list.length; ++j) {
    var code = list[j];
    if (code === "E") {
      if (/\bE-?\d+(\.\d*)?/.test(line) && mode !== "FDM") found.push("E axis move");
    } else if (line.match(new RegExp("\\b" + code + "\\b"))) {
      found.push(code);
    }
  }
  return found;
}

function writeBlock(str) { writeLine(str); }
function writeComment(msg) { writeLine("; " + msg); }
function onClose() { writeComment("End of program"); }