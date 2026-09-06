%% small_angle_check.m
% Local pitch behaviour for final disc_lenticular_v03.
%
% Official analysis uses shadow ON.
% The exact zero-degree result is retained for reference but excluded
% from the local derivative fit because the baffle concavity has shown
% sensitivity to ADBSat shadowing near grazing incidence.

if ~exist('cfg','var')
    project_config
end

cfg_run = cfg;
cfg_run.flags.verbose = 0;

%% Settings

model_name = cfg.model.name;

altitude_km = cfg.orbit.altitude_km;
aos_deg = 0;

aoa_deg = [-2 -1 -0.5 0 0.5 1 2];

gsi_model = cfg.gsi.baseline_model;

nCase = numel(aoa_deg);

%% Load model reference data

model_file = fullfile( ...
    cfg.paths.model_dir, ...
    [model_name '.mat']);

S = load(model_file);

Lref_m = S.meshdata.Lref;

%% Preallocate

AreaProj_m2 = zeros(nCase,1);
CD_ADBSat = zeros(nCase,1);
Drag_N = zeros(nCase,1);

CMy = zeros(nCase,1);
My_Nm = zeros(nCase,1);

%% Header

fprintf('\n====================================================\n');
fprintf('FINAL v03 LOCAL PITCH ASSESSMENT\n');
fprintf('====================================================\n');

fprintf('Model:      %s\n', model_name);
fprintf('Altitude:   %.1f km\n', altitude_km);
fprintf('AoS:        %.1f deg\n', aos_deg);
fprintf('GSIM:       %s\n', gsi_model);
fprintf('Shadow:     %d\n', cfg.flags.shadow);
fprintf('Solar:      %d\n', cfg.flags.solar);

fprintf('CoM [m]:    [%+.6f  %+.6f  %+.6f]\n\n', ...
    cfg.model.com_G_m(1), ...
    cfg.model.com_G_m(2), ...
    cfg.model.com_G_m(3));

fprintf('NOTE: AoA = 0 deg is evaluated but excluded from derivative fit.\n\n');

%% Run cases

for i = 1:nCase

    fprintf('Case %d of %d: AoA = %+.1f deg\n', ...
        i, nCase, aoa_deg(i));

    out = run_adbsat_case( ...
        cfg_run, ...
        model_name, ...
        altitude_km, ...
        aoa_deg(i), ...
        aos_deg, ...
        gsi_model);

    q = 0.5 * out.rho_kgm3 * out.vinf_ms^2;

    AreaProj_m2(i) = out.AreaProj_m2;

    CD_ADBSat(i) = -out.Cf_w(1);

    Drag_N(i) = ...
        q * out.AreaRef_m2 * CD_ADBSat(i);

    CMy(i) = out.Cm_B(2);

    My_Nm(i) = ...
        q * out.AreaRef_m2 * Lref_m * CMy(i);

end

%% Local derivative fit
% Exclude exact zero because of known local shadowing sensitivity.

fitMask = aoa_deg ~= 0;

alpha_fit_rad = deg2rad(aoa_deg(fitMask));
CMy_fit = CMy(fitMask);

p = polyfit(alpha_fit_rad, CMy_fit', 1);

dCMy_dalpha = p(1);
CMy_intercept = p(2);

CMy_pred = polyval(p, alpha_fit_rad);

SSres = sum((CMy_fit' - CMy_pred).^2);
SStot = sum((CMy_fit' - mean(CMy_fit)).^2);

R2 = 1 - SSres/SStot;

%% Optional one-sided gradients
% These are diagnostic only and help show any asymmetry.

negMask = aoa_deg < 0;
posMask = aoa_deg > 0;

p_neg = polyfit( ...
    deg2rad(aoa_deg(negMask)), ...
    CMy(negMask)', ...
    1);

p_pos = polyfit( ...
    deg2rad(aoa_deg(posMask)), ...
    CMy(posMask)', ...
    1);

dCMy_dalpha_neg = p_neg(1);
dCMy_dalpha_pos = p_pos(1);

%% Results table

results_small_angle = table( ...
    aoa_deg(:), ...
    AreaProj_m2, ...
    CD_ADBSat, ...
    Drag_N, ...
    CMy, ...
    My_Nm, ...
    'VariableNames', { ...
    'AoA_deg', ...
    'AreaProj_m2', ...
    'CD_ADBSat', ...
    'Drag_N', ...
    'CMy', ...
    'My_Nm'});

fprintf('\n====================================================\n');
fprintf('LOCAL PITCH RESULTS\n');
fprintf('====================================================\n\n');

disp(results_small_angle)

%% Summary

fprintf('\n====================================================\n');
fprintf('LOCAL PITCH DERIVATIVE SUMMARY\n');
fprintf('====================================================\n');

fprintf('Fit points:\n');
fprintf('  -2, -1, -0.5, +0.5, +1, +2 deg\n\n');

fprintf('Symmetric linear fit:\n');
fprintf('dCMy/dalpha = %+.8e per rad\n', dCMy_dalpha);
fprintf('Fit intercept = %+.8e\n', CMy_intercept);
fprintf('R^2 = %.8f\n\n', R2);

fprintf('One-sided diagnostic slopes:\n');
fprintf('Negative AoA side: %+.8e per rad\n', ...
    dCMy_dalpha_neg);

fprintf('Positive AoA side: %+.8e per rad\n', ...
    dCMy_dalpha_pos);

idx0 = find(aoa_deg == 0);

fprintf('\nExact zero-degree reference:\n');
fprintf('CMy(0 deg) = %+.8e\n', CMy(idx0));
fprintf('My(0 deg)  = %+.8e N m\n', My_Nm(idx0));

fprintf('\nDo not assign restoring/destabilising terminology\n');
fprintf('until the ADBSat moment/attitude sign convention is explicitly established.\n');

%% Save

csv_file = fullfile( ...
    cfg.paths.project_results_dir, ...
    'small_angle_pitch_results.csv');

mat_file = fullfile( ...
    cfg.paths.project_results_dir, ...
    'small_angle_pitch_summary.mat');

writetable(results_small_angle, csv_file);

save(mat_file, ...
    'results_small_angle', ...
    'dCMy_dalpha', ...
    'CMy_intercept', ...
    'R2', ...
    'dCMy_dalpha_neg', ...
    'dCMy_dalpha_pos', ...
    'cfg');

%% Plot

figure('Name','Final v03 Local Pitch Assessment');

plot(aoa_deg, CMy, '-o', ...
    'LineWidth',1.5);

hold on

alpha_plot_deg = linspace(-2,2,200);
alpha_plot_rad = deg2rad(alpha_plot_deg);

plot( ...
    alpha_plot_deg, ...
    polyval(p,alpha_plot_rad), ...
    '--', ...
    'LineWidth',1.5);

yline(0,'--');

grid on

xlabel('AoA [deg]');
ylabel('C_{My}');

title('disc\_lenticular\_v03 Local Pitch Behaviour');

legend( ...
    'ADBSat results', ...
    'Linear fit excluding 0 deg', ...
    'C_{My}=0', ...
    'Location','best');

fig_file = fullfile( ...
    cfg.paths.project_results_dir, ...
    'small_angle_pitch.png');

exportgraphics(gcf, fig_file, 'Resolution',300);

fprintf('\nLocal pitch assessment complete.\n');
fprintf('Results saved in:\n%s\n', ...
    cfg.paths.project_results_dir);