%% attitude_sweep.m
% Final operational pitch sweep for disc_lenticular_v03.
% Uses the active design CoM defined in project_config.m.

%% Load project configuration

if ~exist('cfg', 'var')
    project_config
end

cfg_run = cfg;
cfg_run.flags.verbose = 0;

%% ================================================================
% Dissertation figure style
% ================================================================

set(groot, ...
    'defaultFigureColor','w', ...
    'defaultFigureInvertHardcopy','off', ...
    'defaultAxesColor','w', ...
    'defaultAxesXColor','k', ...
    'defaultAxesYColor','k', ...
    'defaultAxesZColor','k', ...
    'defaultAxesGridColor',[0.70 0.70 0.70], ...
    'defaultAxesMinorGridColor',[0.82 0.82 0.82], ...
    'defaultAxesGridAlpha',0.35, ...
    'defaultAxesMinorGridAlpha',0.20, ...
    'defaultAxesFontName','Times New Roman', ...
    'defaultAxesFontSize',11, ...
    'defaultAxesLineWidth',0.8, ...
    'defaultAxesBox','on', ...
    'defaultTextColor','k', ...
    'defaultTextFontName','Times New Roman', ...
    'defaultTextFontSize',11, ...
    'defaultLineLineWidth',1.4, ...
    'defaultLineMarkerSize',6, ...
    'defaultLegendColor','w', ...
    'defaultLegendTextColor','k', ...
    'defaultLegendFontName','Times New Roman', ...
    'defaultLegendFontSize',10, ...
    'defaultLegendBox','off');

%% Analysis settings

model_name = cfg_run.model.name;
altitude_km = cfg_run.orbit.altitude_km;
gsi_model = cfg_run.gsi.baseline_model;

aoa_values = cfg_run.test.aoa_deg(:);
aos_deg = cfg_run.test.aos_deg;

if numel(aos_deg) ~= 1
    error(['Final operational pitch sweep requires one AoS value. ' ...
        'Set cfg.test.aos_deg = 0 in project_config.m.']);
end

if ~strcmp(model_name, 'disc_lenticular_v03')
    error('Unexpected model selected. Expected disc_lenticular_v03.');
end


%% Load model reference length

model_file = fullfile(cfg_run.paths.model_dir, [model_name '.mat']);

if ~isfile(model_file)
    error('Model file not found: %s', model_file);
end

M = load(model_file);

if ~isfield(M, 'meshdata') || ~isfield(M.meshdata, 'Lref')
    error('Could not read meshdata.Lref from final model file.');
end

Lref_m = M.meshdata.Lref;


%% Preallocate

nCases = numel(aoa_values);

AoA_deg = aoa_values;
AoS_deg = repmat(aos_deg, nCases, 1);

DynamicPressure_Pa = zeros(nCases,1);
AreaProj_m2 = zeros(nCases,1);
AreaRef_m2 = zeros(nCases,1);

CD_ADBSat = zeros(nCases,1);
CD_projected = zeros(nCases,1);
Drag_N = zeros(nCases,1);

CFx_w = zeros(nCases,1);
CFy_w = zeros(nCases,1);
CFz_w = zeros(nCases,1);

CMx_B = zeros(nCases,1);
CMy_B = zeros(nCases,1);
CMz_B = zeros(nCases,1);
My_Nm = zeros(nCases,1);


%% Run operational pitch sweep

fprintf('\n====================================================\n');
fprintf('FINAL v03 OPERATIONAL PITCH SWEEP\n');
fprintf('====================================================\n');
fprintf('Model:      %s\n', model_name);
fprintf('Altitude:   %.1f km\n', altitude_km);
fprintf('AoS:        %.1f deg\n', aos_deg);
fprintf('AoA range:  %.1f to %.1f deg\n', min(aoa_values), max(aoa_values));
fprintf('GSIM:       %s\n', gsi_model);
fprintf('Shadow:     %d\n', cfg_run.flags.shadow);
fprintf('Solar:      %d\n', cfg_run.flags.solar);
fprintf('CoM [m]:    [%+.6f  %+.6f  %+.6f]\n', ...
    cfg_run.model.com_G_m(1), ...
    cfg_run.model.com_G_m(2), ...
    cfg_run.model.com_G_m(3));
fprintf('Lref:       %.9f m\n\n', Lref_m);

for i = 1:nCases

    aoa = aoa_values(i);

    fprintf('Case %2d of %2d: AoA = %+6.1f deg, AoS = %.1f deg\n', ...
        i, nCases, aoa, aos_deg);

    out = run_adbsat_case( ...
        cfg_run, ...
        model_name, ...
        altitude_km, ...
        aoa, ...
        aos_deg, ...
        gsi_model);

    q = 0.5 * out.rho_kgm3 * out.vinf_ms^2;
    cd_adbsat = -out.Cf_w(1);

    if ~isfinite(out.AreaProj_m2) || out.AreaProj_m2 <= 0
        error('Invalid projected area returned at AoA %.2f deg.', aoa);
    end

    cd_projected = ...
        cd_adbsat * out.AreaRef_m2 / out.AreaProj_m2;

    drag_N = ...
        q * out.AreaRef_m2 * cd_adbsat;

    cmy = out.Cm_B(2);

    my_Nm = ...
        q * out.AreaRef_m2 * Lref_m * cmy;

    DynamicPressure_Pa(i) = q;
    AreaProj_m2(i) = out.AreaProj_m2;
    AreaRef_m2(i) = out.AreaRef_m2;

    CD_ADBSat(i) = cd_adbsat;
    CD_projected(i) = cd_projected;
    Drag_N(i) = drag_N;

    CFx_w(i) = out.Cf_w(1);
    CFy_w(i) = out.Cf_w(2);
    CFz_w(i) = out.Cf_w(3);

    CMx_B(i) = out.Cm_B(1);
    CMy_B(i) = out.Cm_B(2);
    CMz_B(i) = out.Cm_B(3);
    My_Nm(i) = my_Nm;

end


%% Results table

results = table( ...
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
    My_Nm);


%% Display results

fprintf('\n====================================================\n');
fprintf('OPERATIONAL PITCH-SWEEP RESULTS\n');
fprintf('====================================================\n\n');
disp(results)


%% Summary

[drag_min, i_drag_min] = min(Drag_N);
[drag_max, i_drag_max] = max(Drag_N);
[abs_cmy_max, i_cmy_max] = max(abs(CMy_B));
[abs_my_max, i_my_max] = max(abs(My_Nm));

fprintf('\n====================================================\n');
fprintf('PITCH-SWEEP SUMMARY\n');
fprintf('====================================================\n');
fprintf('Minimum drag:      %.8e N at AoA = %+.1f deg\n', ...
    drag_min, AoA_deg(i_drag_min));
fprintf('Maximum drag:      %.8e N at AoA = %+.1f deg\n', ...
    drag_max, AoA_deg(i_drag_max));
fprintf('Maximum |CMy|:     %.8e at AoA = %+.1f deg\n', ...
    abs_cmy_max, AoA_deg(i_cmy_max));
fprintf('Maximum |My|:      %.8e N m at AoA = %+.1f deg\n', ...
    abs_my_max, AoA_deg(i_my_max));

idx_zero = find(abs(AoA_deg) < 1e-12, 1);
if ~isempty(idx_zero)
    fprintf('\nNominal AoA = 0 deg:\n');
    fprintf('Projected area:     %.9f m^2\n', AreaProj_m2(idx_zero));
    fprintf('ADBSat CD:          %.9f\n', CD_ADBSat(idx_zero));
    fprintf('Projected-area CD:  %.9f\n', CD_projected(idx_zero));
    fprintf('Drag:               %.8e N\n', Drag_N(idx_zero));
    fprintf('CMy:                %+.8e\n', CMy_B(idx_zero));
    fprintf('My:                 %+.8e N m\n', My_Nm(idx_zero));
end


%% Save numerical outputs

results_csv = fullfile( ...
    cfg_run.paths.project_results_dir, ...
    'operational_pitch_sweep.csv');

writetable(results, results_csv);

attitude_results.model = model_name;
attitude_results.altitude_km = altitude_km;
attitude_results.gsi_model = gsi_model;
attitude_results.shadow = cfg_run.flags.shadow;
attitude_results.solar = cfg_run.flags.solar;
attitude_results.com_G_m = cfg_run.model.com_G_m;
attitude_results.Lref_m = Lref_m;
attitude_results.table = results;

save( ...
    fullfile(cfg_run.paths.project_results_dir, ...
    'attitude_sweep_summary.mat'), ...
    'attitude_results', ...
    'cfg');


%% Final analysis plots

fig = figure('Name', 'Final v03 Operational Pitch Sweep');
tiledlayout(2,3)

nexttile
plot(AoA_deg, AreaProj_m2, '-o')
xlabel('AoA [deg]')
ylabel('Projected area [m^2]')
title('Projected Area')
grid on

nexttile
plot(AoA_deg, CD_ADBSat, '-o')
xlabel('AoA [deg]')
ylabel('C_D')
title('ADBSat C_D')
grid on

nexttile
plot(AoA_deg, CD_projected, '-o')
xlabel('AoA [deg]')
ylabel('C_D (projected area)')
title('Projected-Area C_D')
grid on

nexttile
plot(AoA_deg, Drag_N, '-o')
xlabel('AoA [deg]')
ylabel('Drag [N]')
title('Dimensional Drag')
grid on

nexttile
plot(AoA_deg, CMy_B, '-o')
yline(0, '--')
xlabel('AoA [deg]')
ylabel('C_{My}')
title('Pitching-Moment Coefficient')
grid on

nexttile
plot(AoA_deg, My_Nm, '-o')
yline(0, '--')
xlabel('AoA [deg]')
ylabel('M_y [N m]')
title('Dimensional Pitching Moment')
grid on

sgtitle('disc\_lenticular\_v03 Operational Pitch Sweep')

savefig(fig, fullfile( ...
    cfg_run.paths.project_results_dir, ...
    'operational_pitch_sweep.fig'));

exportgraphics(fig, fullfile( ...
    cfg_run.paths.project_results_dir, ...
    'operational_pitch_sweep.png'), ...
    'Resolution', 300);


fprintf('\nOperational pitch sweep complete.\n');
fprintf('Results saved in:\n%s\n', cfg_run.paths.project_results_dir);
