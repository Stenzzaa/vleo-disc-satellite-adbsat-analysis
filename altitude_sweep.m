%% altitude_sweep.m
% Final altitude sensitivity study for disc_lenticular_v03.

if ~exist('cfg','var')
    project_config
end

cfg_run = cfg;
cfg_run.flags.verbose = 0;

%% Settings

model_name = cfg.model.name;

altitudes_km = cfg.test.altitude_km;

aoa_deg = cfg.attitude.aoa_deg;
aos_deg = cfg.attitude.aos_deg;

gsi_model = cfg.gsi.baseline_model;

nAlt = numel(altitudes_km);

%% Load model reference length

model_file = fullfile( ...
    cfg.paths.model_dir, ...
    [model_name '.mat']);

S = load(model_file);

Lref_m = S.meshdata.Lref;

%% Preallocate

Altitude_km = zeros(nAlt,1);

Density_kgm3 = zeros(nAlt,1);
Velocity_ms = zeros(nAlt,1);
SpeedRatio = zeros(nAlt,1);
DynamicPressure_Pa = zeros(nAlt,1);

AreaProj_m2 = zeros(nAlt,1);
AreaRef_m2 = zeros(nAlt,1);

CD_ADBSat = zeros(nAlt,1);
CD_projected = zeros(nAlt,1);
Drag_N = zeros(nAlt,1);

CMy = zeros(nAlt,1);
My_Nm = zeros(nAlt,1);

%% Header

fprintf('\n====================================================\n');
fprintf('FINAL v03 ALTITUDE SWEEP\n');
fprintf('====================================================\n');

fprintf('Model:      %s\n', model_name);
fprintf('Altitude:   %.0f to %.0f km\n', ...
    min(altitudes_km), max(altitudes_km));
fprintf('AoA:        %.1f deg\n', aoa_deg);
fprintf('AoS:        %.1f deg\n', aos_deg);
fprintf('GSIM:       %s\n', gsi_model);
fprintf('Shadow:     %d\n', cfg.flags.shadow);
fprintf('Solar:      %d\n', cfg.flags.solar);

fprintf('CoM [m]:    [%+.6f  %+.6f  %+.6f]\n\n', ...
    cfg.model.com_G_m(1), ...
    cfg.model.com_G_m(2), ...
    cfg.model.com_G_m(3));

%% Run cases

for i = 1:nAlt

    h = altitudes_km(i);

    fprintf('Case %d of %d: altitude = %.0f km\n', ...
        i, nAlt, h);

    out = run_adbsat_case( ...
        cfg_run, ...
        model_name, ...
        h, ...
        aoa_deg, ...
        aos_deg, ...
        gsi_model);

    Altitude_km(i) = h;

    Density_kgm3(i) = out.rho_kgm3;
    Velocity_ms(i) = out.vinf_ms;
    SpeedRatio(i) = out.speed_ratio;

    DynamicPressure_Pa(i) = ...
        0.5 * out.rho_kgm3 * out.vinf_ms^2;

    AreaProj_m2(i) = out.AreaProj_m2;
    AreaRef_m2(i) = out.AreaRef_m2;

    % Native ADBSat drag coefficient
    CD_ADBSat(i) = -out.Cf_w(1);

    % Projected-area-normalised drag coefficient
    CD_projected(i) = ...
        CD_ADBSat(i) * AreaRef_m2(i) / AreaProj_m2(i);

    % Dimensional drag
    Drag_N(i) = ...
        DynamicPressure_Pa(i) * ...
        AreaRef_m2(i) * ...
        CD_ADBSat(i);

    % Pitch moment about selected design CoM
    CMy(i) = out.Cm_B(2);

    My_Nm(i) = ...
        DynamicPressure_Pa(i) * ...
        AreaRef_m2(i) * ...
        Lref_m * ...
        CMy(i);

end

%% Results table

results_altitude = table( ...
    Altitude_km, ...
    Density_kgm3, ...
    Velocity_ms, ...
    SpeedRatio, ...
    DynamicPressure_Pa, ...
    AreaProj_m2, ...
    AreaRef_m2, ...
    CD_ADBSat, ...
    CD_projected, ...
    Drag_N, ...
    CMy, ...
    My_Nm);

fprintf('\n====================================================\n');
fprintf('ALTITUDE-SWEEP RESULTS\n');
fprintf('====================================================\n\n');

disp(results_altitude)

%% Summary

fprintf('\n====================================================\n');
fprintf('ALTITUDE-SWEEP SUMMARY\n');
fprintf('====================================================\n');

fprintf('Drag at %.0f km:  %.8e N\n', ...
    Altitude_km(1), Drag_N(1));

fprintf('Drag at 300 km: %.8e N\n', ...
    Drag_N(Altitude_km == 300));

fprintf('Drag at %.0f km:  %.8e N\n', ...
    Altitude_km(end), Drag_N(end));

fprintf('\n');

fprintf('Density ratio %.0f km / %.0f km: %.3f\n', ...
    Altitude_km(1), ...
    Altitude_km(end), ...
    Density_kgm3(1)/Density_kgm3(end));

fprintf('Drag ratio %.0f km / %.0f km:    %.3f\n', ...
    Altitude_km(1), ...
    Altitude_km(end), ...
    Drag_N(1)/Drag_N(end));

%% Save results

mat_file = fullfile( ...
    cfg.paths.project_results_dir, ...
    'altitude_sweep_summary.mat');

csv_file = fullfile( ...
    cfg.paths.project_results_dir, ...
    'altitude_sweep_summary.csv');

save(mat_file, ...
    'results_altitude', ...
    'cfg');

writetable(results_altitude, csv_file);

%% Plot

figure('Name','Final v03 Altitude Sensitivity');

tiledlayout(2,2);

nexttile

semilogy(Altitude_km, Density_kgm3, '-o', ...
    'LineWidth',1.5);

grid on
xlabel('Altitude [km]')
ylabel('Density [kg m^{-3}]')
title('Atmospheric Density')

nexttile

plot(Altitude_km, CD_ADBSat, '-o', ...
    'LineWidth',1.5);

grid on
xlabel('Altitude [km]')
ylabel('C_D')
title('ADBSat C_D')

nexttile

semilogy(Altitude_km, Drag_N, '-o', ...
    'LineWidth',1.5);

grid on
xlabel('Altitude [km]')
ylabel('Drag [N]')
title('Dimensional Drag')

nexttile

semilogy(Altitude_km, abs(My_Nm), '-o', ...
    'LineWidth',1.5);

grid on
xlabel('Altitude [km]')
ylabel('|M_y| [N m]')
title('Pitching-Moment Magnitude')

sgtitle('disc\_lenticular\_v03 Altitude Sensitivity');

fig_file = fullfile( ...
    cfg.paths.project_results_dir, ...
    'altitude_sweep.png');

exportgraphics(gcf, fig_file, 'Resolution',300);

fprintf('\nAltitude sweep complete.\n');
fprintf('Results saved in:\n%s\n', ...
    cfg.paths.project_results_dir);