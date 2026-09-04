%% run_project_analysis.m
% Master controller for the VLEO ADBSat analysis framework.
% Runs the main aerodynamic analyses required for the project.
% Individual scripts remain available for separate testing.

clear
clc
close all

%% Load configuration

project_config

%% Confirm selected model

fprintf('Selected model: %s\n', cfg.model.name);

if ~strcmp(cfg.model.name, 'disc_lenticular_v03')
    error('Unexpected model selected. Check project_config.m.');
end

%% Analysis selection

run_self_test      = false;
run_baseline       = true;
run_fmf            = true;
run_altitude       = false;
run_environment    = false;
run_attitude       = false;
run_small_angle    = false;
run_gsi            = false;
run_mesh           = false;


% Mesh convergence is normally run separately because it requires
% multiple mesh versions of the same geometry.

%% Record analysis-selection settings

run_flags = struct;

run_flags.self_test   = run_self_test;
run_flags.baseline    = run_baseline;
run_flags.fmf         = run_fmf;
run_flags.altitude    = run_altitude;
run_flags.environment = run_environment;
run_flags.attitude    = run_attitude;
run_flags.small_angle = run_small_angle;
run_flags.gsi         = run_gsi;
run_flags.mesh        = run_mesh;

%% Display project setup

fprintf('\n');
fprintf('====================================================\n');
fprintf('VLEO ADBSat PROJECT ANALYSIS\n');
fprintf('====================================================\n');

fprintf('Model:             %s\n', cfg.model.name);
fprintf('Baseline altitude: %.1f km\n', cfg.orbit.altitude_km);
fprintf('Baseline AoA:      %.2f deg\n', cfg.attitude.aoa_deg);
fprintf('Baseline AoS:      %.2f deg\n', cfg.attitude.aos_deg);
fprintf('Baseline GSIM:     %s\n', cfg.gsi.baseline_model);

fprintf('\nCentre of mass [geometric axes, m]:\n');
disp(cfg.model.com_G_m)

fprintf('====================================================\n\n');


%% Start timer

analysis_start = datetime('now');

timer_start = tic;


%% Model preflight check

fprintf('\n[PRECHECK] Checking model before analysis...\n');

preflight_report = model_preflight_check( ...
    cfg, ...
    cfg.model.name);

if preflight_report.status ~= "PASS"
    error(['Model preflight did not pass. ' ...
        'Analysis has been stopped.']);
end

fprintf('\nModel preflight passed. Continuing with analysis.\n');
%% Framework self-test

if run_self_test

    fprintf('\n');
    fprintf('[CHECK] Running framework self-test...\n');

    self_test_report = framework_self_test(cfg);

    if self_test_report.status ~= "PASS"
        error(['Framework self-test failed. ' ...
            'Full analysis has been stopped.']);
    end

    fprintf('\nFramework self-test passed.\n');

end


%% 1. Baseline aerodynamic case

if run_baseline

    fprintf('\n[1] Running baseline case...\n');

    baseline_run

end


%% 2. Free-molecular-flow verification

if run_fmf

    fprintf('\n[2] Running FMF verification...\n');

    fmf_check

end


%% 3. Altitude sensitivity

if run_altitude

    fprintf('\n[3] Running altitude sweep...\n');

    altitude_sweep

end

%% 4. Environmental sensitivity

if run_environment

    fprintf('\n');
    fprintf('[4] Running environmental sensitivity...\n');

    environment_sensitivity

end

%% 5. Attitude database

if run_attitude

    fprintf('\n[4] Running attitude sweep...\n');

    attitude_sweep

end


%% 6. Small-angle stability check

if run_small_angle

    fprintf('\n[5] Running small-angle analysis...\n');

    small_angle_check

end


%% 7. GSIM and accommodation sensitivity

if run_gsi

    fprintf('\n[6] Running GSIM sensitivity...\n');

    gsi_sensitivity

end


%% 8. Mesh convergence

if run_mesh

    fprintf('\n[7] Running mesh sensitivity...\n');

    mesh_sensitivity

end

%% Finish Analysis

elapsed_seconds = toc(timer_start);

analysis_end = datetime('now');

%% Save run metadata

run_metadata = save_run_metadata( ...
    cfg, ...
    run_flags, ...
    analysis_start, ...
    analysis_end, ...
    elapsed_seconds);
% Completion message

fprintf('\n');
fprintf('====================================================\n');
fprintf('PROJECT ANALYSIS COMPLETE\n');
fprintf('====================================================\n');

fprintf('Started:      %s\n', ...
    char(analysis_start));

fprintf('Finished:     %s\n', ...
    char(analysis_end));

fprintf('Elapsed time: %.1f seconds\n', ...
    elapsed_seconds);

fprintf('Elapsed time: %.2f minutes\n', ...
    elapsed_seconds / 60);

fprintf('====================================================\n');