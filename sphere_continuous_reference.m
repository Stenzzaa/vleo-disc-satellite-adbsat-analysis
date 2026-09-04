%% sphere_continuous_reference.m
%
% Continuous-sphere verification using the same Sentman formulation
% implemented in ADBSat.
%
% This script:
%   1. loads the existing 960-panel sphere result;
%   2. reconstructs the frontal-area-referenced ADBSat CD;
%   3. extracts scalar Sentman parameters from the saved panel case;
%   4. integrates the local ADBSat Sentman drag coefficient over an exact
%      sphere using scalar-by-scalar calls to coeff_sentman;
%   5. compares the continuous result with the 960-panel result;
%   6. saves the verification evidence;
%   7. copies the relevant sphere files into the final dissertation archive.

clear
clc

fprintf('\n');
fprintf('============================================================\n');
fprintf('SPHERE CONTINUOUS SENTMAN REFERENCE\n');
fprintf('============================================================\n\n');

%% ---------------------------------------------------------------
% PROJECT PATHS
% ---------------------------------------------------------------

project_root = ...
'C:\Users\Samsung\OneDrive\MSc Aerospace Engineering\Dissertation\MATLAB Code';

sphere_dir = fullfile( ...
    project_root, ...
    'results', ...
    'sphere_validation');

baseline_file = fullfile( ...
    sphere_dir, ...
    'baseline_sphere_300km_sentman_AoA_0_AoS_0.mat');

mesh_file = fullfile( ...
    sphere_dir, ...
    'mesh_sensitivity_results.csv');

gsi_file = fullfile( ...
    sphere_dir, ...
    'gsi_sensitivity_summary.csv');

preflight_file = fullfile( ...
    sphere_dir, ...
    'preflight_sphere.mat');

if ~isfile(baseline_file)
    error('Baseline sphere file not found:\n%s',baseline_file);
end

%% ---------------------------------------------------------------
% LOCATE ADBSat SENTMAN ROUTINE
% ---------------------------------------------------------------

sentman_path = which('coeff_sentman');

if isempty(sentman_path)
    error(['coeff_sentman.m is not on the MATLAB path. ' ...
        'Add the ADBSat toolbox to the MATLAB path first.']);
end

fprintf('ADBSat Sentman routine:\n%s\n\n',sentman_path);

%% ---------------------------------------------------------------
% LOAD EXISTING 960-PANEL RESULT
% ---------------------------------------------------------------

S = load(baseline_file);

required = { ...
    'param_eq', ...
    'Cf_w', ...
    'Cm_B', ...
    'AreaRef', ...
    'AreaProj', ...
    'cd'};

for i = 1:numel(required)

    if ~isfield(S,required{i})
        error('Missing field in baseline sphere MAT: %s',required{i});
    end

end

panel_count = numel(S.cd);

%% ---------------------------------------------------------------
% EXTRACT UNIFORM SCALAR SENTMAN PARAMETERS
% ---------------------------------------------------------------
%
% Saved ADBSat cases may store values such as alpha once per panel.
% We first verify that every panel contains the same value and then use
% one scalar value for the continuous integration.

param_eq = S.param_eq;

param_scalar = struct();

fields_needed = { ...
    'Tinf', ...
    'alpha', ...
    's', ...
    'Tw'};

for i = 1:numel(fields_needed)

    name = fields_needed{i};

    if ~isfield(param_eq,name)
        error('param_eq.%s is missing.',name);
    end

    values = double(param_eq.(name));
    values = values(:);

    if isempty(values)
        error('param_eq.%s is empty.',name);
    end

    first_value = values(1);

    tolerance = ...
        1e-10 * max(1,abs(first_value));

    if any(abs(values - first_value) > tolerance)

        error( ...
            ['param_eq.%s is not uniform across the saved sphere ' ...
             'panels.'], ...
            name);

    end

    param_scalar.(name) = first_value;

end

fprintf('Verified scalar Sentman parameters\n');
fprintf('----------------------------------\n');
fprintf('alpha = %.12g\n',param_scalar.alpha);
fprintf('s     = %.12g\n',param_scalar.s);
fprintf('Tinf  = %.12g K\n',param_scalar.Tinf);
fprintf('Tw    = %.12g K\n\n',param_scalar.Tw);

%% ---------------------------------------------------------------
% RECONSTRUCT ADBSat 960-PANEL SPHERE CD
% ---------------------------------------------------------------

CD_ADBSat_native = ...
    -S.Cf_w(1);

CD_ADBSat_frontal = ...
    CD_ADBSat_native * ...
    S.AreaRef / ...
    S.AreaProj;

moment_norm = ...
    norm(S.Cm_B);

fprintf('Saved ADBSat sphere result\n');
fprintf('--------------------------\n');
fprintf('Panel count:                %d\n',panel_count);
fprintf('AreaRef:                    %.12f m^2\n',S.AreaRef);
fprintf('AreaProj:                   %.12f m^2\n',S.AreaProj);
fprintf('Native ADBSat CD:           %.12f\n',CD_ADBSat_native);
fprintf('Frontal-area CD:            %.12f\n',CD_ADBSat_frontal);
fprintf('Moment coefficient norm:    %.12e\n\n',moment_norm);

%% ---------------------------------------------------------------
% CONTINUOUS SPHERE REFERENCE
% ---------------------------------------------------------------
%
% For a sphere:
%
%   dA = 2*pi*R^2*sin(delta) d(delta)
%
% and:
%
%   Afront = pi*R^2
%
% Therefore:
%
%   CD = 2 * integral[ cd(delta)*sin(delta) d(delta) ]
%
% from delta = 0 to pi/2.
%
% IMPORTANT:
% coeff_sentman is deliberately called once per scalar delta using
% arrayfun. This avoids all vector-size incompatibilities with ADBSat.

integrand = @(delta) ...
    arrayfun( ...
        @(d) local_integrand(d,param_scalar), ...
        delta);

CD_continuous = ...
    2 * integral( ...
        integrand, ...
        0, ...
        pi/2, ...
        'ArrayValued',true, ...
        'AbsTol',1e-11, ...
        'RelTol',1e-10);

%% ---------------------------------------------------------------
% DENSE-GRID INDEPENDENT CROSS-CHECK
% ---------------------------------------------------------------

N = 20001;

delta_grid = ...
    linspace(0,pi/2,N);

integrand_grid = ...
    zeros(size(delta_grid));

for i = 1:N

    integrand_grid(i) = ...
        local_integrand( ...
            delta_grid(i), ...
            param_scalar);

end

CD_trapz = ...
    2 * trapz( ...
        delta_grid, ...
        integrand_grid);

quadrature_difference = ...
    abs(CD_continuous - CD_trapz);

%% ---------------------------------------------------------------
% COMPARISON
% ---------------------------------------------------------------

absolute_difference = ...
    CD_ADBSat_frontal - ...
    CD_continuous;

relative_difference_pct = ...
    100 * ...
    absolute_difference / ...
    CD_continuous;

fprintf('Continuous exact-geometry reference\n');
fprintf('-----------------------------------\n');
fprintf('Adaptive integration CD:          %.12f\n',CD_continuous);
fprintf('Dense-grid integration CD:        %.12f\n',CD_trapz);
fprintf('Integration cross-check:          %.3e\n\n', ...
    quadrature_difference);

fprintf('960-panel comparison\n');
fprintf('--------------------\n');
fprintf('960-panel frontal CD:             %.12f\n', ...
    CD_ADBSat_frontal);

fprintf('Continuous Sentman CD:            %.12f\n', ...
    CD_continuous);

fprintf('Absolute difference:              %+.12e\n', ...
    absolute_difference);

fprintf('Relative difference:              %+.6f %%\n\n', ...
    relative_difference_pct);

%% ---------------------------------------------------------------
% MEDIUM-TO-FINE SPHERE MESH CHANGE
% ---------------------------------------------------------------

medium_to_fine_pct = NaN;

if isfile(mesh_file)

    Tmesh = readtable(mesh_file);

    mesh_names = string(Tmesh.Mesh);

    idx_medium = ...
        strcmpi(mesh_names,'Medium') & ...
        Tmesh.AoA_deg == 0 & ...
        Tmesh.AoS_deg == 0;

    idx_fine = ...
        strcmpi(mesh_names,'Fine') & ...
        Tmesh.AoA_deg == 0 & ...
        Tmesh.AoS_deg == 0;

    if any(idx_medium) && any(idx_fine)

        CD_medium = ...
            Tmesh.CD(find(idx_medium,1));

        CD_fine = ...
            Tmesh.CD(find(idx_fine,1));

        medium_to_fine_pct = ...
            100 * ...
            abs(CD_medium - CD_fine) / ...
            abs(CD_fine);

        fprintf( ...
            'Medium-to-fine native CD change: %.6f %%\n\n', ...
            medium_to_fine_pct);

    end

end

%% ---------------------------------------------------------------
% SAVE VERIFICATION RESULTS
% ---------------------------------------------------------------

Result = table( ...
    panel_count, ...
    S.AreaRef, ...
    S.AreaProj, ...
    CD_ADBSat_native, ...
    CD_ADBSat_frontal, ...
    CD_continuous, ...
    CD_trapz, ...
    quadrature_difference, ...
    absolute_difference, ...
    relative_difference_pct, ...
    moment_norm, ...
    medium_to_fine_pct, ...
    string(sentman_path), ...
    'VariableNames',{ ...
    'PanelCount', ...
    'AreaRef_m2', ...
    'AreaProj_m2', ...
    'CD_ADBSat_native', ...
    'CD_ADBSat_frontal', ...
    'CD_continuous_Sentman', ...
    'CD_dense_grid', ...
    'IntegrationDifference', ...
    'ADBSatMinusContinuous', ...
    'Difference_pct', ...
    'MomentCoefficientNorm', ...
    'MediumToFineNativeCDChange_pct', ...
    'SentmanRoutinePath'});

csv_output = fullfile( ...
    sphere_dir, ...
    'sphere_continuous_reference_results.csv');

mat_output = fullfile( ...
    sphere_dir, ...
    'sphere_continuous_reference.mat');

writetable( ...
    Result, ...
    csv_output);

save( ...
    mat_output, ...
    'Result', ...
    'param_scalar', ...
    'param_eq', ...
    'CD_continuous', ...
    'CD_ADBSat_frontal', ...
    'relative_difference_pct');

fprintf('Saved verification evidence:\n');
fprintf('%s\n',csv_output);
fprintf('%s\n\n',mat_output);

%% ---------------------------------------------------------------
% FINAL DISSERTATION ARCHIVE PATHS
% ---------------------------------------------------------------

disc_results = fullfile( ...
    project_root, ...
    'results', ...
    'disc_lenticular_v03');

final_results = fullfile( ...
    disc_results, ...
    'FINAL_WRITEUP_RESULTS', ...
    '09_Verification_and_Validation');

final_code = fullfile( ...
    project_root, ...
    'DISSERTATION_MATLAB_CODE', ...
    '02_Verification');

if ~exist(final_results,'dir')
    mkdir(final_results);
end

if ~exist(final_code,'dir')
    mkdir(final_code);
end

%% ---------------------------------------------------------------
% COPY SPHERE EVIDENCE
% ---------------------------------------------------------------

evidence = { ...
    baseline_file
    preflight_file
    mesh_file
    gsi_file
    csv_output
    mat_output};

fprintf('============================================================\n');
fprintf('COPYING SPHERE EVIDENCE TO FINAL RESULTS ARCHIVE\n');
fprintf('============================================================\n');

for i = 1:numel(evidence)

    source = evidence{i};

    if isfile(source)

        [~,name,ext] = fileparts(source);

        destination = ...
            fullfile( ...
                final_results, ...
                [name ext]);

        copyfile( ...
            source, ...
            destination, ...
            'f');

        fprintf('COPIED: %s%s\n',name,ext);

    else

        fprintf('NOT FOUND: %s\n',source);

    end

end

%% ---------------------------------------------------------------
% COPY THIS SCRIPT TO FINAL CODE ARCHIVE
% ---------------------------------------------------------------

this_script = ...
    fullfile( ...
        project_root, ...
        'sphere_continuous_reference.m');

if isfile(this_script)

    copyfile( ...
        this_script, ...
        fullfile( ...
            final_code, ...
            'sphere_continuous_reference.m'), ...
        'f');

    fprintf('\nCOPIED CODE: sphere_continuous_reference.m\n');

end

%% ---------------------------------------------------------------
% FINAL STATUS
% ---------------------------------------------------------------

checks = [ ...
    panel_count == 960
    isfinite(CD_continuous)
    quadrature_difference < 1e-6
    isfile(fullfile( ...
        final_results, ...
        'sphere_continuous_reference_results.csv'))
    isfile(fullfile( ...
        final_code, ...
        'sphere_continuous_reference.m'))];

Check = [ ...
    "960-panel sphere case confirmed"
    "Continuous Sentman reference calculated"
    "Two integration methods agree"
    "Sphere results copied to final archive"
    "Verification script copied to final code archive"];

Status = table(Check,checks, ...
    'VariableNames',{'Check','Passed'});

fprintf('\n');
fprintf('============================================================\n');
fprintf('SPHERE VALIDATION ARCHIVE STATUS\n');
fprintf('============================================================\n');

disp(Status);

if all(checks)

    fprintf('SPHERE VALIDATION ARCHIVE: PASS\n');

else

    fprintf('SPHERE VALIDATION ARCHIVE: REVIEW REQUIRED\n');

end

fprintf('\nFinal verification results:\n%s\n',final_results);
fprintf('\nFinal verification code:\n%s\n',final_code);

fprintf('============================================================\n');

%% ---------------------------------------------------------------
% LOCAL FUNCTION
% ---------------------------------------------------------------

function value = local_integrand(delta,param_scalar)

    % Force every input to scalar double.
    delta = double(delta);

    p = struct();

    p.Tinf = double(param_scalar.Tinf);
    p.alpha = double(param_scalar.alpha);
    p.s = double(param_scalar.s);
    p.Tw = double(param_scalar.Tw);

    % ADBSat local Sentman coefficients.
    [~,~,cd,~] = ...
        coeff_sentman( ...
            p, ...
            delta);

    % Continuous sphere surface-area weighting.
    value = ...
        double(cd) * ...
        sin(delta);

end