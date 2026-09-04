%% accommodation_sensitivity.m
% Final accommodation-parameter sensitivity study for
% disc_lenticular_v03.
%
% IMPORTANT:
% The parameter values used here are generic sensitivity cases.
% They are NOT experimentally measured accommodation properties
% for Al2O3-coated POSS-polyimide or any specific spacecraft material.

if ~exist('cfg','var')
    project_config
end

cfg_run = cfg;
cfg_run.flags.verbose = 0;


%% Settings

model_name = cfg.model.name;

altitude_km = cfg.orbit.altitude_km;

aoa_deg = 0;
aos_deg = 0;

sentman_alpha = cfg.test.sentman_alpha(:);

cll_alphaN = cfg.test.cll_alphaN(:);
cll_sigmaT = cfg.test.cll_sigmaT(:);

nSentman = numel(sentman_alpha);

nCLL = ...
    numel(cll_alphaN) * ...
    numel(cll_sigmaT);

nCase = nSentman + nCLL;


%% Load model reference length

model_file = fullfile( ...
    cfg.paths.model_dir, ...
    [model_name '.mat']);

S = load(model_file);

Lref_m = S.meshdata.Lref;


%% Preallocate

GSIM = strings(nCase,1);
CaseLabel = strings(nCase,1);

Alpha = NaN(nCase,1);
AlphaN = NaN(nCase,1);
SigmaT = NaN(nCase,1);

AreaProj_m2 = zeros(nCase,1);
AreaRef_m2 = zeros(nCase,1);

CD_ADBSat = zeros(nCase,1);
CD_projected = zeros(nCase,1);

Drag_N = zeros(nCase,1);

CMy = zeros(nCase,1);
My_Nm = zeros(nCase,1);


%% Header

fprintf('\n====================================================\n');
fprintf('FINAL v03 ACCOMMODATION SENSITIVITY\n');
fprintf('====================================================\n');

fprintf('Model:      %s\n', model_name);
fprintf('Altitude:   %.1f km\n', altitude_km);
fprintf('AoA:        %.1f deg\n', aoa_deg);
fprintf('AoS:        %.1f deg\n', aos_deg);

fprintf('Shadow:     %d\n', cfg.flags.shadow);
fprintf('Solar:      %d\n', cfg.flags.solar);

fprintf('Wall T:     %.1f K\n', ...
    cfg.gsi.wall_temperature_K);

fprintf('CoM [m]:    [%+.6f  %+.6f  %+.6f]\n\n', ...
    cfg.model.com_G_m(1), ...
    cfg.model.com_G_m(2), ...
    cfg.model.com_G_m(3));

fprintf('Sentman alpha cases:\n');
disp(sentman_alpha.');

fprintf('CLL alphaN cases:\n');
disp(cll_alphaN.');

fprintf('CLL sigmaT cases:\n');
disp(cll_sigmaT.');

fprintf(['\nNOTE: These are generic parameter-sensitivity cases, ' ...
    'not measured material properties.\n\n']);


%% Run Sentman cases

k = 0;

for i = 1:nSentman

    k = k + 1;

    alpha = sentman_alpha(i);

    override = struct();
    override.alpha = alpha;

    fprintf( ...
        'Case %d of %d: Sentman alpha = %.2f\n', ...
        k, nCase, alpha);

    out = run_adbsat_case( ...
        cfg_run, ...
        model_name, ...
        altitude_km, ...
        aoa_deg, ...
        aos_deg, ...
        'sentman', ...
        override);

    q = ...
        0.5 * ...
        out.rho_kgm3 * ...
        out.vinf_ms^2;

    GSIM(k) = "Sentman";

    CaseLabel(k) = sprintf( ...
        'Sentman alpha=%.2f', ...
        alpha);

    Alpha(k) = alpha;

    AreaProj_m2(k) = out.AreaProj_m2;
    AreaRef_m2(k) = out.AreaRef_m2;

    CD_ADBSat(k) = -out.Cf_w(1);

    CD_projected(k) = ...
        CD_ADBSat(k) * ...
        AreaRef_m2(k) / ...
        AreaProj_m2(k);

    Drag_N(k) = ...
        q * ...
        AreaRef_m2(k) * ...
        CD_ADBSat(k);

    CMy(k) = out.Cm_B(2);

    My_Nm(k) = ...
        q * ...
        AreaRef_m2(k) * ...
        Lref_m * ...
        CMy(k);

end


%% Run CLL cases

for i = 1:numel(cll_alphaN)

    for j = 1:numel(cll_sigmaT)

        k = k + 1;

        alphaN = cll_alphaN(i);
        sigmaT = cll_sigmaT(j);

        override = struct();

        override.alphaN = alphaN;
        override.sigmaT = sigmaT;

        fprintf( ...
            ['Case %d of %d: CLL alphaN = %.2f, ' ...
             'sigmaT = %.2f\n'], ...
            k, nCase, alphaN, sigmaT);

        out = run_adbsat_case( ...
            cfg_run, ...
            model_name, ...
            altitude_km, ...
            aoa_deg, ...
            aos_deg, ...
            'CLL', ...
            override);

        q = ...
            0.5 * ...
            out.rho_kgm3 * ...
            out.vinf_ms^2;

        GSIM(k) = "CLL";

        CaseLabel(k) = sprintf( ...
            'CLL alphaN=%.2f sigmaT=%.2f', ...
            alphaN, sigmaT);

        AlphaN(k) = alphaN;
        SigmaT(k) = sigmaT;

        AreaProj_m2(k) = out.AreaProj_m2;
        AreaRef_m2(k) = out.AreaRef_m2;

        CD_ADBSat(k) = -out.Cf_w(1);

        CD_projected(k) = ...
            CD_ADBSat(k) * ...
            AreaRef_m2(k) / ...
            AreaProj_m2(k);

        Drag_N(k) = ...
            q * ...
            AreaRef_m2(k) * ...
            CD_ADBSat(k);

        CMy(k) = out.Cm_B(2);

        My_Nm(k) = ...
            q * ...
            AreaRef_m2(k) * ...
            Lref_m * ...
            CMy(k);

    end
end


%% Full results table

results_accommodation = table( ...
    GSIM, ...
    CaseLabel, ...
    Alpha, ...
    AlphaN, ...
    SigmaT, ...
    AreaProj_m2, ...
    AreaRef_m2, ...
    CD_ADBSat, ...
    CD_projected, ...
    Drag_N, ...
    CMy, ...
    My_Nm);


fprintf('\n====================================================\n');
fprintf('ACCOMMODATION-SENSITIVITY RESULTS\n');
fprintf('====================================================\n\n');

disp(results_accommodation)


%% Sentman baseline-relative comparison

idxS = GSIM == "Sentman";

alpha_S = Alpha(idxS);

CD_S = CD_ADBSat(idxS);
CDproj_S = CD_projected(idxS);

Drag_S = Drag_N(idxS);

CMy_S = CMy(idxS);
My_S = My_Nm(idxS);


% Fully accommodating Sentman reference
idxSbase = alpha_S == 1.0;

if sum(idxSbase) ~= 1
    error('Exactly one Sentman alpha = 1 baseline is required.');
end

Drag_S_base = Drag_S(idxSbase);
CMy_S_base = CMy_S(idxSbase);
My_S_base = My_S(idxSbase);


DragChange_S_pct = ...
    100 * ...
    (Drag_S - Drag_S_base) / ...
    Drag_S_base;

CMyDiff_S = ...
    CMy_S - CMy_S_base;

MyDiff_S_Nm = ...
    My_S - My_S_base;


summary_sentman = table( ...
    alpha_S, ...
    CD_S, ...
    CDproj_S, ...
    Drag_S, ...
    DragChange_S_pct, ...
    CMy_S, ...
    CMyDiff_S, ...
    My_S, ...
    MyDiff_S_Nm, ...
    'VariableNames', { ...
    'Alpha', ...
    'CD_ADBSat', ...
    'CD_projected', ...
    'Drag_N', ...
    'DragChangeFromAlpha1_pct', ...
    'CMy', ...
    'CMyDiffFromAlpha1', ...
    'My_Nm', ...
    'MyDiffFromAlpha1_Nm'});


%% CLL baseline-relative comparison

idxC = GSIM == "CLL";

alphaN_C = AlphaN(idxC);
sigmaT_C = SigmaT(idxC);

CD_C = CD_ADBSat(idxC);
CDproj_C = CD_projected(idxC);

Drag_C = Drag_N(idxC);

CMy_C = CMy(idxC);
My_C = My_Nm(idxC);


% CLL alphaN = 1, sigmaT = 1 reference
idxCbase = ...
    alphaN_C == 1.0 & ...
    sigmaT_C == 1.0;

if sum(idxCbase) ~= 1
    error(['Exactly one CLL alphaN = 1, sigmaT = 1 ' ...
        'baseline is required.']);
end

Drag_C_base = Drag_C(idxCbase);
CMy_C_base = CMy_C(idxCbase);
My_C_base = My_C(idxCbase);


DragChange_C_pct = ...
    100 * ...
    (Drag_C - Drag_C_base) / ...
    Drag_C_base;

CMyDiff_C = ...
    CMy_C - CMy_C_base;

MyDiff_C_Nm = ...
    My_C - My_C_base;


summary_cll = table( ...
    alphaN_C, ...
    sigmaT_C, ...
    CD_C, ...
    CDproj_C, ...
    Drag_C, ...
    DragChange_C_pct, ...
    CMy_C, ...
    CMyDiff_C, ...
    My_C, ...
    MyDiff_C_Nm, ...
    'VariableNames', { ...
    'AlphaN', ...
    'SigmaT', ...
    'CD_ADBSat', ...
    'CD_projected', ...
    'Drag_N', ...
    'DragChangeFromCLL11_pct', ...
    'CMy', ...
    'CMyDiffFromCLL11', ...
    'My_Nm', ...
    'MyDiffFromCLL11_Nm'});


%% Display summaries

fprintf('\n====================================================\n');
fprintf('SENTMAN ACCOMMODATION SUMMARY\n');
fprintf('Reference: alpha = 1.0\n');
fprintf('====================================================\n\n');

disp(summary_sentman)


fprintf('\n====================================================\n');
fprintf('CLL ACCOMMODATION SUMMARY\n');
fprintf('Reference: alphaN = 1.0, sigmaT = 1.0\n');
fprintf('====================================================\n\n');

disp(summary_cll)


%% Overall sensitivity summary

fprintf('\n====================================================\n');
fprintf('ACCOMMODATION-SENSITIVITY SUMMARY\n');
fprintf('====================================================\n');

fprintf('\nSentman:\n');

fprintf('Maximum |drag change| from alpha=1: %.3f %%\n', ...
    max(abs(DragChange_S_pct)));

fprintf('Maximum |Delta CMy| from alpha=1: %.8e\n', ...
    max(abs(CMyDiff_S)));

fprintf('Maximum |Delta My| from alpha=1: %.8e N m\n', ...
    max(abs(MyDiff_S_Nm)));


fprintf('\nCLL:\n');

fprintf('Maximum |drag change| from (1,1): %.3f %%\n', ...
    max(abs(DragChange_C_pct)));

fprintf('Maximum |Delta CMy| from (1,1): %.8e\n', ...
    max(abs(CMyDiff_C)));

fprintf('Maximum |Delta My| from (1,1): %.8e N m\n', ...
    max(abs(MyDiff_C_Nm)));

fprintf(['\nParameter changes are sensitivity assumptions only; ' ...
    'they are not assigned to a specific coating/material.\n']);


%% Save tables

writetable( ...
    results_accommodation, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'accommodation_sensitivity_results.csv'));

writetable( ...
    summary_sentman, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'accommodation_sensitivity_sentman.csv'));

writetable( ...
    summary_cll, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'accommodation_sensitivity_cll.csv'));


%% Save MAT file

save( ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'accommodation_sensitivity_summary.mat'), ...
    'results_accommodation', ...
    'summary_sentman', ...
    'summary_cll', ...
    'cfg');


%% Plot

figure('Name','Final v03 Accommodation Sensitivity');

tiledlayout(2,2);


% Sentman drag
nexttile

plot( ...
    alpha_S, ...
    Drag_S, ...
    '-o', ...
    'LineWidth',1.5);

grid on

xlabel('Sentman \alpha');
ylabel('Drag [N]');
title('Sentman: Dimensional Drag');


% Sentman CMy
nexttile

plot( ...
    alpha_S, ...
    CMy_S, ...
    '-o', ...
    'LineWidth',1.5);

grid on

xlabel('Sentman \alpha');
ylabel('C_{My}');
title('Sentman: Pitching Moment');


% CLL drag
nexttile

hold on
grid on

for j = 1:numel(cll_sigmaT)

    sigma_value = cll_sigmaT(j);

    mask = ...
        sigmaT_C == sigma_value;

    plot( ...
        alphaN_C(mask), ...
        Drag_C(mask), ...
        '-o', ...
        'LineWidth',1.5, ...
        'DisplayName', ...
        sprintf('\\sigma_T = %.1f',sigma_value));

end

xlabel('CLL \alpha_N');
ylabel('Drag [N]');
title('CLL: Dimensional Drag');

legend('Location','best');


% CLL CMy
nexttile

hold on
grid on

for j = 1:numel(cll_sigmaT)

    sigma_value = cll_sigmaT(j);

    mask = ...
        sigmaT_C == sigma_value;

    plot( ...
        alphaN_C(mask), ...
        CMy_C(mask), ...
        '-o', ...
        'LineWidth',1.5, ...
        'DisplayName', ...
        sprintf('\\sigma_T = %.1f',sigma_value));

end

xlabel('CLL \alpha_N');
ylabel('C_{My}');
title('CLL: Pitching Moment');

legend('Location','best');


sgtitle( ...
    'disc\_lenticular\_v03 Accommodation Sensitivity');


%% Export figure

exportgraphics( ...
    gcf, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'accommodation_sensitivity.png'), ...
    'Resolution',300);


fprintf('\nAccommodation sensitivity complete.\n');
fprintf('Results saved in:\n%s\n', ...
    cfg.paths.project_results_dir);