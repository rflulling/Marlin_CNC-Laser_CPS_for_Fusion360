// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
/**
 * Minimal Marlin/Fusion360 Post Processor with Working Dropdown and Correct Output
 */

description = "Marlin Minimal Mode Checker";
vendor = "Open Source";
longDescription = "Minimal post: only checks for known-incompatible commands per Marlin mode.";

// Default property values
properties = {
  marlinMode: 0 // 0=FDM, 1=CNC, 2=LASER
};

// UI Definitions
propertyDefinitions = {
  marlinMode: {
    title: "Marlin Mode",
    description: "Select the Marlin machine mode: FDM, CNC, or LASER.",
    type: "integer",
    values: [
      { title: "FDM (3D Printer)", id: 0 },
      { title: "CNC (Milling)", id: 1 },
      { title: "Laser", id: 2 }
    ],
    default_mm: 0,
    default_in: 0
  }
};

// Mode lookup table for internal use
var modeLabels = ["FDM", "CNC", "LASER"];

var incompatibleGcodes = {
  0:   ["M3", "M4", "M5", "S", "G53", "G54", "G55", "G56", "G57", "G58", "G59"], // FDM
  1:   ["M104", "M109", "M140", "M190", "M600", "M125", "E", "G29"],             // CNC
  2:   ["M104", "M109", "M140", "M190", "M600", "M125", "E", "G29"]              // LASER
};

function onOpen() {
  writeln("; Minimal Marlin Mode Checker - Mode: " + modeLabels[properties.marlinMode]);
}

function onSection() {
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
    var issues = checkForIncompatible(line, properties.marlinMode);
    if (issues.length > 0) {
      writeln("; WARNING: " + issues.join(", ") + " found in line: " + line);
    }
    writeln(line);
  }
}

function checkForIncompatible(line, mode) {
  var list = incompatibleGcodes[mode];
  var found = [];
  for (var j = 0; j < list.length; ++j) {
    var code = list[j];
    if (code === "E") {
      if (/\bE-?\d+(\.\d*)?/.test(line) && mode !== 0) found.push("E axis move");
    } else if (line.match(new RegExp("\\b" + code + "\\b"))) {
      found.push(code);
    }
  }
  return found;
}

function onClose() { writeln("; End of program"); }