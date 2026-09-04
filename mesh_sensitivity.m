%% mesh_sensitivity.m
% Final mesh-convergence study for disc_lenticular_v03.
% Compares coarse, medium and fine meshes at -30, 0 and +30 deg AoA.
% Uses the selected nominal design CoM [+0.006; 0; 0] m.

%% Load project configuration

if ~exist('cfg', 'var')
    project_config
end

cfg_run = cfg;

% Final convergence-study settings
cfg_run.model.com_G_m = cfg.model.com_design_G_m;
cfg_run.flags.shadow = 1;
cfg_run.flags.solar = 0;
cfg_run.flags.verbose = 0;


%% Analysis settings

model_names = cfg.mesh.model_names;
mesh_labels = cfg.mesh.labels;
test_cases = cfg.mesh.test_cases_deg;

altitude_km = cfg.orbit.altitude_km;
gsi_model = cfg.gsi.baseline_model;

nMeshes = numel(model_names);
nCases = size(test_cases,1);

if numel(mesh_labels) ~= nMeshes
    error('Number of mesh labels must match number of mesh models.');
end

if nMeshes ~= 3
    error('Final mesh convergence requires exactly three meshes: coarse, medium and fine.');
end

if ~strcmpi(gsi_model, 'sentman')
    error('Final mesh convergence is defined using the Sentman baseline GSIM.');
end

if altitude_km ~= 300
    warning('Mesh convergence baseline altitude is expected to be 300 km. Current value: %.1f km.', altitude_km);
end


%% Preallocate geometry information

Panels = zeros(nMeshes,1);
SurfaceArea_m2 = zeros(nMeshes,1);
LenRef_m = zeros(nMeshes,1);
MaterialID = zeros(nMeshes,1);


%% Inspect meshes

fprintf('\n====================================================\n');
fprintf('FINAL v03 MESH GEOMETRY CHECK\n');
fprintf('====================================================\n');

for m = 1:nMeshes

    model_file = fullfile( ...
        cfg.paths.model_dir, ...
        [model_names{m} '.mat']);

    if ~isfile(model_file)
        error('Mesh model not found: %s', model_file);
    end

    M = load(model_file);

    if ~isfield(M, 'meshdata')
        error('meshdata structure missing from %s.', model_file);
    end

    Panels(m) = numel(M.meshdata.Areas);
    SurfaceArea_m2(m) = sum(M.meshdata.Areas);
    LenRef_m(m) = M.meshdata.Lref;

    ids = unique(M.meshdata.MatID(:));

    if numel(ids) ~= 1
        error('%s contains more than one material ID.', model_names{m});
    end

    MaterialID(m) = ids;

    if MaterialID(m) ~= 1
        error(['%s has MatID = %g. Apply the established post-import ' ...
               'S.meshdata.MatID(:)=1 correction before convergence.'], ...
               model_names{m}, MaterialID(m));
    end

end


%% Display geometry table

SurfaceArea_ErrorFine_pct = ...
    100 * abs(SurfaceArea_m2 - SurfaceArea_m2(end)) ./ SurfaceArea_m2(end);

LenRef_ErrorFine_pct = ...
    100 * abs(LenRef_m - LenRef_m(end)) ./ LenRef_m(end);

mesh_geometry = table( ...
    string(mesh_labels(:)), ...
    string(model_names(:)), ...
    Panels, ...
    SurfaceArea_m2, ...
    SurfaceArea_ErrorFine_pct, ...
    LenRef_m, ...
    LenRef_ErrorFine_pct, ...
    MaterialID, ...
    'VariableNames', { ...
    'Mesh', ...
    'Model', ...
    'Panels', ...
    'SurfaceArea_m2', ...
    'SurfaceArea_ErrorFine_pct', ...
    'LenRef_m', ...
    'LenRef_ErrorFine_pct', ...
    'MaterialID'});

disp(mesh_geometry)

if any(diff(Panels) <= 0)
    error('Meshes must be ordered coarse -> medium -> fine by panel count.');
end


%% Preallocate aerodynamic results

nRows = nMeshes * nCases;

Mesh = strings(nRows,1);
Model = strings(nRows,1);
PanelCount = zeros(nRows,1);

AoA_deg = zeros(nRows,1);
AoS_deg = zeros(nRows,1);

DynamicPressure_Pa = zeros(nRows,1);
AreaProj_m2 = zeros(nRows,1);
AreaRef_m2 = zeros(nRows,1);
LenRef_case_m = zeros(nRows,1);

CD_ADBSat = zeros(nRows,1);
CD_projected = zeros(nRows,1);
Drag_N = zeros(nRows,1);

CMy = zeros(nRows,1);
My_Nm = zeros(nRows,1);

row = 0;


%% Run mesh cases

fprintf('\n====================================================\n');
fprintf('FINAL v03 ADBSat MESH-CONVERGENCE STUDY\n');
fprintf('====================================================\n');
fprintf('Altitude: %.1f km\n', altitude_km);
fprintf('GSIM:     %s\n', gsi_model);
fprintf('Shadow:   %d\n', cfg_run.flags.shadow);
fprintf('Solar:    %d\n', cfg_run.flags.solar);
fprintf('CoM [m]:  [%+.6f  %+.6f  %+.6f]\n', ...
    cfg_run.model.com_G_m(1), ...
    cfg_run.model.com_G_m(2), ...
    cfg_run.model.com_G_m(3));

for c = 1:nCases

    aoa = test_cases(c,1);
    aos = test_cases(c,2);

    fprintf('\nAoA = %+.2f deg, AoS = %.2f deg\n', aoa, aos);

    for m = 1:nMeshes

        row = row + 1;

        fprintf('  Running %-6s mesh (%d panels)...\n', ...
            mesh_labels{m}, Panels(m));

        out = run_adbsat_case( ...
            cfg_run, ...
            model_names{m}, ...
            altitude_km, ...
            aoa, ...
            aos, ...
            gsi_model);

        q = 0.5 * out.rho_kgm3 * out.vinf_ms^2;
        cd_adbsat = -out.Cf_w(1);

        if ~isfinite(out.AreaProj_m2) || out.AreaProj_m2 <= 0
            error('Invalid projected area returned for %s at AoA %.2f deg.', ...
                model_names{m}, aoa);
        end

        cd_projected = ...
            cd_adbsat * out.AreaRef_m2 / out.AreaProj_m2;

        drag_N = ...
            q * out.AreaRef_m2 * cd_adbsat;

        cmy = out.Cm_B(2);

        my_Nm = ...
            q * out.AreaRef_m2 * LenRef_m(m) * cmy;

        Mesh(row) = string(mesh_labels{m});
        Model(row) = string(model_names{m});
        PanelCount(row) = Panels(m);

        AoA_deg(row) = aoa;
        AoS_deg(row) = aos;

        DynamicPressure_Pa(row) = q;
        AreaProj_m2(row) = out.AreaProj_m2;
        AreaRef_m2(row) = out.AreaRef_m2;
        LenRef_case_m(row) = LenRef_m(m);

        CD_ADBSat(row) = cd_adbsat;
        CD_projected(row) = cd_projected;
        Drag_N(row) = drag_N;

        CMy(row) = cmy;
        My_Nm(row) = my_Nm;

    end
end


%% Raw results table

results_mesh = table( ...
    Mesh, ...
    Model, ...
    PanelCount, ...
    AoA_deg, ...
    AoS_deg, ...
    DynamicPressure_Pa, ...
    AreaProj_m2, ...
    AreaRef_m2, ...
    LenRef_case_m, ...
    CD_ADBSat, ...
    CD_projected, ...
    Drag_N, ...
    CMy, ...
    My_Nm);


%% Differences relative to fine mesh

AreaProj_ErrorFine_pct = zeros(nRows,1);
CD_ADBSat_ErrorFine_pct = zeros(nRows,1);
CD_projected_ErrorFine_pct = zeros(nRows,1);
Drag_ErrorFine_pct = zeros(nRows,1);

CMy_DiffFine = zeros(nRows,1);
CMy_AbsDiffFine = zeros(nRows,1);
CMy_ErrorFine_pct = zeros(nRows,1);

My_DiffFine_Nm = zeros(nRows,1);
My_AbsDiffFine_Nm = zeros(nRows,1);
My_ErrorFine_pct = zeros(nRows,1);

for c = 1:nCases

    idx = find( ...
        AoA_deg == test_cases(c,1) & ...
        AoS_deg == test_cases(c,2));

    if numel(idx) ~= nMeshes
        error('Unexpected number of mesh results for convergence case %d.', c);
    end

    fine_idx = idx(end);

    for k = 1:numel(idx)

        r = idx(k);

        AreaProj_ErrorFine_pct(r) = ...
            100 * abs(AreaProj_m2(r) - AreaProj_m2(fine_idx)) / ...
            abs(AreaProj_m2(fine_idx));

        CD_ADBSat_ErrorFine_pct(r) = ...
            100 * abs(CD_ADBSat(r) - CD_ADBSat(fine_idx)) / ...
            abs(CD_ADBSat(fine_idx));

        CD_projected_ErrorFine_pct(r) = ...
            100 * abs(CD_projected(r) - CD_projected(fine_idx)) / ...
            abs(CD_projected(fine_idx));

        Drag_ErrorFine_pct(r) = ...
            100 * abs(Drag_N(r) - Drag_N(fine_idx)) / ...
            abs(Drag_N(fine_idx));

        CMy_DiffFine(r) = CMy(r) - CMy(fine_idx);
        CMy_AbsDiffFine(r) = abs(CMy_DiffFine(r));

        if abs(CMy(fine_idx)) > 1e-12
            CMy_ErrorFine_pct(r) = ...
                100 * CMy_AbsDiffFine(r) / abs(CMy(fine_idx));
        else
            CMy_ErrorFine_pct(r) = NaN;
        end

        My_DiffFine_Nm(r) = My_Nm(r) - My_Nm(fine_idx);
        My_AbsDiffFine_Nm(r) = abs(My_DiffFine_Nm(r));

        if abs(My_Nm(fine_idx)) > 1e-15
            My_ErrorFine_pct(r) = ...
                100 * My_AbsDiffFine_Nm(r) / abs(My_Nm(fine_idx));
        else
            My_ErrorFine_pct(r) = NaN;
        end

    end
end

results_mesh.AreaProj_ErrorFine_pct = AreaProj_ErrorFine_pct;
results_mesh.CD_ADBSat_ErrorFine_pct = CD_ADBSat_ErrorFine_pct;
results_mesh.CD_projected_ErrorFine_pct = CD_projected_ErrorFine_pct;
results_mesh.Drag_ErrorFine_pct = Drag_ErrorFine_pct;

results_mesh.CMy_DiffFine = CMy_DiffFine;
results_mesh.CMy_AbsDiffFine = CMy_AbsDiffFine;
results_mesh.CMy_ErrorFine_pct = CMy_ErrorFine_pct;

results_mesh.My_DiffFine_Nm = My_DiffFine_Nm;
results_mesh.My_AbsDiffFine_Nm = My_AbsDiffFine_Nm;
results_mesh.My_ErrorFine_pct = My_ErrorFine_pct;


%% Display complete results

fprintf('\n====================================================\n');
fprintf('MESH-CONVERGENCE RESULTS\n');
fprintf('====================================================\n\n');

disp(results_mesh)


%% Medium-to-fine convergence summary

CaseName = strings(nCases,1);
Summary_AoA_deg = test_cases(:,1);
Summary_AoS_deg = test_cases(:,2);

AreaProj_MediumFine_pct = zeros(nCases,1);
CD_ADBSat_MediumFine_pct = zeros(nCases,1);
CD_projected_MediumFine_pct = zeros(nCases,1);
Drag_MediumFine_pct = zeros(nCases,1);

CMy_Medium = zeros(nCases,1);
CMy_Fine = zeros(nCases,1);
CMy_MediumFine_abs = zeros(nCases,1);
CMy_MediumFine_pct = zeros(nCases,1);

My_Medium_Nm = zeros(nCases,1);
My_Fine_Nm = zeros(nCases,1);
My_MediumFine_abs_Nm = zeros(nCases,1);
My_MediumFine_pct = zeros(nCases,1);

for c = 1:nCases

    idx = find( ...
        AoA_deg == test_cases(c,1) & ...
        AoS_deg == test_cases(c,2));

    medium_idx = idx(end-1);
    fine_idx = idx(end);

    CaseName(c) = sprintf( ...
        'AoA %+.1f deg, AoS %.1f deg', ...
        test_cases(c,1), ...
        test_cases(c,2));

    AreaProj_MediumFine_pct(c) = ...
        100 * abs(AreaProj_m2(medium_idx) - AreaProj_m2(fine_idx)) / ...
        abs(AreaProj_m2(fine_idx));

    CD_ADBSat_MediumFine_pct(c) = ...
        100 * abs(CD_ADBSat(medium_idx) - CD_ADBSat(fine_idx)) / ...
        abs(CD_ADBSat(fine_idx));

    CD_projected_MediumFine_pct(c) = ...
        100 * abs(CD_projected(medium_idx) - CD_projected(fine_idx)) / ...
        abs(CD_projected(fine_idx));

    Drag_MediumFine_pct(c) = ...
        100 * abs(Drag_N(medium_idx) - Drag_N(fine_idx)) / ...
        abs(Drag_N(fine_idx));

    CMy_Medium(c) = CMy(medium_idx);
    CMy_Fine(c) = CMy(fine_idx);
    CMy_MediumFine_abs(c) = abs(CMy(medium_idx) - CMy(fine_idx));

    if abs(CMy(fine_idx)) > 1e-12
        CMy_MediumFine_pct(c) = ...
            100 * CMy_MediumFine_abs(c) / abs(CMy(fine_idx));
    else
        CMy_MediumFine_pct(c) = NaN;
    end

    My_Medium_Nm(c) = My_Nm(medium_idx);
    My_Fine_Nm(c) = My_Nm(fine_idx);
    My_MediumFine_abs_Nm(c) = abs(My_Nm(medium_idx) - My_Nm(fine_idx));

    if abs(My_Nm(fine_idx)) > 1e-15
        My_MediumFine_pct(c) = ...
            100 * My_MediumFine_abs_Nm(c) / abs(My_Nm(fine_idx));
    else
        My_MediumFine_pct(c) = NaN;
    end

end

convergence_summary = table( ...
    CaseName, ...
    Summary_AoA_deg, ...
    Summary_AoS_deg, ...
    AreaProj_MediumFine_pct, ...
    CD_ADBSat_MediumFine_pct, ...
    CD_projected_MediumFine_pct, ...
    Drag_MediumFine_pct, ...
    CMy_Medium, ...
    CMy_Fine, ...
    CMy_MediumFine_abs, ...
    CMy_MediumFine_pct, ...
    My_Medium_Nm, ...
    My_Fine_Nm, ...
    My_MediumFine_abs_Nm, ...
    My_MediumFine_pct);

fprintf('\n====================================================\n');
fprintf('MEDIUM-TO-FINE CONVERGENCE SUMMARY\n');
fprintf('====================================================\n\n');

disp(convergence_summary)

fprintf('\nMaximum medium-to-fine differences across the three attitudes:\n');
fprintf('Projected area:        %.6f %%\n', max(AreaProj_MediumFine_pct));
fprintf('ADBSat CD:             %.6f %%\n', max(CD_ADBSat_MediumFine_pct));
fprintf('Projected-area CD:     %.6f %%\n', max(CD_projected_MediumFine_pct));
fprintf('Dimensional drag:      %.6f %%\n', max(Drag_MediumFine_pct));
fprintf('|Delta CMy|:           %.8e\n', max(CMy_MediumFine_abs));
fprintf('|Delta My|:            %.8e N m\n', max(My_MediumFine_abs_Nm));
fprintf('\nNo numerical pass/fail threshold is imposed; convergence is assessed from the trend and medium-to-fine differences.\n');


%% Save numerical results

save( ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'mesh_sensitivity_summary.mat'), ...
    'mesh_geometry', ...
    'results_mesh', ...
    'convergence_summary', ...
    'cfg_run');

writetable( ...
    mesh_geometry, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'mesh_geometry.csv'));

writetable( ...
    results_mesh, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'mesh_sensitivity_results.csv'));

writetable( ...
    convergence_summary, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'mesh_convergence_medium_to_fine.csv'));


%% Convergence plots

figure('Name', 'Final v03 Mesh Convergence');
tiledlayout(2,3);

plot_metric(PanelCount, AoA_deg, AoS_deg, test_cases, ...
    AreaProj_m2, 'Projected area [m^2]', 'Projected Area');

plot_metric(PanelCount, AoA_deg, AoS_deg, test_cases, ...
    CD_ADBSat, 'C_D (ADBSat reference area)', 'ADBSat C_D');

plot_metric(PanelCount, AoA_deg, AoS_deg, test_cases, ...
    CD_projected, 'C_D (projected area)', 'Projected-Area C_D');

plot_metric(PanelCount, AoA_deg, AoS_deg, test_cases, ...
    Drag_N, 'Drag [N]', 'Dimensional Drag');

plot_metric(PanelCount, AoA_deg, AoS_deg, test_cases, ...
    CMy, 'C_{My}', 'Pitching-Moment Coefficient');

plot_metric(PanelCount, AoA_deg, AoS_deg, test_cases, ...
    My_Nm, 'M_y [N m]', 'Dimensional Pitching Moment');

sgtitle('disc\_lenticular\_v03 Mesh Convergence');

savefig( ...
    gcf, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'mesh_convergence_plots.fig'));

exportgraphics( ...
    gcf, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'mesh_convergence_plots.png'), ...
    'Resolution', 300);

fprintf('\nMesh-convergence analysis complete.\n');
fprintf('Results saved in:\n%s\n', cfg.paths.project_results_dir);


%% Local plotting function

function plot_metric(PanelCount, AoA_deg, AoS_deg, test_cases, y, yLabelText, titleText)

nexttile
hold on

for c = 1:size(test_cases,1)

    idx = find( ...
        AoA_deg == test_cases(c,1) & ...
        AoS_deg == test_cases(c,2));

    plot( ...
        PanelCount(idx), ...
        y(idx), ...
        '-o', ...
        'LineWidth', 1.3, ...
        'DisplayName', sprintf('AoA %+.0f deg', test_cases(c,1)));

end

grid on
xlabel('Number of panels')
ylabel(yLabelText)
title(titleText)
legend('Location','best')
hold off

end
