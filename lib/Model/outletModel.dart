// ... (Existing Enums and PduDevice/Rack/Location classes remain the same) ...

class OutletData {
  final String id;
  final bool isOn;

  // Electrical Parameters
  final double current;      // Amps
  final double voltage;      // Volts
  final double activePower;  // kWatt
  final double energy;       // kWattHr
  final double powerFactor;  // PF
  final double frequency;    // Hz
  final double apparentPower;// VA

  OutletData({
    required this.id,
    this.isOn = true,
    this.current = 0.0,
    this.voltage = 0.0,
    this.activePower = 0.0,
    this.energy = 0.0,
    this.powerFactor = 0.0,
    this.frequency = 0.0,
    this.apparentPower = 0.0,
  });
}

// ... (StaticData class remains the same) ...