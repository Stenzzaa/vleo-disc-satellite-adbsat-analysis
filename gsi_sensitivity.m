%% gsi_sensitivity.m
% Final GSIM comparison for disc_lenticular_v03.
% Compares baseline Sentman and CLL assumptions at representative
% operational pitch attitudes.

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

models = {'sentman','CLL'};
labels = {'Sentman','CLL'};

nAoA = numel(aoa_values);
nModel = numel(models);
nCase = nAoA*nModel;

%% Load Lref

model_file = fullfile( ...
    cfg.paths.model_dir, ...
    [model_name '.mat']);

S = load(model_file);
Lref_m = S.meshdata.Lref;

%% Preallocate

GSIM = strings(nCase,1);
AoA_deg = zeros(nCase,1);
AoS_deg = zeros(nCase,1);

AreaProj_m2 = zeros(nCase,1);
AreaRef_m2 = zeros(nCase,1);

CD_ADBSat = zeros(nCase,1);
CD_projected = zeros(nCase,1);
Drag_N = zeros(nCase,1);

CMy = zeros(nCase,1);
My_Nm = zeros(nCase,1);

%% Header

fprintf('\n====================================================\n');
fprintf('FINAL v03 GSIM SENSITIVITY\n');
fprintf('====================================================\n');

fprintf('Model:      %s\n', model_name);
fprintf('Altitude:   %.1f km\n', altitude_km);
fprintf('AoA cases:  -30, 0, +30 deg\n');
fprintf('AoS:        %.1f deg\n', aos_deg);
fprintf('Shadow:     %d\n', cfg.flags.shadow);
fprintf('Solar:      %d\n', cfg.flags.solar);

fprintf('CoM [m]:    [%+.6f  %+.6f  %+.6f]\n\n', ...
    cfg.model.com_G_m(1), ...
    cfg.model.com_G_m(2), ...
    cfg.model.com_G_m(3));

fprintf('Sentman alpha = %.3f\n', ...
    cfg.gsi.sentman.alpha);

fprintf('CLL alphaN = %.3f, sigmaT = %.3f\n\n', ...
    cfg.gsi.cll.alphaN, ...
    cfg.gsi.cll.sigmaT);

%% Run cases

k = 0;

for i = 1:nAoA

    for j = 1:nModel

        k = k + 1;

        aoa = aoa_values(i);
        model = models{j};

        fprintf( ...
            'Case %d of %d: AoA = %+5.1f deg, GSIM = %s\n', ...
            k, nCase, aoa, labels{j});

        out = run_adbsat_case( ...
            cfg_run, ...
            model_name, ...
            altitude_km, ...
            aoa, ...
            aos_deg, ...
            model);

        q = 0.5*out.rho_kgm3*out.vinf_ms^2;

        GSIM(k) = labels{j};
        AoA_deg(k) = aoa;
        AoS_deg(k) = aos_deg;

        AreaProj_m2(k) = out.AreaProj_m2;
        AreaRef_m2(k) = out.AreaRef_m2;

        CD_ADBSat(k) = -out.Cf_w(1);

        CD_projected(k) = ...
            CD_ADBSat(k)*AreaRef_m2(k)/AreaProj_m2(k);

        Drag_N(k) = ...
            q*AreaRef_m2(k)*CD_ADBSat(k);

        CMy(k) = out.Cm_B(2);

        My_Nm(k) = ...
            q*AreaRef_m2(k)*Lref_m*CMy(k);

    end
end

%% Results

results_gsi = table( ...
    GSIM, ...
    AoA_deg, ...
    AoS_deg, ...
    AreaProj_m2, ...
    CD_ADBSat, ...
    CD_projected, ...
    Drag_N, ...
    CMy, ...
    My_Nm);

fprintf('\n====================================================\n');
fprintf('GSIM SENSITIVITY RESULTS\n');
fprintf('====================================================\n\n');

disp(results_gsi)

%% Sentman vs CLL percentage differences

AoA_summary = aoa_values(:);

Drag_Sentman = zeros(nAoA,1);
Drag_CLL = zeros(nAoA,1);
Drag_Difference_pct = zeros(nAoA,1);

CMy_Sentman = zeros(nAoA,1);
CMy_CLL = zeros(nAoA,1);
CMy_AbsDifference = zeros(nAoA,1);

My_Sentman_Nm = zeros(nAoA,1);
My_CLL_Nm = zeros(nAoA,1);
My_AbsDifference_Nm = zeros(nAoA,1);

for i = 1:nAoA

    idxS = GSIM == "Sentman" & AoA_deg == aoa_values(i);
    idxC = GSIM == "CLL"     & AoA_deg == aoa_values(i);

    Drag_Sentman(i) = Drag_N(idxS);
    Drag_CLL(i) = Drag_N(idxC);

    Drag_Difference_pct(i) = ...
        100*(Drag_CLL(i)-Drag_Sentman(i))/Drag_Sentman(i);

    CMy_Sentman(i) = CMy(idxS);
    CMy_CLL(i) = CMy(idxC);

    CMy_AbsDifference(i) = ...
        abs(CMy_CLL(i)-CMy_Sentman(i));

    My_Sentman_Nm(i) = My_Nm(idxS);
    My_CLL_Nm(i) = My_Nm(idxC);

    My_AbsDifference_Nm(i) = ...
        abs(My_CLL_Nm(i)-My_Sentman_Nm(i));

end

summary_gsi = table( ...
    AoA_summary, ...
    Drag_Sentman, ...
    Drag_CLL, ...
    Drag_Difference_pct, ...
    CMy_Sentman, ...
    CMy_CLL, ...
    CMy_AbsDifference, ...
    My_Sentman_Nm, ...
    My_CLL_Nm, ...
    My_AbsDifference_Nm);

fprintf('\n====================================================\n');
fprintf('SENTMAN vs CLL SUMMARY\n');
fprintf('====================================================\n\n');

disp(summary_gsi)

%% Save

writetable( ...
    results_gsi, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'gsi_sensitivity_results.csv'));

writetable( ...
    summary_gsi, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'gsi_sensitivity_comparison.csv'));

save( ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'gsi_sensitivity_summary.mat'), ...
    'results_gsi', ...
    'summary_gsi', ...
    'cfg');

%% Plot

figure('Name','Final v03 GSIM Sensitivity');

tiledlayout(1,2);

nexttile

hold on
grid on

for j = 1:nModel

    mask = GSIM == labels{j};

    plot( ...
        AoA_deg(mask), ...
        Drag_N(mask), ...
        '-o', ...
        'LineWidth',1.5);

end

xlabel('AoA [deg]');
ylabel('Drag [N]');
title('Dimensional Drag');
legend(labels,'Location','best');

nexttile

hold on
grid on

for j = 1:nModel

    mask = GSIM == labels{j};

    plot( ...
        AoA_deg(mask), ...
        CMy(mask), ...
        '-o', ...
        'LineWidth',1.5);

end

yline(0,'--');

xlabel('AoA [deg]');
ylabel('C_{My}');
title('Pitching-Moment Coefficient');
legend(labels,'Location','best');

sgtitle('disc\_lenticular\_v03 GSIM Sensitivity');

exportgraphics( ...
    gcf, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'gsi_sensitivity.png'), ...
    'Resolution',300);

fprintf('\nGSIM sensitivity complete.\n');