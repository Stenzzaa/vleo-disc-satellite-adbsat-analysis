%% accommodation_offnominal.m
% Final off-nominal Sentman accommodation sensitivity.
%
% Runs ONLY four new ADBSat cases:
% alpha = 0.8 and 0.4
% at AoA = -30 and +30 deg.
%
% Existing alpha = 1 results are read from the completed
% operational_pitch_sweep.csv and used as the comparison baseline.

if ~exist('cfg','var')
    project_config
end

cfg_run = cfg;
cfg_run.flags.verbose = 0;

%% Settings

model_name = cfg.model.name;
altitude_km = cfg.orbit.altitude_km;

aoa_values = [-30 30];
alpha_values = [0.8 0.4];

aos_deg = 0;

nAoA = numel(aoa_values);
nAlpha = numel(alpha_values);
nCase = nAoA * nAlpha;

%% Load model reference length

model_file = fullfile( ...
    cfg.paths.model_dir, ...
    [model_name '.mat']);

if ~isfile(model_file)
    error('Model file not found: %s', model_file);
end

S = load(model_file);
Lref_m = S.meshdata.Lref;

%% Load existing alpha = 1 operational results

baseline_csv = fullfile( ...
    cfg.paths.project_results_dir, ...
    'operational_pitch_sweep.csv');

if ~isfile(baseline_csv)
    error('Operational pitch sweep CSV not found: %s', baseline_csv);
end

baseline = readtable(baseline_csv);

%% Preallocate four new cases

AoA_deg = zeros(nCase,1);
AoS_deg = zeros(nCase,1);
Alpha = zeros(nCase,1);

AreaProj_m2 = zeros(nCase,1);
AreaRef_m2 = zeros(nCase,1);

CD_ADBSat = zeros(nCase,1);
CD_projected = zeros(nCase,1);

Drag_N = zeros(nCase,1);

CMy = zeros(nCase,1);
My_Nm = zeros(nCase,1);

%% Header

fprintf('\n');
fprintf('====================================================\n');
fprintf('FINAL v03 OFF-NOMINAL ACCOMMODATION SENSITIVITY\n');
fprintf('====================================================\n');

fprintf('Model:      %s\n', model_name);
fprintf('Altitude:   %.1f km\n', altitude_km);
fprintf('AoA cases:  -30 and +30 deg\n');
fprintf('AoS:        %.1f deg\n', aos_deg);
fprintf('GSIM:       Sentman\n');
fprintf('Shadow:     %d\n', cfg.flags.shadow);
fprintf('Solar:      %d\n', cfg.flags.solar);

fprintf('CoM [m]:    [%+.6f  %+.6f  %+.6f]\n\n', ...
    cfg.model.com_G_m(1), ...
    cfg.model.com_G_m(2), ...
    cfg.model.com_G_m(3));

fprintf('New accommodation cases: alpha = 0.8 and 0.4\n');
fprintf('Existing alpha = 1 pitch-sweep results used as baseline.\n\n');

%% Run four new cases

k = 0;

for i = 1:nAoA

    aoa = aoa_values(i);

    for j = 1:nAlpha

        k = k + 1;

        alpha = alpha_values(j);

        override = struct();
        override.alpha = alpha;

        fprintf( ...
            'Case %d of %d: AoA = %+5.1f deg, alpha = %.1f\n', ...
            k, ...
            nCase, ...
            aoa, ...
            alpha);

        out = run_adbsat_case( ...
            cfg_run, ...
            model_name, ...
            altitude_km, ...
            aoa, ...
            aos_deg, ...
            'sentman', ...
            override);

        q = ...
            0.5 * ...
            out.rho_kgm3 * ...
            out.vinf_ms^2;

        AoA_deg(k) = aoa;
        AoS_deg(k) = aos_deg;
        Alpha(k) = alpha;

        AreaProj_m2(k) = ...
            out.AreaProj_m2;

        AreaRef_m2(k) = ...
            out.AreaRef_m2;

        CD_ADBSat(k) = ...
            -out.Cf_w(1);

        CD_projected(k) = ...
            CD_ADBSat(k) * ...
            AreaRef_m2(k) / ...
            AreaProj_m2(k);

        Drag_N(k) = ...
            q * ...
            AreaRef_m2(k) * ...
            CD_ADBSat(k);

        CMy(k) = ...
            out.Cm_B(2);

        My_Nm(k) = ...
            q * ...
            AreaRef_m2(k) * ...
            Lref_m * ...
            CMy(k);

    end
end

%% New-case results table

results_offnominal = table( ...
    AoA_deg, ...
    AoS_deg, ...
    Alpha, ...
    AreaProj_m2, ...
    AreaRef_m2, ...
    CD_ADBSat, ...
    CD_projected, ...
    Drag_N, ...
    CMy, ...
    My_Nm);

fprintf('\n');
fprintf('====================================================\n');
fprintf('NEW OFF-NOMINAL ACCOMMODATION RESULTS\n');
fprintf('====================================================\n\n');

disp(results_offnominal);

%% Build comparison against existing alpha = 1 results

AoA_summary = [];
Alpha_summary = [];

Drag_summary = [];
DragChangeFromAlpha1_pct = [];

CMy_summary = [];
CMyDiffFromAlpha1 = [];

My_summary = [];
MyDiffFromAlpha1_Nm = [];

for i = 1:nAoA

    aoa = aoa_values(i);

    %% Find existing alpha = 1 baseline

    idx_base = ...
        baseline.AoA_deg == aoa;

    if sum(idx_base) ~= 1
        error( ...
            'Expected one existing pitch-sweep case at AoA %.1f deg.', ...
            aoa);
    end

    D_base = baseline.Drag_N(idx_base);

    % Allow either CMy_B or CMy column name
    if ismember('CMy_B', baseline.Properties.VariableNames)

        CMy_base = baseline.CMy_B(idx_base);

    elseif ismember('CMy', baseline.Properties.VariableNames)

        CMy_base = baseline.CMy(idx_base);

    else

        error('Could not find CMy_B or CMy in operational pitch CSV.');

    end

    My_base = baseline.My_Nm(idx_base);

    %% Add alpha = 1 baseline row

    AoA_summary(end+1,1) = aoa;
    Alpha_summary(end+1,1) = 1.0;

    Drag_summary(end+1,1) = D_base;
    DragChangeFromAlpha1_pct(end+1,1) = 0;

    CMy_summary(end+1,1) = CMy_base;
    CMyDiffFromAlpha1(end+1,1) = 0;

    My_summary(end+1,1) = My_base;
    MyDiffFromAlpha1_Nm(end+1,1) = 0;

    %% Add alpha = 0.8 and 0.4 rows

    for j = 1:nAlpha

        alpha = alpha_values(j);

        idx = ...
            (AoA_deg == aoa) & ...
            (Alpha == alpha);

        D = Drag_N(idx);
        C = CMy(idx);
        M = My_Nm(idx);

        AoA_summary(end+1,1) = aoa;
        Alpha_summary(end+1,1) = alpha;

        Drag_summary(end+1,1) = D;

        DragChangeFromAlpha1_pct(end+1,1) = ...
            100 * ...
            (D - D_base) / ...
            D_base;

        CMy_summary(end+1,1) = C;

        CMyDiffFromAlpha1(end+1,1) = ...
            C - CMy_base;

        My_summary(end+1,1) = M;

        MyDiffFromAlpha1_Nm(end+1,1) = ...
            M - My_base;

    end
end

comparison_offnominal = table( ...
    AoA_summary, ...
    Alpha_summary, ...
    Drag_summary, ...
    DragChangeFromAlpha1_pct, ...
    CMy_summary, ...
    CMyDiffFromAlpha1, ...
    My_summary, ...
    MyDiffFromAlpha1_Nm, ...
    'VariableNames', { ...
    'AoA_deg', ...
    'Alpha', ...
    'Drag_N', ...
    'DragChangeFromAlpha1_pct', ...
    'CMy', ...
    'CMyDiffFromAlpha1', ...
    'My_Nm', ...
    'MyDiffFromAlpha1_Nm'});

fprintf('\n');
fprintf('====================================================\n');
fprintf('OFF-NOMINAL ACCOMMODATION COMPARISON\n');
fprintf('====================================================\n\n');

disp(comparison_offnominal);

%% Summary

fprintf('\n');
fprintf('====================================================\n');
fprintf('OFF-NOMINAL ACCOMMODATION SUMMARY\n');
fprintf('====================================================\n');

for i = 1:nAoA

    aoa = aoa_values(i);

    fprintf('\nAoA = %+.0f deg\n', aoa);

    rows = ...
        comparison_offnominal.AoA_deg == aoa;

    T = comparison_offnominal(rows,:);

    for r = 1:height(T)

        fprintf( ...
            'alpha = %.1f: Drag = %.8e N, CMy = %+.8e, My = %+.8e N m\n', ...
            T.Alpha(r), ...
            T.Drag_N(r), ...
            T.CMy(r), ...
            T.My_Nm(r));

    end

end

fprintf('\nMaximum changes relative to alpha = 1:\n');

fprintf('Drag:       %.3f %%\n', ...
    max(abs( ...
    comparison_offnominal.DragChangeFromAlpha1_pct)));

fprintf('|Delta CMy|: %.8e\n', ...
    max(abs( ...
    comparison_offnominal.CMyDiffFromAlpha1)));

fprintf('|Delta My|:  %.8e N m\n', ...
    max(abs( ...
    comparison_offnominal.MyDiffFromAlpha1_Nm)));

%% Save

writetable( ...
    results_offnominal, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'accommodation_offnominal_results.csv'));

writetable( ...
    comparison_offnominal, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'accommodation_offnominal_comparison.csv'));

save( ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'accommodation_offnominal_summary.mat'), ...
    'results_offnominal', ...
    'comparison_offnominal', ...
    'cfg');

%% Plot

figure('Name','Final v03 Off-Nominal Accommodation Sensitivity');

tiledlayout(1,2);

nexttile;
hold on;
grid on;

for i = 1:nAoA

    rows = ...
        comparison_offnominal.AoA_deg == aoa_values(i);

    T = comparison_offnominal(rows,:);

    [alpha_plot, order] = sort(T.Alpha);

    plot( ...
        alpha_plot, ...
        T.Drag_N(order), ...
        '-o', ...
        'LineWidth',1.5, ...
        'DisplayName', ...
        sprintf('AoA %+.0f deg',aoa_values(i)));

end

xlabel('Sentman \alpha');
ylabel('Drag [N]');
title('Dimensional Drag');
legend('Location','best');

nexttile;
hold on;
grid on;

for i = 1:nAoA

    rows = ...
        comparison_offnominal.AoA_deg == aoa_values(i);

    T = comparison_offnominal(rows,:);

    [alpha_plot, order] = sort(T.Alpha);

    plot( ...
        alpha_plot, ...
        T.CMy(order), ...
        '-o', ...
        'LineWidth',1.5, ...
        'DisplayName', ...
        sprintf('AoA %+.0f deg',aoa_values(i)));

end

yline(0,'--');

xlabel('Sentman \alpha');
ylabel('C_{My}');
title('Pitching-Moment Coefficient');
legend('Location','best');

sgtitle( ...
    'disc\_lenticular\_v03 Off-Nominal Accommodation Sensitivity');

exportgraphics( ...
    gcf, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'accommodation_offnominal.png'), ...
    'Resolution',300);

fprintf('\nOff-nominal accommodation sensitivity complete.\n');
fprintf('Results saved in:\n%s\n', ...
    cfg.paths.project_results_dir);