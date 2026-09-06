# VLEO Disc Satellite Aerodynamic Analysis

Supplementary code and results for **Design and Aerodynamic Assessment of a Disc-Shaped Satellite for Optical Remote Sensing**, MSc Aerospace Engineering, The University of Manchester, Malik Zain, 2026.

This repository supports the aerodynamic assessment of a conceptual lenticular spacecraft with an integrated telescope envelope and baffle. It includes attitude, altitude, atmospheric and gas–surface interaction sensitivities, centre-of-mass trades, mesh and sphere verification, and an idealised agility assessment.

## Repository contents

* Top-level MATLAB scripts: configuration, analysis and figure generation.
* `FINAL_WRITEUP_RESULTS/`: the curated results, configuration snapshot, imported fine disc model and dissertation figure exports.
* `results/disc_lenticular_v03/`: saved disc mesh-convergence calculations and supporting records.
* `results/sphere_validation/`: saved sphere panel calculations, continuous-reference comparison and supporting records.

CSV files can be inspected directly. MAT files contain MATLAB models, calculation outputs or metadata. The dissertation provides the methods, interpretation and limitations.

The project helper `build_environment.m` constructs the atmospheric input array used by `build_freestream.m`.

## Setup

1. Download and extract the repository. Set MATLAB’s Current Folder to the folder containing `project_config.m`.
2. Install ADBSat and change `cfg.paths.adbsat_root` in `project_config.m` to its location on your computer.
3. Copy `disc_lenticular_v03.mat` from `FINAL_WRITEUP_RESULTS/01_Geometry_and_Mesh/` into the ADBSat installation’s `inou/models/` folder.
4. Add ADBSat to the MATLAB path:

```matlab
clear
project_config
addpath(genpath(cfg.paths.adbsat_root))
```

5. Check that the required functions can be located:

```matlab
which ADBSatFcn -all
which environment -all
which build_environment -all
```

The supplied fine model contains 8,800 panels. Repeating disc mesh convergence additionally requires the original `disc_lenticular_v03_coarse.mat` and `disc_lenticular_v03_medium.mat` in the configured model folder.

Regenerating sphere panel calculations requires the corresponding original sphere model inputs. Saved calculation outputs do not contain the imported `meshdata` structure and cannot substitute for those inputs.

## Running the analysis

After setup, run:

```matlab
run_project_analysis
```

By default, the controller performs the model preflight check, baseline aerodynamic calculation and free-molecular-flow check. Other analysis flags are initially disabled.

The nominal case uses a 300 km altitude, zero pitch and sideslip, fully accommodating Sentman conditions, a 300 K wall temperature, aerodynamic shadowing and the selected [+6, 0, 0] mm centre of mass in geometric axes.

For individual studies, reload `project_config` and run the relevant script. Check its case-specific settings before execution.

| Study                                  | Scripts                                                                          |
| -------------------------------------- | -------------------------------------------------------------------------------- |
| Operational attitude                   | `attitude_sweep.m`, `sideslip_sweep.m`                                           |
| Altitude and atmosphere                | `altitude_sweep.m`, `environment_sensitivity.m`                                  |
| Accommodation and GSI                  | `accommodation_sensitivity.m`, `accommodation_offnominal.m`, `gsi_sensitivity.m` |
| Material-informed surfaces             | `material_surface_comparison.m`                                                  |
| Centre-of-mass trade                   | `com_xz_sensitivity_v03.m`                                                       |
| Local pitch and stability              | `small_angle_check.m`, `stability_com_trade_shadowON_v03.m`                      |
| Shadow-off diagnostic                  | `small_angle_shadow_diagnostic.m`                                                |
| Disc mesh convergence                  | `mesh_sensitivity.m`                                                             |
| Extended attitudes                     | `high_agility_assessment.m`                                                      |
| Conceptual mass properties and agility | `mass_properties_agility_assessment.m`                                           |

Analysis outputs are written to `results/disc_lenticular_v03/`. Use a separate working copy for reruns to preserve the archived outputs.

## Sphere verification

The sphere calculations include 240-, 480- and 960-panel meshes. The continuous-reference comparison uses the saved 960-panel case and integrates the ADBSat Sentman formulation over an exact sphere.

To repeat this comparison, replace the hard-coded `project_root` assignment in `sphere_continuous_reference.m` with:

```matlab
project_root = fileparts(mfilename('fullpath'));
```

Keep the supplied files in `results/sphere_validation/`, add ADBSat to the MATLAB path and run:

```matlab
sphere_continuous_reference
```

This repeats the comparison against the saved panel calculation. It does not regenerate the sphere mesh or rerun its panel calculation.

## Figure generation

* `figure_4_3_accommodation_sensitivity.m` plots the numerical results embedded in the script.
* `figure_4_5_com_stability.m` reads `com_xz_sensitivity_v03.mat` and `small_angle_pitch_summary.mat`. Copy these from `FINAL_WRITEUP_RESULTS/07_CoM_and_Stability/` into `results/disc_lenticular_v03/` before running it.
* `plot_final_mesh_figure.m` requires the original `disc_lenticular_v03.obj` in the configured `cfg.paths.obj_dir`.

## Result conventions

Exact zero pitch is retained as a baseline but excluded from the reported local stability fit. Distinguish coefficients normalised by ADBSat’s fixed reference area from those normalised by projected area.

The shadow-off diagnostic CSV contains the body-z force coefficient under the original column name `CFz_B`.

Surface sensitivities and idealised agility estimates should be interpreted within the modelling limitations stated in the dissertation. A permanent GitHub commit link identifies the particular archive version cited in Appendix C.
