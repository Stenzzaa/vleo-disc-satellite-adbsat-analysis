%% Load project configuration

if ~exist('cfg', 'var')
    project_config
end

%% Analysis settings

altitudes_km = cfg.test.altitude_km;

L_char = cfg.fmf.characteristic_length_m;
d_eff = cfg.fmf.collision_diameter_m;

nAlt = numel(altitudes_km);


%% Physical constants

R_u = 8.31446261815324;       % Universal gas constant [J/(mol K)]
N_A = 6.02214076e23;          % Avogadro constant [1/mol]


%% Preallocate results

Altitude_km = zeros(nAlt,1);

Density_kgm3 = zeros(nAlt,1);
Temperature_K = zeros(nAlt,1);
Rmean_JkgK = zeros(nAlt,1);

MolarMass_kgmol = zeros(nAlt,1);
NumberDensity_m3 = zeros(nAlt,1);

MeanFreePath_m = zeros(nAlt,1);
CharacteristicLength_m = L_char * ones(nAlt,1);

Knudsen = zeros(nAlt,1);
FlowRegime = strings(nAlt,1);


%% Calculate Knudsen number

fprintf('\n========================================\n');
fprintf('FREE-MOLECULAR-FLOW VERIFICATION\n');
fprintf('========================================\n\n');

fprintf('Characteristic length: %.4f m\n', L_char);
fprintf('Collision diameter:     %.4e m\n\n', d_eff);

for i = 1:nAlt

    h = altitudes_km(i);

    %% Obtain NRLMSISE-00 atmospheric state

    [param_eq, ~] = build_freestream(cfg, h);


    %% Atmospheric properties

    rho = param_eq.rho(6);
    T = param_eq.Tinf;
    Rmean = param_eq.Rmean;


    %% Mean molar mass

    M = R_u / Rmean;


    %% Mean molecular mass

    molecular_mass = M / N_A;


    %% Total number density

    number_density = rho / molecular_mass;


    %% Hard-sphere mean free path

    lambda = 1 / ( ...
        sqrt(2) * pi * d_eff^2 * number_density);


    %% Knudsen number

    Kn = lambda / L_char;


    %% Classify flow regime

    if Kn >= 10

        regime = "Free molecular";

    elseif Kn >= 0.1

        regime = "Transitional";

    elseif Kn >= 0.01

        regime = "Slip";

    else

        regime = "Continuum";

    end


    %% Store values

    Altitude_km(i) = h;

    Density_kgm3(i) = rho;
    Temperature_K(i) = T;
    Rmean_JkgK(i) = Rmean;

    MolarMass_kgmol(i) = M;
    NumberDensity_m3(i) = number_density;

    MeanFreePath_m(i) = lambda;
    Knudsen(i) = Kn;

    FlowRegime(i) = regime;

end


%% Create results table

results_fmf = table( ...
    Altitude_km, ...
    Density_kgm3, ...
    Temperature_K, ...
    Rmean_JkgK, ...
    MolarMass_kgmol, ...
    NumberDensity_m3, ...
    MeanFreePath_m, ...
    CharacteristicLength_m, ...
    Knudsen, ...
    FlowRegime);


%% Display results

disp(results_fmf)


%% Overall validation

minimum_Kn = min(Knudsen);

fprintf('\n========================================\n');
fprintf('FMF VALIDATION SUMMARY\n');
fprintf('========================================\n');

fprintf('Minimum Knudsen number: %.6g\n', minimum_Kn);

if minimum_Kn >= cfg.fmf.free_molecular_threshold

    fprintf('PASS: All tested cases satisfy Kn >= %.1f.\n', ...
        cfg.fmf.free_molecular_threshold);

    fprintf('The free-molecular-flow assumption is supported.\n');

else

    fprintf('CHECK: At least one case does not satisfy Kn >= %.1f.\n', ...
        cfg.fmf.free_molecular_threshold);

end


%% Save results

save( ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'fmf_check_summary.mat'), ...
    'results_fmf', ...
    'cfg');

writetable( ...
    results_fmf, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'fmf_check_summary.csv'));


%% Plot Knudsen number

figure

semilogy( ...
    Altitude_km, ...
    Knudsen, ...
    '-o', ...
    'LineWidth', 1.5)

hold on

yline( ...
    cfg.fmf.free_molecular_threshold, ...
    '--', ...
    'FMF threshold')

grid on

xlabel('Altitude [km]')
ylabel('Knudsen number')
title('Knudsen Number vs Altitude')

hold off


%% Plot mean free path

figure

semilogy( ...
    Altitude_km, ...
    MeanFreePath_m, ...
    '-o', ...
    'LineWidth', 1.5)

grid on

xlabel('Altitude [km]')
ylabel('Mean free path [m]')
title('Mean Free Path vs Altitude')