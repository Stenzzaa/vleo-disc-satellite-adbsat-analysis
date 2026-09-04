%% project_config.m
% Central configuration for the VLEO disc ADBSat study.
% ADBSat source/example files are kept unchanged.

clear cfg

set(groot, ...
    'defaultFigureColor','w', ...
    'defaultAxesColor','w', ...
    'defaultAxesXColor','k', ...
    'defaultAxesYColor','k', ...
    'defaultTextColor','k');

%% Project folders

% Folder containing project_config.m
cfg.paths.project_root = fileparts(mfilename('fullpath'));

% Original ADBSat installation
cfg.paths.adbsat_root = ...
    'C:\Users\Samsung\Downloads\ADBSat-master\ADBSat-master';

% ADBSat folders
cfg.paths.obj_dir = fullfile( ...
    cfg.paths.adbsat_root, 'inou', 'obj_files');

cfg.paths.model_dir = fullfile( ...
    cfg.paths.adbsat_root, 'inou', 'models');

cfg.paths.adbsat_results_dir = fullfile( ...
    cfg.paths.adbsat_root, 'inou', 'results');

%% Model

% Current final spacecraft geometry
cfg.model.name = 'disc_lenticular_v03';

% Centre of mass relative to mesh/CAD origin
% expressed in ADBSat geometric axes [m]

%% Centre of mass
% Geometric-centre reference used for validation and CoM sensitivity
cfg.model.com_reference_G_m = [ ...
    0;
    0;
    0];

% Selected nominal design CoM
% Approximately 6 mm forward (+X) of the geometric centre
cfg.model.com_design_G_m = [ ...
    0.006;
    0;
    0];

% Active CoM used by the main aerodynamic analyses
cfg.model.com_G_m = cfg.model.com_design_G_m;


%% Project results folder
% Separate result folder for this geometry
cfg.paths.project_results_dir = fullfile( ...
    cfg.paths.project_root, ...
    'results', ...
    cfg.model.name);

if ~exist(cfg.paths.project_results_dir, 'dir')
    mkdir(cfg.paths.project_results_dir);
end


%% Baseline orbit and atmospheric inputs
% Baseline altitude [km]
cfg.orbit.altitude_km = 300;

% Orbital inclination [deg]
cfg.orbit.inclination_deg = 0;

% Atmospheric model location and time
cfg.env.latitude_deg = 0;
cfg.env.longitude_deg = 0;
cfg.env.day_of_year = 1;
cfg.env.ut_seconds = 0;

% Solar activity indices
cfg.env.f107_average = 65;
cfg.env.f107_daily = 65;

% Seven geomagnetic Ap values
cfg.env.ap = 3 * ones(1,7);

% Anomalous oxygen flag
cfg.env.anomalous_oxygen = 0;


%% Baseline attitude
% Nominal edge-on aerodynamic attitude
cfg.attitude.aoa_deg = 0;
cfg.attitude.aos_deg = 0;


%% ADBSat flags

% Include aerodynamic shadowing
cfg.flags.shadow = 1;

% Solar radiation pressure disabled
cfg.flags.solar = 0;

% Keep temporary files
cfg.flags.delete_temp = 0;

% Display detailed ADBSat output
cfg.flags.verbose = 1;


%% Gas-surface interaction settings

% Baseline gas-surface interaction model
cfg.gsi.baseline_model = 'sentman';

% Sentman energy accommodation coefficient
cfg.gsi.sentman.alpha = 1.0;

% Spacecraft surface temperature [K]
cfg.gsi.wall_temperature_K = 300;

% CLL sensitivity model
cfg.gsi.cll.model = 'CLL';
cfg.gsi.cll.alphaN = 1.0;
cfg.gsi.cll.sigmaT = 1.0;


%% Analysis ranges

% Altitude sweep [km]
cfg.test.altitude_km = 200:50:400;

% Standard attitude sweep [deg]
cfg.test.aoa_deg = -30:5:30;
cfg.test.aos_deg = 0;

% Small-angle diagnostic around nominal edge-on orientation [deg]
cfg.test.small_angle_deg = [-0.1, 0, 0.1];

% Sentman accommodation sensitivity
cfg.test.sentman_alpha = [1.0, 0.9, 0.8, 0.4];

% CLL accommodation sensitivity
cfg.test.cll_alphaN = [1.0, 0.8];
cfg.test.cll_sigmaT = [1.0, 0.8];


%% High-agility attitude study

% Wide AoA range from face-on through edge-on to face-on
cfg.high_agility.aoa_deg = [ ...
    -90, -75, -60, -45, -30, -20, -15, -10, -5, ...
    -2, -1, -0.5, -0.1, ...
     0, ...
     0.1, 0.5, 1, 2, 5, 10, 15, 20, 30, 45, 60, 75, 90];

% Nominal sideslip for primary high-agility sweep
cfg.high_agility.aos_deg = 0;


%% Final dissertation cases

% These can be populated after baseline and mesh verification
cfg.final.altitude_km = [];
cfg.final.aoa_deg = [];
cfg.final.aos_deg = [];

cfg.final.sentman_alpha = [];
cfg.final.cll_alphaN = [];
cfg.final.cll_sigmaT = [];


%% Free-molecular-flow verification

% Characteristic spacecraft length [m]
% Disc maximum diameter used as conservative characteristic length
cfg.fmf.characteristic_length_m = 1.0;

% Effective hard-sphere collision diameter [m]
cfg.fmf.collision_diameter_m = 3.7e-10;

% Conventional free-molecular-flow threshold
cfg.fmf.free_molecular_threshold = 10;


%% Mesh sensitivity settings

cfg.mesh.model_names = { ...
    'disc_lenticular_v03_coarse', ...
    'disc_lenticular_v03_medium', ...
    'disc_lenticular_v03'};

cfg.mesh.labels = { ...
    'Coarse', ...
    'Medium', ...
    'Fine'};

% Final convergence cases [AoA, AoS] in degrees
cfg.mesh.test_cases_deg = [ ...
    -30, 0;
      0, 0;
     30, 0];

%% Local stability analysis

% Small perturbation points used for local aerodynamic derivatives
cfg.stability.angle_deg = [ ...
    -1, -0.5, -0.1, 0, 0.1, 0.5, 1];

% Narrow diagnostic points very close to nominal attitude
cfg.stability.diagnostic_deg = [-0.1, 0, 0.1];

% Minimum R-squared used as a warning for local linearity
cfg.stability.min_R2 = 0.98;


%% Environmental sensitivity

cfg.env_sensitivity.labels = { ...
    'Quiet', ...
    'Reference', ...
    'Elevated'};

cfg.env_sensitivity.f107_average = [ ...
    65, ...
    150, ...
    220];

cfg.env_sensitivity.f107_daily = [ ...
    65, ...
    150, ...
    220];

cfg.env_sensitivity.ap_daily = [ ...
    3, ...
    4, ...
    40];