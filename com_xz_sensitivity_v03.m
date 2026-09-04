%% X-Z CENTRE-OF-MASS SENSITIVITY - V03
%
% Evaluates aerodynamic pitching moment over the operational
% pitch range for different X and Z centre-of-mass positions.
%
% ADBSat is run only at the geometric-centre reference position.
% Moments at alternative CoM positions are then obtained using
% rigid-body moment translation.

if ~exist('cfg','var')
    project_config
end

fprintf('\n====================================================\n');
fprintf('X-Z CENTRE-OF-MASS SENSITIVITY - V03\n');
fprintf('====================================================\n');

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


%% Configuration

model_name = 'disc_lenticular_v03';

altitude_km = 300;

aoa_deg = [-30 -20 -10 0 10 20 30];

aos_deg = 0;

gsi_model = cfg.gsi.baseline_model;


%% Force correct model and baseline settings

cfg_case = cfg;

cfg_case.model.name = model_name;

cfg_case.model.com_G_m = [0;0;0];

cfg_case.flags.shadow = 1;
cfg_case.flags.solar = 0;


%% Correct results folder

cfg_case.paths.project_results_dir = fullfile( ...
    cfg_case.paths.project_root, ...
    'results', ...
    model_name);

if ~exist(cfg_case.paths.project_results_dir,'dir')
    mkdir(cfg_case.paths.project_results_dir);
end


%% Load reference length

model_file = fullfile( ...
    cfg_case.paths.model_dir, ...
    [model_name '.mat']);

S = load(model_file);

Lref = S.meshdata.Lref;

fprintf('Model:       %s\n', model_name);
fprintf('Altitude:    %.1f km\n', altitude_km);
fprintf('Lref:        %.9f m\n', Lref);
fprintf('Shadowing:   ON\n');


%% Run seven baseline ADBSat cases about geometric centre

nA = numel(aoa_deg);

Cfx = zeros(nA,1);
Cfz = zeros(nA,1);
CMy_origin = zeros(nA,1);

fprintf('\nRunning baseline aerodynamic cases...\n');

for i = 1:nA

    fprintf('AoA = %+5.1f deg\n', aoa_deg(i));

    out = run_adbsat_case( ...
        cfg_case, ...
        model_name, ...
        altitude_km, ...
        aoa_deg(i), ...
        aos_deg, ...
        gsi_model);

    Cfx(i) = out.Cf_B(1);
    Cfz(i) = out.Cf_B(3);

    % Since cfg_case CoM = [0;0;0], this is the
    % moment coefficient about the geometric origin.
    CMy_origin(i) = out.Cm_B(2);

end


%% Baseline metrics

rms_origin = sqrt(mean(CMy_origin.^2));
max_origin = max(abs(CMy_origin));

fprintf('\n====================================================\n');
fprintf('GEOMETRIC-CENTRE BASELINE\n');
fprintf('====================================================\n');

fprintf('RMS |CMy| measure:     %.8e\n', rms_origin);
fprintf('Maximum |CMy|:         %.8e\n', max_origin);


%% Exact least-squares X-Z optimum
%
% Moment translation:
%
% CMy_new =
% CMy_origin
% + (x_G/Lref)*Cfz
% + (z_G/Lref)*Cfx
%
% Solve for x_G and z_G that minimise the squared pitching
% moment across all seven operational AoA cases.

A = [ ...
    Cfz ./ Lref, ...
    Cfx ./ Lref];

target = -CMy_origin;

xz_opt_m = A \ target;

x_opt_m = xz_opt_m(1);
z_opt_m = xz_opt_m(2);


%% Calculate pitching moments at least-squares optimum

CMy_opt = ...
    CMy_origin ...
    + (x_opt_m ./ Lref) .* Cfz ...
    + (z_opt_m ./ Lref) .* Cfx;

rms_opt = sqrt(mean(CMy_opt.^2));
max_opt = max(abs(CMy_opt));


%% Percentage improvements

rms_reduction_pct = ...
    100 * (1 - rms_opt/rms_origin);

max_reduction_pct = ...
    100 * (1 - max_opt/max_origin);


%% Print optimum

fprintf('\n====================================================\n');
fprintf('LEAST-SQUARES X-Z CoM RESULT\n');
fprintf('====================================================\n');

fprintf('x CoM:                 %+8.4f mm\n', ...
    x_opt_m * 1000);

fprintf('y CoM:                 %+8.4f mm\n', ...
    0);

fprintf('z CoM:                 %+8.4f mm\n', ...
    z_opt_m * 1000);

fprintf('\n');

fprintf('Original RMS CMy:      %.8e\n', rms_origin);
fprintf('Optimised RMS CMy:     %.8e\n', rms_opt);
fprintf('RMS reduction:         %.2f %%\n', rms_reduction_pct);

fprintf('\n');

fprintf('Original max |CMy|:    %.8e\n', max_origin);
fprintf('Optimised max |CMy|:   %.8e\n', max_opt);
fprintf('Max reduction:         %.2f %%\n', max_reduction_pct);


%% Angle-by-angle comparison

comparison = table( ...
    aoa_deg(:), ...
    Cfx, ...
    Cfz, ...
    CMy_origin, ...
    CMy_opt, ...
    'VariableNames', { ...
    'AoA_deg', ...
    'Cfx', ...
    'Cfz', ...
    'CMy_origin', ...
    'CMy_optimised'});

fprintf('\n====================================================\n');
fprintf('ANGLE-BY-ANGLE COMPARISON\n');
fprintf('====================================================\n');

disp(comparison);


%% Grid sensitivity
%
% Broad +/-10 mm investigation in both X and Z.
% This is post-processing only; ADBSat is NOT rerun.

x_grid_mm = -10:0.5:10;
z_grid_mm = -10:0.5:10;

nX = numel(x_grid_mm);
nZ = numel(z_grid_mm);

RMS_CMy = zeros(nZ,nX);
MAX_CMy = zeros(nZ,nX);

for iz = 1:nZ

    z_m = z_grid_mm(iz) / 1000;

    for ix = 1:nX

        x_m = x_grid_mm(ix) / 1000;

        CMy_test = ...
            CMy_origin ...
            + (x_m/Lref).*Cfz ...
            + (z_m/Lref).*Cfx;

        RMS_CMy(iz,ix) = ...
            sqrt(mean(CMy_test.^2));

        MAX_CMy(iz,ix) = ...
            max(abs(CMy_test));

    end
end


%% Best grid point based on RMS

[min_rms_grid, linear_idx] = min(RMS_CMy(:));

[iz_best, ix_best] = ind2sub( ...
    size(RMS_CMy), ...
    linear_idx);

x_best_grid_mm = x_grid_mm(ix_best);
z_best_grid_mm = z_grid_mm(iz_best);


fprintf('\n====================================================\n');
fprintf('GRID CHECK\n');
fprintf('====================================================\n');

fprintf('Best grid X:           %+7.2f mm\n', ...
    x_best_grid_mm);

fprintf('Best grid Z:           %+7.2f mm\n', ...
    z_best_grid_mm);

fprintf('Grid RMS CMy:          %.8e\n', ...
    min_rms_grid);


%% Minimum maximum-moment grid solution

[min_max_grid, linear_idx2] = min(MAX_CMy(:));

[iz_minmax, ix_minmax] = ind2sub( ...
    size(MAX_CMy), ...
    linear_idx2);

x_minmax_mm = x_grid_mm(ix_minmax);
z_minmax_mm = z_grid_mm(iz_minmax);


fprintf('\nMinimum-maximum solution:\n');

fprintf('X CoM:                 %+7.2f mm\n', ...
    x_minmax_mm);

fprintf('Z CoM:                 %+7.2f mm\n', ...
    z_minmax_mm);

fprintf('Maximum |CMy|:         %.8e\n', ...
    min_max_grid);


%% Save results

summary_file = fullfile( ...
    cfg_case.paths.project_results_dir, ...
    'com_xz_sensitivity_v03.mat');

save(summary_file, ...
    'aoa_deg', ...
    'Cfx', ...
    'Cfz', ...
    'CMy_origin', ...
    'CMy_opt', ...
    'Lref', ...
    'x_opt_m', ...
    'z_opt_m', ...
    'rms_origin', ...
    'rms_opt', ...
    'max_origin', ...
    'max_opt', ...
    'x_grid_mm', ...
    'z_grid_mm', ...
    'RMS_CMy', ...
    'MAX_CMy');


csv_file = fullfile( ...
    cfg_case.paths.project_results_dir, ...
    'com_xz_optimised_comparison.csv');

writetable(comparison, csv_file);


fprintf('\nSaved:\n%s\n%s\n', ...
    summary_file, ...
    csv_file);

fprintf('\nX-Z CoM sensitivity complete.\n');