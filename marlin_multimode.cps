// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
// Version: 1.6.1
/**
 * Fusion360 Post Processor for Marlin (FDM/CNC/Laser) - Multi-Mode
 *
 * - Supports FDM, CNC, and Laser mode with real toolpath output.
 * - User can select mode, speed control approach, startup/shutdown, and TMC driver setup.
 * - Dynamic TMC adjustments: the post can emit TMC M-codes based on move feed/length heuristics.
 * - Reports all capabilities to Fusion360.
 * - Concise NC file header, units, positioning, zeroing, custom code, device control, TMC setup, and per-axis invert options.
 */

description = "Marlin Multi-Mode (FDM/CNC/Laser)";
vendor = "rflulling";
longDescription = "Fusion360 post for Marlin FDM, CNC, and Laser. Full config, dynamic TMC support, header, startup/shutdown, real G-code, mode & speed selection.";
extension = "gcode"; // default, user can override

/*
Version: 1.6.1
Vendor: rflulling
Credits: GitHub Copilot GPT-4.1
*/

capabilities = CAPABILITY_MILLING | CAPABILITY_JET; // Advertise CNC and Laser/Jet support

properties.machineMode = properties.machineMode || 0; // preserve existing structure
// Insert new properties into the existing properties object (shown here for clarity)
properties.invertX = false;
properties.invertY = false;

propertyDefinitions.invertX = {
  title: "Invert X Axis",
  description: "Negate X coordinates before output. Use if Fusion360 X direction is opposite of machine X.",
  type: "boolean",
  default_mm: false,
  default_in: false
};
propertyDefinitions.invertY = {
  title: "Invert Y Axis",
  description: "Negate Y coordinates before output. Use if Fusion360 Y direction is opposite of machine Y.",
  type: "boolean",
  default_mm: false,
  default_in: false
};

var machineModeLabels = ["FDM", "CNC", "LASER"];
var speedModeLabels = ["Firmware", "Gcode", "Magic"];

// Keep dynamic TMC state variables (unchanged)
var _lastTmcSet = "";
var _lastTmcTime = 0;

function onOpen() {
  extension = properties.fileExt === 1 ? "nc" : "gcode";

  writeln("; ==============================================");
  writeln("; Marlin Multi-Mode Post - Mode: " + machineModeLabels[properties.machineMode] + " | Speed: " + speedModeLabels[properties.speedControlMode]);
  writeln("; Vendor: rflulling | Version: 1.6.1 | Credits: GitHub Copilot GPT-4.1");
  writeln("; Units: " + (unit == MM ? "mm" : "inch"));
  writeln("; Positioning: Absolute (G90)");
  writeln("; Zeroing: " +
    (properties.autoZero === 1 ? "Auto (G92 X0 Y0 Z0)" :
     properties.autoZero === 2 ? "Custom (" + properties.customZero + ")" : "None"));
  if (properties.machineMode === 1 || properties.machineMode === 2) {
    var devType = (properties.machineMode === 1) ? "Spindle/Router" : "Laser";
    var startChoice = ["Automatic by G-code/script", "Operator will start manually", "Handled by separate hardware"][properties.startDevice];
    writeln("; " + devType + " Start: " + startChoice);
  }
  writeln("; Shutdown: " +
    (properties.shutdownMode === 0 ? "Default" :
     properties.shutdownMode === 1 ? "Custom" : "None"));
  writeln("; Axis invert: X=" + (properties.invertX ? "INVERTED" : "NORMAL") + ", Y=" + (properties.invertY ? "INVERTED" : "NORMAL"));

  if (properties.enableTMCSetup && properties.tmcSetupCode) {
    writeln("; --- TMC Driver Setup ---");
    writeln("; User-supplied TMC driver configuration is enabled.");
    writeln("; The following code will be sent before toolpath:");
    var tmcLines = properties.tmcSetupCode.split(/\r?\n/);
    for (var i = 0; i < tmcLines.length; ++i) {
      if (tmcLines[i].trim()) {
        writeln("; " + tmcLines[i]);
      }
    }
    writeln("; --- End TMC Driver Setup ---");
  }

  if (properties.enableTmcDynamic) {
    writeln("; --- Dynamic TMC adjustments enabled ---");
    writeln("; The post will emit TMC commands based on feed thresholds to optimize driver currents.");
    writeln("; Configure templates and thresholds in MultiMode properties.");
    writeln("; WARNING: Dynamic adjustments require firmware support for the emitted commands. Use cautiously.");
  }

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
  if ((properties.machineMode === 1 || properties.machineMode === 2) && properties.startDevice === 0) {
    if (properties.machineMode === 1) { // CNC/Spindle
      writeln("M3 ; Start spindle/router");
    } else if (properties.machineMode === 2) { // LASER
      writeln("M106 ; Laser ON (startup, if needed)");
    }
  }

  // Emit static TMC setup user-supplied
  if (properties.enableTMCSetup && properties.tmcSetupCode) {
    var tmcLines2 = properties.tmcSetupCode.split(/\r?\n/);
    for (var i = 0; i < tmcLines2.length; ++i) {
      if (tmcLines2[i].trim()) {
        writeln(tmcLines2[i]);
      }
    }
  }

  // Emit baseline dynamic TMC if enabled
  if (properties.enableTmcDynamic && properties.tmcEmitAtStartup && properties.tmcBaselineCurrents) {
    var baselineCmd = formatCurrents(properties.tmcCommandTemplate, properties.tmcBaselineCurrents);
    if (baselineCmd) {
      writeln("; Emitting baseline TMC configuration");
      writeln(baselineCmd);
      _lastTmcSet = properties.tmcBaselineCurrents;
      _lastTmcTime = (new Date()).getTime();
    }
  }

  // Typical Marlin setup per selected mode
  if (properties.speedControlMode === 0 || properties.speedControlMode === 2) {
    writeln("M201 X1000 Y1000 Z100 E5000 ; Default accelerations");
    writeln("M204 P1000 T2000 ; Default/travel accel");
    writeln("M205 J0.02 ; Junction deviation");
  }
}

function _applyAxisInvert(x, y) {
  var xo = x;
  var yo = y;
  if (xo !== undefined && properties.invertX) xo = -xo;
  if (yo !== undefined && properties.invertY) yo = -yo;
  return [xo, yo];
}

function formatCurrents(template, currentsStr) { /* unchanged from v1.6.0 */ }

function emitTmcIfNeeded(currentsStr) { /* unchanged from v1.6.0 */ }

function onSection() { /* unchanged */ }

function onLinear(x, y, z, feed) {
  var coords = _applyAxisInvert(x, y);
  var xOut = coords[0], yOut = coords[1];

  var line = "G1";
  if (xOut !== undefined) line += " X" + xOut.toFixed(3);
  if (yOut !== undefined) line += " Y" + yOut.toFixed(3);
  if (z !== undefined) line += " Z" + z.toFixed(3);
  if (feed !== undefined) line += " F" + feed.toFixed(0);

  // Dynamic TMC decision
  if (properties.enableTmcDynamic && feed !== undefined) {
    var desired = properties.tmcBaselineCurrents;
    if (feed >= properties.tmcFeedThresholdHigh) desired = properties.tmcHighCurrents;
    else if (feed <= properties.tmcFeedThresholdLow) desired = properties.tmcBaselineCurrents;
    emitTmcIfNeeded(desired);
  }

  // Mode-specific warnings
  if (properties.machineMode === 0) {
    if (currentSection.getTool && currentSection.getTool().isJetTool && currentSection.getTool().isJetTool()) {
      if (/E[+\-]?\d+(\.\d*)?/.test(line)) {
        writeln("; WARNING: E axis move in Laser mode: " + line);
      }
    }
  } else {
    if (/E[+\-]?\d+(\.\d*)?/.test(line)) {
      writeln("; WARNING: E axis move found: " + line);
    }
  }

  if (properties.speedControlMode === 1) {
    writeln("M204 P" + (feed ? feed : 1000) + " ; Set accel");
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

function onClose() { /* unchanged */ }