// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
// Version: 1.6.2
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
certificationLevel = 2; // Non-Autodesk certified; disables certification error

/*
Version: 1.6.2
Vendor: rflulling
Credits: GitHub Copilot GPT-4.1
*/

capabilities = CAPABILITY_MILLING | CAPABILITY_JET; // Advertise CNC and Laser/Jet support

properties = {
  machineMode: 0,
  speedControlMode: 0,
  autoZero: 0,
  customZero: "X0 Y0 Z0",
  customHeader: "",
  fileExt: 0,
  startDevice: 0,
  shutdownMode: 0,
  customShutdown: "",

  // TMC features
  enableTMCSetup: false,
  tmcSetupCode: "",
  enableTmcDynamic: false,
  tmcCommandTemplate: "M906 X{X} Y{Y} Z{Z}",
  tmcBaselineCurrents: "X800 Y800 Z800",
  tmcHighCurrents: "X1200 Y1200 Z1000",
  tmcFeedThresholdHigh: 2500,
  tmcFeedThresholdLow: 800,
  tmcMinIntervalMs: 1000,
  tmcDedupe: true,
  tmcEmitAtStartup: true,

  // Axis inversion
  invertX: false,
  invertY: false
};

propertyDefinitions = {
  machineMode: {
    title: "Machine Mode",
    description: "Select Marlin machine mode: FDM (3D printing), CNC (milling), Laser",
    type: "integer",
    values: [
      { title: "FDM (3D Printer)", id: 0 },
      { title: "CNC (Milling)", id: 1 },
      { title: "Laser", id: 2 }
    ],
    default_mm: 0,
    default_in: 0
  },
  speedControlMode: {
    title: "Speed Control Mode",
    description: "Firmware: Let Marlin manage motion. G-code: Per-move feed/accel/jerk. Magic: Advanced dynamic hybrid.",
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
  enableTMCSetup: {
    title: "Enable TMC Driver Setup",
    description: "If enabled, user-supplied TMC driver G/M-codes will be output after startup.",
    type: "boolean",
    default_mm: false,
    default_in: false
  },
  tmcSetupCode: {
    title: "TMC Driver Setup Code",
    description: "Advanced users: Insert Marlin M-codes for TMC configuration (e.g., M906/M913/M569). One per line.",
    type: "string",
    default_mm: "",
    default_in: ""
  },
  enableTmcDynamic: {
    title: "Enable Dynamic TMC Adjustments",
    description: "Automatically adjust TMC driver parameters during the job based on move feed/length heuristics.",
    type: "boolean",
    default_mm: false,
    default_in: false
  },
  tmcCommandTemplate: {
    title: "TMC Command Template",
    description: "Template for TMC commands. Use placeholders {X} {Y} {Z} for axis values. Example: M906 X{X} Y{Y} Z{Z}",
    type: "string",
    default_mm: "M906 X{X} Y{Y} Z{Z}",
    default_in: "M906 X{X} Y{Y} Z{Z}"
  },
  tmcBaselineCurrents: {
    title: "TMC Baseline Currents",
    description: "Baseline current values for axes (e.g., X800 Y800 Z800)",
    type: "string",
    default_mm: "X800 Y800 Z800",
    default_in: "X800 Y800 Z800"
  },
  tmcHighCurrents: {
    title: "TMC High Currents",
    description: "Higher current set for heavy/high-speed moves (e.g., X1200 Y1200 Z1000)",
    type: "string",
    default_mm: "X1200 Y1200 Z1000",
    default_in: "X1200 Y1200 Z1000"
  },
  tmcFeedThresholdHigh: {
    title: "Feed Threshold High",
    description: "Feed (F) at or above which high currents are requested",
    type: "integer",
    default_mm: 2500,
    default_in: 2500
  },
  tmcFeedThresholdLow: {
    title: "Feed Threshold Low",
    description: "Feed (F) at or below which baseline currents are used",
    type: "integer",
    default_mm: 800,
    default_in: 800
  },
  tmcMinIntervalMs: {
    title: "Min Interval between TMC commands (ms)",
    description: "Minimum milliseconds between emitted TMC commands to avoid spamming controller",
    type: "integer",
    default_mm: 1000,
    default_in: 1000
  },
  tmcDedupe: {
    title: "Dedupe identical TMC commands",
    description: "If enabled, the post will not resend the same TMC setting repeatedly",
    type: "boolean",
    default_mm: true,
    default_in: true
  },
  tmcEmitAtStartup: {
    title: "Emit Baseline at Startup",
    description: "Emit the baseline TMC command at startup if dynamic mode is enabled",
    type: "boolean",
    default_mm: true,
    default_in: true
  },
  invertX: {
    title: "Invert X Axis",
    description: "Negate X coordinates before output. Use if Fusion360 X direction is opposite of machine X.",
    type: "boolean",
    default_mm: false,
    default_in: false
  },
  invertY: {
    title: "Invert Y Axis",
    description: "Negate Y coordinates before output. Use if Fusion360 Y direction is opposite of machine Y.",
    type: "boolean",
    default_mm: false,
    default_in: false
  }
};

var machineModeLabels = ["FDM", "CNC", "LASER"];
var speedModeLabels = ["Firmware", "Gcode", "Magic"];
var _lastTmcSet = "";
var _lastTmcTime = 0;

function onOpen() {
  extension = properties.fileExt === 1 ? "nc" : "gcode";
  writeln("; ==============================================");
  writeln("; Marlin Multi-Mode Post - Mode: " + machineModeLabels[properties.machineMode] + " | Speed: " + speedModeLabels[properties.speedControlMode]);
  writeln("; Vendor: rflulling | Version: 1.6.2 | Credits: GitHub Copilot GPT-4.1");
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
  if ((properties.machineMode === 1 || properties.machineMode === 2) && properties.startDevice === 0) {
    if (properties.machineMode === 1) {
      writeln("M3 ; Start spindle/router");
    } else if (properties.machineMode === 2) {
      writeln("M106 ; Laser ON (startup, if needed)");
    }
  }
  if (properties.enableTMCSetup && properties.tmcSetupCode) {
    var tmcLines2 = properties.tmcSetupCode.split(/\r?\n/);
    for (var i = 0; i < tmcLines2.length; ++i) {
      if (tmcLines2[i].trim()) {
        writeln(tmcLines2[i]);
      }
    }
  }
  if (properties.enableTmcDynamic && properties.tmcEmitAtStartup && properties.tmcBaselineCurrents) {
    var baselineCmd = formatCurrents(properties.tmcCommandTemplate, properties.tmcBaselineCurrents);
    if (baselineCmd) {
      writeln("; Emitting baseline TMC configuration");
      writeln(baselineCmd);
      _lastTmcSet = properties.tmcBaselineCurrents;
      _lastTmcTime = (new Date()).getTime();
    }
  }
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

function formatCurrents(template, currentsStr) {
  if (!template || !currentsStr) return "";
  var map = { X: "", Y: "", Z: "" };
  var parts = currentsStr.trim().split(/\s+/);
  for (var i = 0; i < parts.length; ++i) {
    var m = parts[i].match(/^([XYZ])\s*([+\-]?\d+(\.\d+)?)$/i);
    if (m) map[m[1].toUpperCase()] = m[2];
  }
  var out = template.replace(/\{X\}/g, map.X || "").replace(/\{Y\}/g, map.Y || "").replace(/\{Z\}/g, map.Z || "");
  return out.trim();
}

function emitTmcIfNeeded(currentsStr) {
  if (!properties.enableTmcDynamic || !properties.tmcCommandTemplate || !currentsStr) return;
  var now = (new Date()).getTime();
  if (properties.tmcDedupe) {
    if (currentsStr === _lastTmcSet && (now - _lastTmcTime) < properties.tmcMinIntervalMs) return;
  } else {
    if ((now - _lastTmcTime) < properties.tmcMinIntervalMs) return;
  }
  var cmd = formatCurrents(properties.tmcCommandTemplate, currentsStr);
  if (cmd && cmd.length) {
    writeln(cmd);
    _lastTmcSet = currentsStr;
    _lastTmcTime = now;
  }
}

function onSection() {}

function onLinear(x, y, z, feed) {
  var coords = _applyAxisInvert(x, y);
  var xOut = coords[0], yOut = coords[1];
  var line = "G1";
  if (xOut !== undefined) line += " X" + xOut.toFixed(3);
  if (yOut !== undefined) line += " Y" + yOut.toFixed(3);
  if (z !== undefined) line += " Z" + z.toFixed(3);
  if (feed !== undefined) line += " F" + feed.toFixed(0);
  if (properties.enableTmcDynamic && feed !== undefined) {
    var desired = properties.tmcBaselineCurrents;
    if (feed >= properties.tmcFeedThresholdHigh) desired = properties.tmcHighCurrents;
    else if (feed <= properties.tmcFeedThresholdLow) desired = properties.tmcBaselineCurrents;
    emitTmcIfNeeded(desired);
  }
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

function onClose() {
  if (properties.machineMode === 1 || properties.machineMode === 2) {
    if (properties.shutdownMode === 0) {
      writeln("G28 Z ; Retract Z axis");
      if (properties.machineMode === 1) {
        writeln("M5 ; Spindle/Router OFF");
      } else {
        writeln("M107 ; Laser OFF");
      }
      writeln("G28 Y0 ; Home Y");
      writeln("G28 X0 ; Home X");
    } else if (properties.shutdownMode === 1 && properties.customShutdown) {
      var lines = properties.customShutdown.split(/\r?\n/);
      for (var i = 0; i < lines.length; ++i) {
        writeln(lines[i]);
      }
    }
  }
  writeln("; End of program");
}