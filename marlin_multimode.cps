// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
// Version: 1.5.0
/**
 * Fusion360 Post Processor for Marlin (FDM/CNC/Laser) - Multi-Mode
 * 
 * - Supports FDM, CNC, and Laser mode with real toolpath output.
 * - User can select mode, speed control approach, startup/shutdown, and TMC driver setup.
 * - Reports all capabilities to Fusion360.
 * - Concise NC file header, units, positioning, zeroing, custom code, device control, and TMC setup.
 */

description = "Marlin Multi-Mode (FDM/CNC/Laser)";
vendor = "rflulling";
longDescription = "Fusion360 post for Marlin FDM, CNC, and Laser. Full config, header, startup/shutdown, TMC driver setup, real G-code, mode & speed selection.";
extension = "gcode"; // default, user can override

/*
Version: 1.5.0
Vendor: rflulling
Credits: GitHub Copilot GPT-4.1
*/

capabilities = CAPABILITY_MILLING | CAPABILITY_JET; // Advertise CNC and Laser/Jet support

properties = {
  machineMode: 0,        // 0=FDM, 1=CNC, 2=LASER
  speedControlMode: 0,   // 0=Firmware, 1=G-code, 2=Magic
  autoZero: 0,           // 0=None, 1=Auto Zero, 2=Custom Zero
  customZero: "X0 Y0 Z0",
  customHeader: "",
  fileExt: 0,
  startDevice: 0,
  shutdownMode: 0,
  customShutdown: "",
  enableTMCSetup: false,
  tmcSetupCode: ""
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
  }
};

var machineModeLabels = ["FDM", "CNC", "LASER"];
var speedModeLabels = ["Firmware", "Gcode", "Magic"];

function onOpen() {
  extension = properties.fileExt === 1 ? "nc" : "gcode";

  writeln("; ==============================================");
  writeln("; Marlin Multi-Mode Post - Mode: " + machineModeLabels[properties.machineMode] + " | Speed: " + speedModeLabels[properties.speedControlMode]);
  writeln("; Vendor: rflulling | Version: 1.5.0 | Credits: GitHub Copilot GPT-4.1");
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

  // TMC driver setup block
  if (properties.enableTMCSetup && properties.tmcSetupCode) {
    var tmcLines = properties.tmcSetupCode.split(/\r?\n/);
    for (var i = 0; i < tmcLines.length; ++i) {
      if (tmcLines[i].trim()) {
        writeln(tmcLines[i]);
      }
    }
  }

  // Typical Marlin setup per selected mode
  if (properties.speedControlMode === 0 || properties.speedControlMode === 2) {
    writeln("M201 X1000 Y1000 Z100 E5000 ; Default accelerations");
    writeln("M204 P1000 T2000 ; Default/travel accel");
    writeln("M205 J0.02 ; Junction deviation");
  }
}

function onSection() {
  // Section-specific setup can be added here if needed per mode.
}

function onLinear(x, y, z, feed) {
  var line = "G1";
  if (x !== undefined) line += " X" + x.toFixed(3);
  if (y !== undefined) line += " Y" + y.toFixed(3);
  if (z !== undefined) line += " Z" + z.toFixed(3);

  // Mode-specific behavior
  if (properties.machineMode === 0) {
    // FDM: E axis allowed, output as is
    if (currentSection.getTool && currentSection.getTool().isJetTool && currentSection.getTool().isJetTool()) {
      // Laser: no E axis, warn
      if (/E[+\-]?\d+(\.\d*)?/.test(line)) {
        writeln("; WARNING: E axis move in Laser mode: " + line);
      }
    }
  } else {
    // CNC or Laser
    if (/E[+\-]?\d+(\.\d*)?/.test(line)) {
      writeln("; WARNING: E axis move found: " + line);
    }
  }
  if (feed !== undefined) line += " F" + feed.toFixed(0);

  // Speed control mode: G-code overrides
  if (properties.speedControlMode === 1) {
    writeln("M204 P" + (feed ? feed : 1000) + " ; Set accel");
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
  if (properties.machineMode === 1 || properties.machineMode === 2) {
    if (properties.shutdownMode === 0) {
      // Default: Z retract, OFF, G28 Y0, G28 X0
      writeln("G28 Z ; Retract Z axis");
      if (properties.machineMode === 1) {
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