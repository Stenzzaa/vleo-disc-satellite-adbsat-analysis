%% stability_com_trade_v03.m
% Final local pitch-stability / centre-of-mass trade for disc_lenticular_v03.
%
% POST-PROCESSING ONLY:
% This script DOES NOT call ADBSatFcn or run_adbsat_case.
%
% It reads the existing shadow-ON Sentman alpha=1 raw ADBSat result files
% generated previously at:
% AoA = -2, -1, -0.5, +0.5, +1, +2 deg
% AoS = 0 deg
% altitude = 300 km
%
% From those files it:
% 1. extracts body-axis normal-force coefficient C_Fz;
% 2. extracts pitching moment about the geometric origin;
% 3. translates moments to the selected +6 mm design CoM;
% 4. fits local derivatives excluding exactly 0 deg;
% 5. calculates the X CoM that makes the fitted local CMy derivative zero;
% 6. compares that local-neutral X location with the +6 mm RMS-moment target.

if ~exist('cfg','var')
    project_config
end

%% Settings

model_name = 'disc_lenticular_v03';
altitude_km = 300;
aos_deg = 0;

aoa_deg = [-2 -1 -0.5 0.5 1 2];

x_design_m = cfg.model.com_design_G_m(1);
z_design_m = cfg.model.com_design_G_m(3);

%% Load model

model_file = fullfile( ...
    cfg.paths.model_dir, ...
    [model_name '.mat']);

if ~isfile(model_file)
    error('Model file not found: %s', model_file);
end

Smodel = load(model_file);

Lref_m = Smodel.meshdata.Lref;

%% Coordinate transformation used in shift_moment_to_com.m

L_fb = [ ...
   -1  0  0;
    0  1  0;
    0  0 -1];

%% Preallocate

nCase = numel(aoa_deg);

Cfx_B = zeros(nCase,1);
Cfz_B = zeros(nCase,1);

CMy_origin = zeros(nCase,1);
CMy_design = zeros(nCase,1);

AreaRef_m2 = NaN;
result_files = cell(nCase,1);

%% Header

fprintf('\n====================================================\n');
fprintf('FINAL v03 LOCAL STABILITY / CoM TRADE\n');
fprintf('====================================================\n');

fprintf('Model:       %s\n', model_name);
fprintf('Altitude:    %.1f km\n', altitude_km);
fprintf('AoS:         %.1f deg\n', aos_deg);
fprintf('GSIM:        Sentman alpha = 1\n');
fprintf('Shadow:      ON (existing official raw results)\n');

fprintf('Fit AoA:     -2, -1, -0.5, +0.5, +1, +2 deg\n');

fprintf('Lref:        %.9f m\n', Lref_m);

fprintf('Design CoM:  [%+.6f  %+.6f  %+.6f] m\n\n', ...
    cfg.model.com_design_G_m(1), ...
    cfg.model.com_design_G_m(2), ...
    cfg.model.com_design_G_m(3));

%% Read existing ADBSat result files

for i = 1:nCase

    aoa = aoa_deg(i);

    result_name = sprintf( ...
        '%s_%gkm_sentman_alpha_1_AoA_%g_AoS_%g.mat', ...
        model_name, ...
        altitude_km, ...
        aoa, ...
        aos_deg);

    result_file = fullfile( ...
        cfg.paths.project_results_dir, ...
        result_name);

    if ~isfile(result_file)

        % Fallback search in case ADBSat returned a slightly different path.
        pattern = sprintf( ...
            '%s_%gkm_sentman_alpha_1_AoA_%g_AoS_%g*.mat', ...
            model_name, ...
            altitude_km, ...
            aoa, ...
            aos_deg);

        matches = dir(fullfile( ...
            cfg.paths.project_results_dir, ...
            pattern));

        if numel(matches) ~= 1
            error(['Could not locate exactly one existing raw result for ' ...
                'AoA = %+g deg.\nExpected pattern:\n%s'], ...
                aoa, ...
                fullfile(cfg.paths.project_results_dir, pattern));
        end

        result_file = fullfile( ...
            matches(1).folder, ...
            matches(1).name);

    end

    result_files{i} = result_file;

    R = load(result_file);

    if ~isfield(R,'Cf_f')
        error('Cf_f missing from: %s', result_file);
    end

    if ~isfield(R,'Cm_B')
        error('Cm_B missing from: %s', result_file);
    end

    if ~isfield(R,'AreaRef')
        error('AreaRef missing from: %s', result_file);
    end

    if isnan(AreaRef_m2)
        AreaRef_m2 = R.AreaRef;
    end

    %% Convert ADBSat flight-axis force coefficient to body axes

    Cf_f = R.Cf_f(:);
    Cf_B = L_fb' * Cf_f;

    Cfx_B(i) = Cf_B(1);
    Cfz_B(i) = Cf_B(3);

    %% Native ADBSat moment is about mesh/geometric origin

    CMy_origin(i) = R.Cm_B(2);

    %% Translate to selected design CoM
    %
    % Existing verified relation:
    %
    % CMy_new =
    % CMy_origin
    % + (x_G/Lref)*Cfz
    % + (z_G/Lref)*Cfx

    CMy_design(i) = ...
        CMy_origin(i) ...
        + (x_design_m/Lref_m) * Cfz_B(i) ...
        + (z_design_m/Lref_m) * Cfx_B(i);

end

%% Linear fits versus AoA in radians

alpha_rad = deg2rad(aoa_deg(:));

p_fz = polyfit(alpha_rad, Cfz_B, 1);
p_origin = polyfit(alpha_rad, CMy_origin, 1);
p_design = polyfit(alpha_rad, CMy_design, 1);

dCfz_dalpha = p_fz(1);

dCMy_origin_dalpha = p_origin(1);
dCMy_design_dalpha = p_design(1);

%% R-squared values

pred_fz = polyval(p_fz, alpha_rad);
pred_origin = polyval(p_origin, alpha_rad);
pred_design = polyval(p_design, alpha_rad);

R2_fz = 1 - ...
    sum((Cfz_B - pred_fz).^2) / ...
    sum((Cfz_B - mean(Cfz_B)).^2);

R2_origin = 1 - ...
    sum((CMy_origin - pred_origin).^2) / ...
    sum((CMy_origin - mean(CMy_origin)).^2);

R2_design = 1 - ...
    sum((CMy_design - pred_design).^2) / ...
    sum((CMy_design - mean(CMy_design)).^2);

%% X CoM for zero fitted local pitch derivative
%
% For z_G = 0:
%
% dCMy/dalpha =
% dCMy_origin/dalpha
% + (x_G/Lref) * dCfz/dalpha
%
% Set derivative to zero.

if abs(dCfz_dalpha) < 1e-12
    error('dCfz/dalpha is too small to calculate a neutral X CoM.');
end

x_neutral_m = ...
    -dCMy_origin_dalpha * ...
    Lref_m / ...
    dCfz_dalpha;

%% Cross-check using current +6 mm design derivative

x_neutral_crosscheck_m = ...
    x_design_m ...
    - dCMy_design_dalpha * ...
    Lref_m / ...
    dCfz_dalpha;

%% Moment curve at local-neutral CoM

CMy_neutral = ...
    CMy_origin ...
    + (x_neutral_m/Lref_m) .* Cfz_B;

p_neutral = polyfit(alpha_rad, CMy_neutral, 1);

dCMy_neutral_dalpha = p_neutral(1);

%% Dimensional local derivative at 300 km

[param_eq_300, ~] = build_freestream(cfg, altitude_km);

q_300_Pa = ...
    0.5 * ...
    param_eq_300.rho(6) * ...
    param_eq_300.vinf^2;

dMy_design_dalpha_300 = ...
    q_300_Pa * ...
    AreaRef_m2 * ...
    Lref_m * ...
    dCMy_design_dalpha;

%% Dynamic-pressure-scaled 200 km estimate
% This holds the dimensionless local derivative fixed and only scales
% dimensional moment by dynamic pressure. It is an analytical scaling,
% not a new aerodynamic derivative calculation.

[param_eq_200, ~] = build_freestream(cfg, 200);

q_200_Pa = ...
    0.5 * ...
    param_eq_200.rho(6) * ...
    param_eq_200.vinf^2;

dMy_design_dalpha_200_scaled = ...
    q_200_Pa * ...
    AreaRef_m2 * ...
    Lref_m * ...
    dCMy_design_dalpha;

%% Load existing operational CoM optimum if available

com_summary_file = fullfile( ...
    cfg.paths.project_results_dir, ...
    'com_xz_sensitivity_v03.mat');

have_operational_optimum = isfile(com_summary_file);

x_rms_opt_m = NaN;
z_rms_opt_m = NaN;

if have_operational_optimum

    Scom = load(com_summary_file);

    if isfield(Scom,'x_opt_m')
        x_rms_opt_m = Scom.x_opt_m;
    end

    if isfield(Scom,'z_opt_m')
        z_rms_opt_m = Scom.z_opt_m;
    end

end

%% Results table

results_stability = table( ...
    aoa_deg(:), ...
    Cfx_B, ...
    Cfz_B, ...
    CMy_origin, ...
    CMy_design, ...
    CMy_neutral, ...
    'VariableNames', { ...
    'AoA_deg', ...
    'Cfx_B', ...
    'Cfz_B', ...
    'CMy_origin', ...
    'CMy_designPlus6mm', ...
    'CMy_localNeutral'});

fprintf('\n====================================================\n');
fprintf('LOCAL DATA USED\n');
fprintf('====================================================\n\n');

disp(results_stability);

%% Print derivative results

fprintf('\n====================================================\n');
fprintf('LOCAL DERIVATIVE RESULTS\n');
fprintf('====================================================\n');

fprintf('dCfz/dalpha at origin:       %+.8e per rad\n', ...
    dCfz_dalpha);

fprintf('R^2 for Cfz fit:             %.8f\n\n', ...
    R2_fz);

fprintf('dCMy/dalpha at origin:       %+.8e per rad\n', ...
    dCMy_origin_dalpha);

fprintf('R^2 origin CMy fit:          %.8f\n\n', ...
    R2_origin);

fprintf('dCMy/dalpha at +6 mm CoM:    %+.8e per rad\n', ...
    dCMy_design_dalpha);

fprintf('R^2 +6 mm CMy fit:           %.8f\n\n', ...
    R2_design);

fprintf('dCMy/dalpha at neutral CoM:  %+.8e per rad\n', ...
    dCMy_neutral_dalpha);

%% Print CoM trade

fprintf('\n====================================================\n');
fprintf('CENTRE-OF-MASS TRADE\n');
fprintf('====================================================\n');

fprintf('Selected practical design X CoM:   %+.3f mm\n', ...
    x_design_m * 1000);

fprintf('Local-neutral X CoM:               %+.3f mm\n', ...
    x_neutral_m * 1000);

fprintf('Cross-check neutral X CoM:         %+.3f mm\n', ...
    x_neutral_crosscheck_m * 1000);

fprintf('Shift from +6 mm design target:    %+.3f mm\n', ...
    (x_neutral_m - x_design_m) * 1000);

if have_operational_optimum && isfinite(x_rms_opt_m)

    fprintf('\nExisting +/-30 deg least-squares optimum:\n');

    fprintf('X = %+.3f mm\n', ...
        x_rms_opt_m * 1000);

    fprintf('Z = %+.3f mm\n', ...
        z_rms_opt_m * 1000);

    fprintf(['\nInterpretation: the CoM that minimises RMS pitching ' ...
        'moment over the operational envelope is not necessarily the ' ...
        'same CoM that makes the local derivative zero.\n']);

end

%% Dimensional derivative

fprintf('\n====================================================\n');
fprintf('DIMENSIONAL LOCAL PITCH DERIVATIVE\n');
fprintf('====================================================\n');

fprintf('At 300 km:\n');
fprintf('dMy/dalpha = %+.8e N m/rad\n', ...
    dMy_design_dalpha_300);

fprintf('\n200 km dynamic-pressure-scaled estimate:\n');
fprintf('dMy/dalpha = %+.8e N m/rad\n', ...
    dMy_design_dalpha_200_scaled);

fprintf(['\nThe 200 km value above is an analytical dynamic-pressure ' ...
    'scaling of the 300 km coefficient derivative, not a separately ' ...
    'fitted 200 km derivative.\n']);

%% Save

summary = struct();

summary.Lref_m = Lref_m;
summary.AreaRef_m2 = AreaRef_m2;

summary.dCfz_dalpha = dCfz_dalpha;
summary.dCMy_origin_dalpha = dCMy_origin_dalpha;
summary.dCMy_design_dalpha = dCMy_design_dalpha;

summary.R2_fz = R2_fz;
summary.R2_origin = R2_origin;
summary.R2_design = R2_design;

summary.x_design_m = x_design_m;
summary.x_neutral_m = x_neutral_m;
summary.x_neutral_crosscheck_m = x_neutral_crosscheck_m;

summary.dMy_design_dalpha_300 = dMy_design_dalpha_300;
summary.dMy_design_dalpha_200_scaled = ...
    dMy_design_dalpha_200_scaled;

summary.x_rms_opt_m = x_rms_opt_m;
summary.z_rms_opt_m = z_rms_opt_m;

writetable( ...
    results_stability, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'stability_com_trade_local_data.csv'));

save( ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'stability_com_trade_v03.mat'), ...
    'results_stability', ...
    'summary', ...
    'result_files', ...
    'cfg');

%% Plot

figure('Name','Final v03 Local Stability and CoM Trade');

plot( ...
    aoa_deg, ...
    CMy_origin, ...
    '-o', ...
    'LineWidth',1.5, ...
    'DisplayName','Geometric origin');

hold on;
grid on;

plot( ...
    aoa_deg, ...
    CMy_design, ...
    '-o', ...
    'LineWidth',1.5, ...
    'DisplayName','Selected +6 mm X CoM');

plot( ...
    aoa_deg, ...
    CMy_neutral, ...
    '-o', ...
    'LineWidth',1.5, ...
    'DisplayName','Local-neutral X CoM');

yline(0,'--');

xlabel('AoA [deg]');
ylabel('C_{My}');
title('disc\_lenticular\_v03 Local CoM Trade');

legend('Location','best');

exportgraphics( ...
    gcf, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'stability_com_trade_v03.png'), ...
    'Resolution',300);

fprintf('\nPost-processing complete. No ADBSat cases were rerun.\n');
fprintf('Results saved in:\n%s\n', ...
    cfg.paths.project_results_dir);
