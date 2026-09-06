%% Load project configuration

if ~exist('cfg', 'var')
    project_config
end


%% Select baseline case

altitude_km = cfg.orbit.altitude_km;

aoa_deg = cfg.attitude.aoa_deg;
aos_deg = cfg.attitude.aos_deg;

gsi_model = cfg.gsi.baseline_model;


%% Check imported ADBSat model exists

modPath = fullfile( ...
    cfg.paths.model_dir, ...
    [cfg.model.name '.mat']);

if ~isfile(modPath)
    error('ADBSat model file not found: %s', modPath);
end


%% Build atmosphere for displayed dimensional quantities

[param_eq, ~] = build_freestream( ...
    cfg, ...
    altitude_km);


%% Run baseline ADBSat case

fprintf('\nRunning baseline ADBSat case...\n');

fprintf('Model:       %s\n', cfg.model.name);
fprintf('Altitude:    %.1f km\n', altitude_km);
fprintf('AoA:         %.2f deg\n', aoa_deg);
fprintf('AoS:         %.2f deg\n', aos_deg);
fprintf('GSIM:        %s\n\n', gsi_model);

case_out = run_adbsat_case( ...
    cfg, ...
    cfg.model.name, ...
    altitude_km, ...
    aoa_deg, ...
    aos_deg, ...
    gsi_model);


%% Calculate useful baseline quantities

CD_adbsat = -case_out.Cf_w(1);

CD_projected = ...
    CD_adbsat * ...
    case_out.AreaRef_m2 / ...
    case_out.AreaProj_m2;

q = 0.5 * ...
    param_eq.rho(6) * ...
    param_eq.vinf^2;

drag_N = ...
    q * ...
    case_out.AreaRef_m2 * ...
    CD_adbsat;


%% Display key results

fprintf('\n');
fprintf('========================================\n');
fprintf('BASELINE ADBSat RESULTS\n');
fprintf('========================================\n');

fprintf('Model:                %s\n', cfg.model.name);
fprintf('Altitude:             %.1f km\n', altitude_km);
fprintf('AoA:                  %.2f deg\n', aoa_deg);
fprintf('AoS:                  %.2f deg\n', aos_deg);
fprintf('GSIM:                 %s\n', gsi_model);

fprintf('\nProjected area:       %.8g m^2\n', ...
    case_out.AreaProj_m2);

fprintf('Reference area:       %.8g m^2\n', ...
    case_out.AreaRef_m2);

fprintf('ADBSat CD:            %.8f\n', ...
    CD_adbsat);

fprintf('Projected-area CD:    %.8f\n', ...
    CD_projected);

fprintf('Dimensional drag:     %.8e N\n', ...
    drag_N);

fprintf('\nWind-axis force coefficients:\n');
disp(case_out.Cf_w)

fprintf('Body-axis force coefficients:\n');
disp(case_out.Cf_B)

fprintf('Body-axis moment coefficients about CoM:\n');
disp(case_out.Cm_B)

fprintf('Atmospheric density:  %.8e kg/m^3\n', ...
    param_eq.rho(6));

fprintf('Free-stream speed:    %.4f m/s\n', ...
    param_eq.vinf);

fprintf('Speed ratio:          %.6f\n', ...
    param_eq.s);

fprintf('\nBaseline run complete.\n');

fprintf('========================================\n');