# Boeing 929 Jetfoil — NACA 0012 Hydrofoil Aerodynamic Analysis

## Overview

This project performs a comprehensive aerodynamic analysis of a **NACA 0012 submerged hydrofoil** used in the Boeing 929 Jetfoil vessel. It calculates and visualizes lift, drag, efficiency, and performance characteristics across a range of angles of attack and velocities using validated aerodynamic coefficients.

## Purpose

To provide engineers and students with:
- Accurate aerodynamic modeling of hydrofoil behavior in seawater
- Performance metrics critical for vessel design and operation
- Publication-ready visualizations for technical reports and presentations
- A reference implementation for submerged foil analysis

## Key Features

✓ **Validated Physics**: Based on NACA sources (Abbott & von Doenhoff, Ladson et al., Sheldahl & Klimas)  
✓ **Realistic Parameters**: Boeing 929 specifications (98,000 kg vessel, 21.6 m/s cruise speed, 18 m² foil area)  
✓ **Comprehensive Analysis**:
  - Lift coefficient (C_L) modeling with realistic stall behavior
  - Drag coefficient (C_D) with post-stall calibration
  - Lift-to-drag efficiency (L/D) optimization
  - Take-off velocity calculations across operating angles
  - Cruise operating point analysis

✓ **5 Professional Visualizations**:
  1. C_L & C_D vs Angle of Attack (dual-axis)
  2. Aerodynamic Efficiency (L/D)
  3. Lift Force vs Velocity at multiple angles
  4. Drag Polar (C_L vs C_D)
  5. 2×2 Performance Summary Dashboard

✓ **High-Resolution Export**: 300 DPI PNG files ready for Google Docs, papers, and presentations

## Requirements

- **MATLAB** R2019b or later
- (No external toolboxes required — uses only base MATLAB functions)

## Installation

1. **Download** the `.m` file to your machine
2. **Open** MATLAB
3. **Navigate** to the folder containing the script
4. **Run** the file (or press `Ctrl+Enter`)

## Usage

```matlab
% Simply run the script
Mini_Project6_Hydrofoil_Corrected.m
```

**Output**:
- 5 figure windows with publication-quality plots
- Console output with performance summary table
- Folder `Hydrofoil_Figures/` containing 5 PNG files at 300 DPI

**Tip**: Set PNG image width to ~14 cm for full-column layout in Google Docs.

## Key Results

| Parameter | Value |
|-----------|-------|
| **Vessel Weight** | 961.4 kN (98 tonnes) |
| **Foil Area** | 18.0 m² |
| **Chord Length** | 1.8 m |
| **Reynolds Number** | ~3.45 × 10⁷ |
| **Cruise Speed** | 21.6 m/s (42 knots) |
| **Cruise AoA** | 5° |
| **Max C_L** | 1.52 @ 11° |
| **Min C_D** | 0.006 |
| **Best L/D** | ~30 @ 9° |
| **Stall Angle** | ±11° |
| **Take-off Speed (6°)** | 11.3 m/s (22 knots) |

## Project Structure

```
├── Mini_Project6_Hydrofoil_Corrected.m    # Main analysis script
├── README.md                               # This file
└── Hydrofoil_Figures/                      # Output folder (auto-created)
    ├── Fig1_CL_and_CD.png
    ├── Fig2_LD_Efficiency.png
    ├── Fig3_Lift_vs_Velocity.png
    ├── Fig4_Drag_Polar.png
    └── Fig5_Dashboard_Summary.png
```

## Code Overview

**Sections**:
1. **Global Plot Styling** — Colorblind-safe palette, professional formatting
2. **Vessel Parameters** — Boeing 929 specifications and fluid properties
3. **Aerodynamic Coefficients** — NACA 0012 C_L, C_D, C_M modeling
4. **Operating Point Analysis** — Cruise, stall, take-off calculations
5. **Figure Generation** — 5 publication-ready plots
6. **Performance Summary** — Console table with key metrics
7. **Export** — 300 DPI PNG export for documents

## Physics Validated Against

- **Thin-Airfoil Theory**: dC_L/dα = 2π ≈ 0.1095/deg
- **Stall Behavior**: Smooth cosine roll-off (NACA 0012 @ Re~10⁷)
- **Drag Polar**: Parabolic + post-stall cubic rise
- **Post-Stall Calibration**: Sheldahl & Klimas (SAND80-2114)
- **High-Re Turbulent Flow**: CD_min = 0.006 typical for flat plate

## References

1. Abbott, I. H., & von Doenhoff, A. E. (1959). *Theory of wing sections*. Dover Publications.
2. Ladson, C. L., et al. (1988). *Compilation and analysis of high-Reynolds-number airfoil data*. NASA TM-100526.
3. Sheldahl, R. E., & Klimas, P. C. (1981). *Aerodynamic characteristics of seven symmetric airfoil sections through 180-degree angle of attack*. Sandia National Labs, SAND80-2114.
4. XFOIL documentation — Open-source airfoil analysis tool.

## Notes for Users

- **Operational Range**: Hydrofoils typically operate 4°–8° AoA; analysis shows −4° to +18° for completeness
- **Cruise Design**: 5° AoA selected for control authority and stability margin, not just minimum drag
- **Velocity Unit Conversion**: 1 knot = 0.5144 m/s, or m/s × 1.944 = knots
- **Reynolds Impact**: Results valid for Re ≈ 10⁷ (fully turbulent boundary layer)
- **Figure Quality**: All exports at 300 DPI, suitable for print and high-res documents

## License

Educational use. Validation based on publicly available aerodynamic data from NACA and Sandia National Laboratories.

## Contact

For questions or improvements, refer to project documentation or consult aerodynamic analysis standards (e.g., AIAA, ISO 11019).

---
