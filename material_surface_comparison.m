%% material_surface_comparison.m
% Material-informed surface comparison for disc_lenticular_v03.
%
% Four CLL surface-interaction cases are compared at -30, 0 and +30 deg.
%
% IMPORTANT:
% alphaT below is tangential ENERGY accommodation from the literature basis.
% ADBSat CLL uses tangential MOMENTUM accommodation sigmaT.
%
% Conversion used:
% alphaT = sigmaT*(2 - sigmaT)
% sigmaT = 1 - sqrt(1 - alphaT)
%
% Treat the material-specific cases as literature-informed aerodynamic
% sensitivity cases, not universal intrinsic material constants.

if ~exist('cfg','var')
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
%% Settings

model_name = cfg.model.name;
altitude_km = cfg.orbit.altitude_km;

aoa_values = [-30 0 30];
aos_deg = 0;

surface_names = { ...
    'Fully accommodating reference'; ...
    'Uncoated POSS-Novastrat'; ...
    'Al2O3-coated POSS-Novastrat conservative'; ...
    'Al2O3-coated POSS-Novastrat best-case'};

alphaN_values = [1.00; 0.20; 0.30; 0.18];
alphaT_values = [1.00; 0.95; 0.58; 0.40];

sigmaT_values = 1 - sqrt(1 - alphaT_values);

nSurface = numel(surface_names);
nAoA = numel(aoa_values);
nCase = nSurface * nAoA;

%% Load reference length

model_file = fullfile(cfg.paths.model_dir, [model_name '.mat']);

if ~isfile(model_file)
    error('Model file not found: %s', model_file);
end

S = load(model_file);
Lref_m = S.meshdata.Lref;

%% Preallocate

SurfaceID = zeros(nCase,1);
SurfaceCase = cell(nCase,1);

AoA_deg = zeros(nCase,1);
AoS_deg = zeros(nCase,1);

AlphaN = zeros(nCase,1);
AlphaT_Literature = zeros(nCase,1);
SigmaT_ADBSat = zeros(nCase,1);

AreaProj_m2 = zeros(nCase,1);
AreaRef_m2 = zeros(nCase,1);

CD_ADBSat = zeros(nCase,1);
CD_projected = zeros(nCase,1);
Drag_N = zeros(nCase,1);

CMy = zeros(nCase,1);
My_Nm = zeros(nCase,1);

%% Header

fprintf('\n====================================================\n');
fprintf('FINAL v03 MATERIAL-INFORMED SURFACE COMPARISON\n');
fprintf('====================================================\n');
fprintf('Model:      %s\n', model_name);
fprintf('Altitude:   %.1f km\n', altitude_km);
fprintf('AoA cases:  -30, 0, +30 deg\n');
fprintf('AoS:        %.1f deg\n', aos_deg);
fprintf('GSIM:       CLL\n');
fprintf('Shadow:     %d\n', cfg.flags.shadow);
fprintf('Solar:      %d\n', cfg.flags.solar);
fprintf('Wall T:     %.1f K\n', cfg.gsi.wall_temperature_K);
fprintf('CoM [m]:    [%+.6f  %+.6f  %+.6f]\n\n', ...
    cfg.model.com_G_m(1), cfg.model.com_G_m(2), cfg.model.com_G_m(3));

for j = 1:nSurface
    fprintf('%d. %s\n', j, surface_names{j});
    fprintf('   alphaN = %.4f\n', alphaN_values(j));
    fprintf('   alphaT = %.4f\n', alphaT_values(j));
    fprintf('   sigmaT = %.6f\n\n', sigmaT_values(j));
end

%% Run cases

k = 0;

for i = 1:nAoA

    aoa = aoa_values(i);

    for j = 1:nSurface

        k = k + 1;

        override = struct();
        override.alphaN = alphaN_values(j);
        override.sigmaT = sigmaT_values(j);

        fprintf('Case %2d of %2d: AoA = %+5.1f deg | %s\n', ...
            k, nCase, aoa, surface_names{j});

        out = run_adbsat_case( ...
            cfg_run, ...
            model_name, ...
            altitude_km, ...
            aoa, ...
            aos_deg, ...
            'CLL', ...
            override);

        q = 0.5 * out.rho_kgm3 * out.vinf_ms^2;

        SurfaceID(k) = j;
        SurfaceCase{k} = surface_names{j};

        AoA_deg(k) = aoa;
        AoS_deg(k) = aos_deg;

        AlphaN(k) = alphaN_values(j);
        AlphaT_Literature(k) = alphaT_values(j);
        SigmaT_ADBSat(k) = sigmaT_values(j);

        AreaProj_m2(k) = out.AreaProj_m2;
        AreaRef_m2(k) = out.AreaRef_m2;

        CD_ADBSat(k) = -out.Cf_w(1);
        CD_projected(k) = CD_ADBSat(k) * AreaRef_m2(k) / AreaProj_m2(k);

        Drag_N(k) = q * AreaRef_m2(k) * CD_ADBSat(k);

        CMy(k) = out.Cm_B(2);
        My_Nm(k) = q * AreaRef_m2(k) * Lref_m * CMy(k);

    end
end

%% Results table

results_material = table( ...
    SurfaceID, ...
    SurfaceCase, ...
    AoA_deg, ...
    AoS_deg, ...
    AlphaN, ...
    AlphaT_Literature, ...
    SigmaT_ADBSat, ...
    AreaProj_m2, ...
    AreaRef_m2, ...
    CD_ADBSat, ...
    CD_projected, ...
    Drag_N, ...
    CMy, ...
    My_Nm);

fprintf('\n====================================================\n');
fprintf('MATERIAL-INFORMED SURFACE RESULTS\n');
fprintf('====================================================\n\n');
disp(results_material);

%% Compare every surface with fully accommodating reference at same AoA

ReferenceDrag_N = zeros(nCase,1);
DragChange_pct = zeros(nCase,1);

ReferenceCMy = zeros(nCase,1);
CMyDifference = zeros(nCase,1);

ReferenceMy_Nm = zeros(nCase,1);
MyDifference_Nm = zeros(nCase,1);

for i = 1:nAoA

    aoa = aoa_values(i);

    ref_idx = (AoA_deg == aoa) & (SurfaceID == 1);

    if sum(ref_idx) ~= 1
        error('Expected one reference case at AoA %.1f deg.', aoa);
    end

    Dref = Drag_N(ref_idx);
    Cref = CMy(ref_idx);
    Mref = My_Nm(ref_idx);

    angle_idx = (AoA_deg == aoa);

    ReferenceDrag_N(angle_idx) = Dref;
    DragChange_pct(angle_idx) = ...
        100 * (Drag_N(angle_idx) - Dref) / Dref;

    ReferenceCMy(angle_idx) = Cref;
    CMyDifference(angle_idx) = CMy(angle_idx) - Cref;

    ReferenceMy_Nm(angle_idx) = Mref;
    MyDifference_Nm(angle_idx) = My_Nm(angle_idx) - Mref;

end

comparison_material = table( ...
    SurfaceID, ...
    SurfaceCase, ...
    AoA_deg, ...
    AlphaN, ...
    AlphaT_Literature, ...
    SigmaT_ADBSat, ...
    Drag_N, ...
    DragChange_pct, ...
    CMy, ...
    CMyDifference, ...
    My_Nm, ...
    MyDifference_Nm);

fprintf('\n====================================================\n');
fprintf('RELATIVE TO FULLY ACCOMMODATING CLL REFERENCE\n');
fprintf('====================================================\n\n');
disp(comparison_material);

%% Nominal attitude comparison

nominal_idx = (AoA_deg == 0);
nominal_material = comparison_material(nominal_idx,:);

fprintf('\n====================================================\n');
fprintf('NOMINAL 0-DEG MATERIAL COMPARISON\n');
fprintf('====================================================\n\n');
disp(nominal_material);

%% Summary

fprintf('\n====================================================\n');
fprintf('MATERIAL-COMPARISON SUMMARY\n');
fprintf('====================================================\n');

for j = 1:nSurface

    idx = (SurfaceID == j);

    fprintf('\n%s\n', surface_names{j});
    fprintf('Drag change range: %+.3f %% to %+.3f %%\n', ...
        min(DragChange_pct(idx)), max(DragChange_pct(idx)));
    fprintf('Maximum |CMy difference|: %.8e\n', ...
        max(abs(CMyDifference(idx))));
    fprintf('Maximum |My difference|:  %.8e N m\n', ...
        max(abs(MyDifference_Nm(idx))));

end

fprintf('\nThese are literature-informed CLL sensitivity cases.\n');
fprintf('Do not treat the fitted parameters as universal material constants.\n');

%% Save

writetable(results_material, ...
    fullfile(cfg.paths.project_results_dir, ...
    'material_surface_results.csv'));

writetable(comparison_material, ...
    fullfile(cfg.paths.project_results_dir, ...
    'material_surface_comparison.csv'));

writetable(nominal_material, ...
    fullfile(cfg.paths.project_results_dir, ...
    'material_surface_nominal_comparison.csv'));

save( ...
    fullfile(cfg.paths.project_results_dir, ...
    'material_surface_summary.mat'), ...
    'results_material', ...
    'comparison_material', ...
    'nominal_material', ...
    'surface_names', ...
    'alphaN_values', ...
    'alphaT_values', ...
    'sigmaT_values', ...
    'cfg');

%% ================================================================
% DISSERTATION FIGURE - SURFACE-PROPERTY SENSITIVITY
% ================================================================

fig = figure( ...
    'Name','Material Surface Sensitivity', ...
    'Color','w', ...
    'Position',[100 100 1500 620]);

t = tiledlayout(fig,1,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

% Short labels for dissertation figure
figure_labels = { ...
    'Fully accommodating'; ...
    'Uncoated POSS'; ...
    'Coated, conservative'; ...
    'Coated, best-case'};

% Distinct markers so the plot remains clear in print
markers = {'o','s','^','d'};

%% ================================================================
% PANEL (a) - PERCENTAGE CHANGE IN DRAG
% ================================================================

ax1 = nexttile(t,1);

hold(ax1,'on');
grid(ax1,'on');
box(ax1,'on');

hDrag = gobjects(nSurface,1);

for j = 1:nSurface

    idx = (SurfaceID == j);

    % Sort by AoA for clean plotting
    x = AoA_deg(idx);
    y = DragChange_pct(idx);

    [x,order] = sort(x);
    y = y(order);

    hDrag(j) = plot( ...
        ax1, ...
        x, ...
        y, ...
        ['-' markers{j}], ...
        'LineWidth',1.8, ...
        'MarkerSize',9, ...
        'DisplayName',figure_labels{j});

end

% Zero-reference line
hZero1 = yline(ax1,0,'--', ...
    'LineWidth',1.0);

hZero1.HandleVisibility = 'off';

xlabel(ax1,'AoA [deg]', ...
    'FontSize',16);

ylabel(ax1,'Change in drag [%]', ...
    'FontSize',16);

title(ax1,'(a) Drag sensitivity', ...
    'FontSize',17, ...
    'FontWeight','bold');

legend(ax1, ...
    hDrag, ...
    figure_labels, ...
    'Location','best', ...
    'FontSize',12);

xlim(ax1,[-32 32]);
xticks(ax1,[-30 0 30]);

set(ax1, ...
    'FontName','Times New Roman', ...
    'FontSize',14, ...
    'LineWidth',0.9, ...
    'Color','w', ...
    'XColor','k', ...
    'YColor','k', ...
    'GridColor',[0.72 0.72 0.72], ...
    'GridAlpha',0.40);

%% ================================================================
% PANEL (b) - PITCHING-MOMENT COEFFICIENT
% ================================================================

ax2 = nexttile(t,2);

hold(ax2,'on');
grid(ax2,'on');
box(ax2,'on');

hMoment = gobjects(nSurface,1);

for j = 1:nSurface

    idx = (SurfaceID == j);

    x = AoA_deg(idx);
    y = CMy(idx);

    [x,order] = sort(x);
    y = y(order);

    hMoment(j) = plot( ...
        ax2, ...
        x, ...
        y, ...
        ['-' markers{j}], ...
        'LineWidth',1.8, ...
        'MarkerSize',9, ...
        'DisplayName',figure_labels{j});

end

% Zero-reference line
hZero2 = yline(ax2,0,'--', ...
    'LineWidth',1.0);

hZero2.HandleVisibility = 'off';

xlabel(ax2,'AoA [deg]', ...
    'FontSize',16);

ylabel(ax2,'C_{My}', ...
    'FontSize',16);

title(ax2,'(b) Pitching-moment coefficient', ...
    'FontSize',17, ...
    'FontWeight','bold');

legend(ax2, ...
    hMoment, ...
    figure_labels, ...
    'Location','best', ...
    'FontSize',12);

xlim(ax2,[-32 32]);
xticks(ax2,[-30 0 30]);

set(ax2, ...
    'FontName','Times New Roman', ...
    'FontSize',14, ...
    'LineWidth',0.9, ...
    'Color','w', ...
    'XColor','k', ...
    'YColor','k', ...
    'GridColor',[0.72 0.72 0.72], ...
    'GridAlpha',0.40);

%% ================================================================
% EXPORT
% ================================================================

pngFile = fullfile( ...
    cfg.paths.project_results_dir, ...
    'Figure_4_4_surface_property_sensitivity.png');

pdfFile = fullfile( ...
    cfg.paths.project_results_dir, ...
    'Figure_4_4_surface_property_sensitivity.pdf');

exportgraphics( ...
    fig, ...
    pngFile, ...
    'Resolution',600, ...
    'BackgroundColor','white');

exportgraphics( ...
    fig, ...
    pdfFile, ...
    'ContentType','vector', ...
    'BackgroundColor','white');

fprintf('\nMaterial-informed surface comparison complete.\n');
fprintf('Figure saved to:\n%s\n',pngFile);
