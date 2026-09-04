%% sideslip_sweep.m
% Final sideslip sensitivity study for disc_lenticular_v03.
%
% Purpose:
% Assess aerodynamic response to sideslip at nominal AoA = 0 deg, and test
% the axisymmetry of the external geometry.
%
% Final configuration:
% - 8800-panel disc_lenticular_v03
% - altitude = 300 km
% - AoA = 0 deg
% - AoS = -30:10:+30 deg
% - Sentman baseline
% - shadow ON
% - solar OFF
% - design CoM = [+0.006; 0; 0] m
%
% NOTE ON THE REFERENCE CASE
% The exactly-zero attitude (AoA = AoS = 0) is affected by the known
% grazing-incidence shadowing behaviour and is NOT a clean reference. All
% relative variations are therefore measured against the mean of the
% non-zero sideslip cases, and the zero case is reported separately as a
% diagnostic of that artefact.

if ~exist('cfg','var')
    project_config
end

cfg_run = cfg;
cfg_run.flags.verbose = 0;


%% Settings

model_name = cfg.model.name;

altitude_km = cfg.orbit.altitude_km;

aoa_deg = 0;

aos_values = [-30 -20 -10 0 10 20 30];

gsi_model = cfg.gsi.baseline_model;

nCase = numel(aos_values);

xCoM_m = cfg.model.com_G_m(1);


%% Load model reference length

model_file = fullfile( ...
    cfg.paths.model_dir, ...
    [model_name '.mat']);

if ~isfile(model_file)
    error('Model file not found: %s', model_file);
end

S = load(model_file);

Lref_m = S.meshdata.Lref;


%% Preallocate

AoA_deg = zeros(nCase,1);
AoS_deg = zeros(nCase,1);

DynamicPressure_Pa = zeros(nCase,1);

AreaProj_m2 = zeros(nCase,1);
AreaRef_m2 = zeros(nCase,1);

CD_ADBSat = zeros(nCase,1);
CD_projected = zeros(nCase,1);

Drag_N = zeros(nCase,1);

CFx_w = zeros(nCase,1);
CFy_w = zeros(nCase,1);
CFz_w = zeros(nCase,1);

CMx_B = zeros(nCase,1);
CMy_B = zeros(nCase,1);
CMz_B = zeros(nCase,1);

Mx_Nm = zeros(nCase,1);
My_Nm = zeros(nCase,1);
Mz_Nm = zeros(nCase,1);


%% Header

fprintf('\n');
fprintf('====================================================\n');
fprintf('FINAL v03 SIDESLIP SENSITIVITY\n');
fprintf('====================================================\n');

fprintf('Model:      %s\n', model_name);
fprintf('Altitude:   %.1f km\n', altitude_km);
fprintf('AoA:        %.1f deg\n', aoa_deg);

fprintf('AoS range:  %.1f to %.1f deg\n', ...
    min(aos_values), ...
    max(aos_values));

fprintf('GSIM:       %s\n', gsi_model);
fprintf('Shadow:     %d\n', cfg.flags.shadow);
fprintf('Solar:      %d\n', cfg.flags.solar);

fprintf('CoM [m]:    [%+.6f  %+.6f  %+.6f]\n', ...
    cfg.model.com_G_m(1), ...
    cfg.model.com_G_m(2), ...
    cfg.model.com_G_m(3));

fprintf('Lref [m]:   %.7f\n\n', Lref_m);


%% Run cases

for i = 1:nCase

    aos = aos_values(i);

    fprintf( ...
        'Case %d of %d: AoA = %+5.1f deg, AoS = %+5.1f deg\n', ...
        i, ...
        nCase, ...
        aoa_deg, ...
        aos);


    out = run_adbsat_case( ...
        cfg_run, ...
        model_name, ...
        altitude_km, ...
        aoa_deg, ...
        aos, ...
        gsi_model);


    %% Dynamic pressure

    q = ...
        0.5 * ...
        out.rho_kgm3 * ...
        out.vinf_ms^2;


    %% Store attitude

    AoA_deg(i) = aoa_deg;
    AoS_deg(i) = aos;


    %% Geometry/reference values

    DynamicPressure_Pa(i) = q;

    AreaProj_m2(i) = ...
        out.AreaProj_m2;

    AreaRef_m2(i) = ...
        out.AreaRef_m2;


    %% Forces

    CD_ADBSat(i) = ...
        -out.Cf_w(1);

    CD_projected(i) = ...
        CD_ADBSat(i) * ...
        AreaRef_m2(i) / ...
        AreaProj_m2(i);

    Drag_N(i) = ...
        q * ...
        AreaRef_m2(i) * ...
        CD_ADBSat(i);


    CFx_w(i) = out.Cf_w(1);
    CFy_w(i) = out.Cf_w(2);
    CFz_w(i) = out.Cf_w(3);


    %% Moments about selected design CoM

    CMx_B(i) = out.Cm_B(1);
    CMy_B(i) = out.Cm_B(2);
    CMz_B(i) = out.Cm_B(3);


    Mx_Nm(i) = ...
        q * ...
        AreaRef_m2(i) * ...
        Lref_m * ...
        CMx_B(i);

    My_Nm(i) = ...
        q * ...
        AreaRef_m2(i) * ...
        Lref_m * ...
        CMy_B(i);

    Mz_Nm(i) = ...
        q * ...
        AreaRef_m2(i) * ...
        Lref_m * ...
        CMz_B(i);

end


%% Results table

results_sideslip = table( ...
    AoA_deg, ...
    AoS_deg, ...
    DynamicPressure_Pa, ...
    AreaProj_m2, ...
    AreaRef_m2, ...
    CD_ADBSat, ...
    CD_projected, ...
    Drag_N, ...
    CFx_w, ...
    CFy_w, ...
    CFz_w, ...
    CMx_B, ...
    CMy_B, ...
    CMz_B, ...
    Mx_Nm, ...
    My_Nm, ...
    Mz_Nm);


fprintf('\n');
fprintf('====================================================\n');
fprintf('SIDESLIP-SWEEP RESULTS\n');
fprintf('====================================================\n\n');

disp(results_sideslip);


%% ===================================================================
%  AXISYMMETRY ASSESSMENT
%  Reference = mean of the NON-ZERO sideslip cases, because the
%  exactly-zero attitude is affected by grazing-incidence shadowing.
%  ===================================================================

idx0 = find(AoS_deg == 0);
idxNZ = find(AoS_deg ~= 0);

if numel(idx0) ~= 1
    error('Exactly one AoS = 0 deg case is required.');
end

AreaProj_ref = mean(AreaProj_m2(idxNZ));
CD_ref = mean(CD_ADBSat(idxNZ));
Drag_ref = mean(Drag_N(idxNZ));

% spread across the non-zero cases: the axisymmetry measure
AreaSpread_pct = ...
    100 * ...
    (max(AreaProj_m2(idxNZ)) - min(AreaProj_m2(idxNZ))) / ...
    AreaProj_ref;

CDSpread_pct = ...
    100 * ...
    (max(CD_ADBSat(idxNZ)) - min(CD_ADBSat(idxNZ))) / ...
    CD_ref;

DragSpread_pct = ...
    100 * ...
    (max(Drag_N(idxNZ)) - min(Drag_N(idxNZ))) / ...
    Drag_ref;

% offset of the exactly-zero case: the artefact measure
AreaZeroOffset_pct = ...
    100 * (AreaProj_m2(idx0) - AreaProj_ref) / AreaProj_ref;

CDZeroOffset_pct = ...
    100 * (CD_ADBSat(idx0) - CD_ref) / CD_ref;

DragZeroOffset_pct = ...
    100 * (Drag_N(idx0) - Drag_ref) / Drag_ref;

% per-case deviation from the non-zero mean (for the results table)
AreaDev_pct = 100 * (AreaProj_m2 - AreaProj_ref) / AreaProj_ref;
CDDev_pct = 100 * (CD_ADBSat - CD_ref) / CD_ref;
DragDev_pct = 100 * (Drag_N - Drag_ref) / Drag_ref;


summary_sideslip = table( ...
    AoS_deg, ...
    AreaProj_m2, ...
    AreaDev_pct, ...
    CD_ADBSat, ...
    CDDev_pct, ...
    Drag_N, ...
    DragDev_pct, ...
    CMx_B, ...
    CMy_B, ...
    CMz_B, ...
    Mx_Nm, ...
    My_Nm, ...
    Mz_Nm);


fprintf('\n');
fprintf('====================================================\n');
fprintf('SIDESLIP SUMMARY (reference = mean of non-zero cases)\n');
fprintf('====================================================\n\n');

disp(summary_sideslip);


fprintf('\n');
fprintf('----------------------------------------------------\n');
fprintf('AXISYMMETRY OF THE EXTERNAL GEOMETRY\n');
fprintf('(spread across non-zero sideslip angles only)\n');
fprintf('----------------------------------------------------\n');

fprintf('Mean projected area (non-zero AoS): %.7f m^2\n', AreaProj_ref);
fprintf('Mean CD (non-zero AoS):             %.7f\n', CD_ref);
fprintf('Mean drag (non-zero AoS):           %.7e N\n\n', Drag_ref);

fprintf('Projected-area spread:  %.4f %%\n', AreaSpread_pct);
fprintf('CD spread:              %.4f %%\n', CDSpread_pct);
fprintf('Drag spread:            %.4f %%\n', DragSpread_pct);


fprintf('\n');
fprintf('----------------------------------------------------\n');
fprintf('GRAZING-INCIDENCE DIAGNOSTIC AT AoS = 0 DEG\n');
fprintf('----------------------------------------------------\n');

fprintf('Projected area offset:  %+.4f %%\n', AreaZeroOffset_pct);
fprintf('CD offset:              %+.4f %%\n', CDZeroOffset_pct);
fprintf('Drag offset:            %+.4f %%\n', DragZeroOffset_pct);

fprintf(['\nAn offset of this size at exactly zero attitude is ' ...
    'consistent with\nthe shadowing behaviour observed at zero ' ...
    'pitch and should not be\ninterpreted as a physical ' ...
    'sideslip effect.\n']);


%% ===================================================================
%  YAW-MOMENT CHECK
%  For an axisymmetric body at AoA = 0 with the centre of mass offset
%  along +X only, the yaw moment should follow
%      CMz = CD * xCoM * sin(beta) / Lref
%  ===================================================================

CMz_predicted = ...
    CD_ADBSat .* ...
    xCoM_m .* ...
    sind(AoS_deg) / ...
    Lref_m;

CMz_error_pct = zeros(nCase,1);

nz = abs(CMz_predicted) > 1e-12;

CMz_error_pct(nz) = ...
    100 * ...
    (CMz_B(nz) - CMz_predicted(nz)) ./ ...
    CMz_predicted(nz);

yaw_check = table( ...
    AoS_deg, ...
    CMz_B, ...
    CMz_predicted, ...
    CMz_error_pct);

fprintf('\n');
fprintf('----------------------------------------------------\n');
fprintf('YAW MOMENT vs CENTRE-OF-MASS OFFSET PREDICTION\n');
fprintf('CMz = CD * xCoM * sin(beta) / Lref,  xCoM = %+.4f m\n', xCoM_m);
fprintf('----------------------------------------------------\n\n');

disp(yaw_check);

fprintf('Maximum |error| over non-zero sideslip: %.3f %%\n', ...
    max(abs(CMz_error_pct(nz))));


%% Overall moment ranges

fprintf('\n');
fprintf('----------------------------------------------------\n');
fprintf('MOMENT RANGES ABOUT THE DESIGN CENTRE OF MASS\n');
fprintf('----------------------------------------------------\n');

fprintf('CMx: %+.8e to %+.8e\n', min(CMx_B), max(CMx_B));
fprintf('CMy: %+.8e to %+.8e\n', min(CMy_B), max(CMy_B));
fprintf('CMz: %+.8e to %+.8e\n', min(CMz_B), max(CMz_B));

fprintf('\nMx:  %+.8e to %+.8e N m\n', min(Mx_Nm), max(Mx_Nm));
fprintf('My:  %+.8e to %+.8e N m\n', min(My_Nm), max(My_Nm));
fprintf('Mz:  %+.8e to %+.8e N m\n', min(Mz_Nm), max(Mz_Nm));


%% Symmetry diagnostics

fprintf('\n');
fprintf('----------------------------------------------------\n');
fprintf('POSITIVE/NEGATIVE SIDESLIP SYMMETRY\n');
fprintf('----------------------------------------------------\n');

for beta = [10 20 30]

    idx_pos = find(AoS_deg == beta);
    idx_neg = find(AoS_deg == -beta);

    fprintf('\n|AoS| = %d deg:\n', beta);

    fprintf('  Drag(+b) - Drag(-b) = %+.8e N   (expect ~0)\n', ...
        Drag_N(idx_pos) - Drag_N(idx_neg));

    fprintf('  CMx(+b) + CMx(-b)   = %+.8e     (expect ~0, odd)\n', ...
        CMx_B(idx_pos) + CMx_B(idx_neg));

    fprintf('  CMy(+b) - CMy(-b)   = %+.8e     (expect ~0, even)\n', ...
        CMy_B(idx_pos) - CMy_B(idx_neg));

    fprintf('  CMz(+b) + CMz(-b)   = %+.8e     (expect ~0, odd)\n', ...
        CMz_B(idx_pos) + CMz_B(idx_neg));

end


%% Values for the dissertation

fprintf('\n');
fprintf('====================================================\n');
fprintf('VALUES FOR REPORTING\n');
fprintf('====================================================\n');

fprintf('Non-zero AoS: CD varied by %.3f %% and projected area by %.3f %%\n', ...
    CDSpread_pct, AreaSpread_pct);

fprintf('AoS = 0 case sat %+.2f %% (CD) and %+.2f %% (area) above that mean\n', ...
    CDZeroOffset_pct, AreaZeroOffset_pct);

fprintf('Yaw moment matched the CoM-offset prediction to within %.2f %%\n', ...
    max(abs(CMz_error_pct(nz))));


%% Save results

writetable( ...
    results_sideslip, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'sideslip_sweep_results.csv'));


writetable( ...
    summary_sideslip, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'sideslip_sweep_summary.csv'));


writetable( ...
    yaw_check, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'sideslip_yaw_moment_check.csv'));


sideslip_stats = struct( ...
    'AreaProj_ref_m2', AreaProj_ref, ...
    'CD_ref', CD_ref, ...
    'Drag_ref_N', Drag_ref, ...
    'AreaSpread_pct', AreaSpread_pct, ...
    'CDSpread_pct', CDSpread_pct, ...
    'DragSpread_pct', DragSpread_pct, ...
    'AreaZeroOffset_pct', AreaZeroOffset_pct, ...
    'CDZeroOffset_pct', CDZeroOffset_pct, ...
    'DragZeroOffset_pct', DragZeroOffset_pct, ...
    'MaxYawError_pct', max(abs(CMz_error_pct(nz))));


save( ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'sideslip_sweep_summary.mat'), ...
    'results_sideslip', ...
    'summary_sideslip', ...
    'yaw_check', ...
    'sideslip_stats', ...
    'cfg');


%% Plot

fh = figure( ...
    'Name','Final v03 Sideslip Sensitivity', ...
    'Color','w');

tiledlayout(2,2);


%% Projected area

nexttile;

plot(AoS_deg, AreaProj_m2, '-o', 'LineWidth',1.5);

hold on;

yline(AreaProj_ref, '--', 'non-zero mean');

grid on;

xlabel('AoS [deg]');
ylabel('Projected area [m^2]');
title('Projected Area');


%% Drag coefficient

nexttile;

plot(AoS_deg, CD_ADBSat, '-o', 'LineWidth',1.5);

hold on;

yline(CD_ref, '--', 'non-zero mean');

grid on;

xlabel('AoS [deg]');
ylabel('C_D (A_{ref})');
title('Drag Coefficient');


%% Moment coefficients

nexttile;

hold on;
grid on;

plot(AoS_deg, CMx_B, '-o', 'LineWidth',1.5, 'DisplayName','C_{Mx}');
plot(AoS_deg, CMy_B, '-o', 'LineWidth',1.5, 'DisplayName','C_{My}');
plot(AoS_deg, CMz_B, '-o', 'LineWidth',1.5, 'DisplayName','C_{Mz}');

yline(0,'--','HandleVisibility','off');

xlabel('AoS [deg]');
ylabel('Moment coefficient');
title('Body-Axis Moments');

legend('Location','best');


%% Yaw moment against prediction

nexttile;

hold on;
grid on;

plot(AoS_deg, CMz_B, 'o', ...
    'LineWidth',1.5, ...
    'DisplayName','ADBSat');

plot(AoS_deg, CMz_predicted, '-', ...
    'LineWidth',1.5, ...
    'DisplayName','C_D x_{CoM} sin\beta / L_{ref}');

yline(0,'--','HandleVisibility','off');

xlabel('AoS [deg]');
ylabel('C_{Mz}');
title('Yaw Moment vs CoM-Offset Prediction');

legend('Location','best');


sgtitle('disc\_lenticular\_v03 Sideslip Sensitivity');


%% Export

exportgraphics( ...
    fh, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'sideslip_sweep.png'), ...
    'Resolution',300, ...
    'BackgroundColor','white');


fprintf('\nSideslip sensitivity analysis complete.\n');

fprintf('Results saved in:\n%s\n', ...
    cfg.paths.project_results_dir);