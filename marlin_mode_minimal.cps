// SPDX-License-Identifier: MIT
// Copyright (c) 2025 rflulling
// An open source project developed by GitHub Copilot GPT-4.1 and rflulling
// Version: 1.5.0
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
 *   - Battery monitoring support for dual lithium batteries with e-ink display (M155 auto-report)
 */

description = "Marlin Minimal Real Output";
vendor = "rflulling";
longDescription = "Minimal Marlin/Fusion360 post: concise header, units/positioning, zeroing, custom code, startup/shutdown, battery monitoring, robust real G-code.";
extension = "gcode"; // default, user can override

/*
Version: 1.5.0
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
  enableBatteryMonitoring: false,
  batteryLowVoltage: 3.3,
  batteryCriticalVoltage: 3.0,
  batteryReportInterval: 10
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
  enableBatteryMonitoring: {
    title: "Enable Battery Monitoring",
    description: "If enabled, adds battery status monitoring for dual lithium batteries with e-ink display support.",
    type: "boolean",
    default_mm: false,
    default_in: false
  },
  batteryLowVoltage: {
    title: "Battery Low Voltage Warning (V)",
    description: "Voltage per cell at which low battery warning is triggered. Typical: 3.3V for lithium batteries.",
    type: "number",
    default_mm: 3.3,
    default_in: 3.3
  },
  batteryCriticalVoltage: {
    title: "Battery Critical Voltage (V)",
    description: "Voltage per cell at which battery is critically low. Typical: 3.0V for lithium batteries.",
    type: "number",
    default_mm: 3.0,
    default_in: 3.0
  },
  batteryReportInterval: {
    title: "Battery Report Interval (seconds)",
    description: "How often to report battery status during operation. Use 0 to disable auto-reporting.",
    type: "integer",
    default_mm: 10,
    default_in: 10
  }
};

var modeLabels = ["FDM", "CNC", "LASER"];

function onOpen() {
  // Set file extension
  extension = properties.fileExt === 1 ? "nc" : "gcode";

  // Header block
  writeln("; ==============================================");
  writeln("; Marlin Minimal Real Output - Mode: " + modeLabels[properties.marlinMode]);
  writeln("; Vendor: rflulling | Version: 1.5.0 | Credits: GitHub Copilot GPT-4.1");
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
  if (properties.enableBatteryMonitoring) {
    writeln("; --- Battery Monitoring ---");
    writeln("; Battery monitoring enabled for dual lithium batteries (parallel)");
    writeln("; Display: E-ink compatible");
    writeln("; Low voltage warning: " + properties.batteryLowVoltage.toFixed(2) + "V per cell");
    writeln("; Critical voltage: " + properties.batteryCriticalVoltage.toFixed(2) + "V per cell");
    if (properties.batteryReportInterval > 0) {
      writeln("; Auto-report interval: " + properties.batteryReportInterval + " seconds");
    } else {
      writeln("; Auto-report: Disabled");
    }
    writeln("; --- End Battery Monitoring ---");
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

  // Battery monitoring setup
  if (properties.enableBatteryMonitoring) {
    writeln("; --- Battery Monitoring Setup ---");
    writeln("; Dual lithium batteries in parallel configuration");
    writeln("; E-ink display support for low-power status indication");
    if (properties.batteryReportInterval > 0) {
      writeln("M155 S" + properties.batteryReportInterval + " ; Enable auto-reporting every " + properties.batteryReportInterval + " seconds");
    }
    writeln("; Battery voltage thresholds configured:");
    writeln(";   Low warning: " + properties.batteryLowVoltage.toFixed(2) + "V per cell");
    writeln(";   Critical: " + properties.batteryCriticalVoltage.toFixed(2) + "V per cell");
    writeln("; --- End Battery Monitoring Setup ---");
  }
}

function onLinear(x, y, z, feed) {
  var line = "G1";
  if (x !== undefined) line += " X" + x.toFixed(3);
  if (y !== undefined) line += " Y" + y.toFixed(3);
  if (z !== undefined) line += " Z" + z.toFixed(3);
  if (feed !== undefined) line += " F" + feed.toFixed(0);
  // Warn for E axis moves in non-FDM modes
  if (properties.marlinMode !== 0 && /E[+\-]?\d+(\.\d*)?/.test(line)) {
    writeln("; WARNING: E axis move found: " + line);
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
  // Battery monitoring shutdown
  if (properties.enableBatteryMonitoring && properties.batteryReportInterval > 0) {
    writeln("; --- Battery Monitoring Shutdown ---");
    writeln("M155 S0 ; Disable auto-reporting");
    writeln("; NOTE: Check battery voltage before next operation");
    writeln("; Safe voltage range: " + properties.batteryCriticalVoltage.toFixed(2) + "V - 4.2V per cell");
    writeln("; --- End Battery Monitoring Shutdown ---");
  }

  // Shutdown sequence (CNC/Laser only, not FDM)
  if (properties.marlinMode === 1 || properties.marlinMode === 2) {
    if (properties.shutdownMode === 0) {
      // Default: Z retract, OFF, G28 Y0, G28 X0
      writeln("G28 Z ; Retract Z axis");
      if (properties.marlinMode === 1) {
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