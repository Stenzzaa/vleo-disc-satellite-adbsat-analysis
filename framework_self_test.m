function test_report = framework_self_test(cfg)
%FRAMEWORK_SELF_TEST Automated validation checks for project framework.
%
% Uses the known ADBSat sphere case to confirm that the core analysis
% functions remain internally consistent after code changes.

fprintf('\n');
fprintf('====================================================\n');
fprintf('ADBSat FRAMEWORK SELF-TEST\n');
fprintf('====================================================\n');


%% Test configuration

test_model = 'sphere';
test_altitude_km = 300;
test_aoa_deg = 0;
test_aos_deg = 0;
test_gsi = 'sentman';

cfg_test = cfg;

cfg_test.model.com_G_m = [0; 0; 0];
cfg_test.flags.verbose = 0;


%% Test 1: model preflight

fprintf('\n[TEST 1] Sphere preflight...\n');

preflight = model_preflight_check( ...
    cfg_test, ...
    test_model);

test1 = preflight.status == "PASS";


%% Test 2: baseline aerodynamic solution

fprintf('\n[TEST 2] Baseline aerodynamic solution...\n');

baseline = run_adbsat_case( ...
    cfg_test, ...
    test_model, ...
    test_altitude_km, ...
    test_aoa_deg, ...
    test_aos_deg, ...
    test_gsi);

CD = -baseline.Cf_w(1);

expected_CD = 1.0529445;

CD_tolerance = 5e-4;

test2 = abs(CD - expected_CD) <= CD_tolerance;

fprintf('Calculated CD: %.9f\n', CD);
fprintf('Reference CD:  %.9f\n', expected_CD);
fprintf('Difference:    %.3e\n', abs(CD - expected_CD));


%% Test 3: projected area

fprintf('\n[TEST 3] Sphere projected area...\n');

area_projected = baseline.AreaProj_m2;

expected_area = 3.1214443;

area_tolerance = 5e-4;

test3 = abs(area_projected - expected_area) <= area_tolerance;

fprintf('Calculated area: %.9f m^2\n', area_projected);
fprintf('Reference area:  %.9f m^2\n', expected_area);
fprintf('Difference:      %.3e m^2\n', ...
    abs(area_projected - expected_area));


%% Test 4: near-zero baseline moments

fprintf('\n[TEST 4] Sphere baseline moments...\n');

moment_norm = norm(baseline.Cm_B);

moment_tolerance = 1e-5;

test4 = moment_norm <= moment_tolerance;

fprintf('Moment coefficient norm: %.3e\n', moment_norm);


%% Test 5: dimensional drag consistency

fprintf('\n[TEST 5] Dimensional drag equation...\n');

drag_from_coeff = ...
    0.5 * ...
    baseline.rho_kgm3 * ...
    baseline.vinf_ms^2 * ...
    CD * ...
    baseline.AreaRef_m2;

if isfield(baseline, 'Drag_N')

    drag_stored = baseline.Drag_N;

else

    drag_stored = drag_from_coeff;

end

drag_tolerance = max( ...
    1e-12, ...
    1e-8 * abs(drag_from_coeff));

test5 = ...
    abs(drag_from_coeff - drag_stored) <= drag_tolerance;

fprintf('Calculated drag: %.9e N\n', drag_from_coeff);
fprintf('Stored drag:     %.9e N\n', drag_stored);


%% Test 6: centre-of-mass shift

fprintf('\n[TEST 6] Centre-of-mass moment shift...\n');

com_test = [0; 0.1; 0];

shifted = shift_moment_to_com( ...
    baseline, ...
    com_test);

% Obtain the ADBSat reference length directly from the validation model.
sphere_model = load(fullfile( ...
    cfg_test.paths.model_dir, ...
    [test_model '.mat']));

Lref_test = sphere_model.meshdata.Lref;

% Expected moment-coefficient change caused by moving the
% reference point from the geometric origin to the test CoM.
expected_delta_CM = ...
    cross( ...
    -com_test / Lref_test, ...
    baseline.Cf_B);

actual_delta_CM = shifted.delta_Cm_B;

com_shift_error = ...
    norm(actual_delta_CM - expected_delta_CM);

com_shift_tolerance = 1e-10;

test6 = com_shift_error <= com_shift_tolerance;

fprintf('Reference length:      %.9f m\n', Lref_test);
fprintf('CoM-shift error norm:  %.3e\n', ...
    com_shift_error);
%% Test 7: atmospheric behaviour

fprintf('\n[TEST 7] Atmospheric density trend...\n');

[param200, ~] = build_freestream(cfg_test, 200);
[param400, ~] = build_freestream(cfg_test, 400);

rho200 = param200.rho(6);
rho400 = param400.rho(6);

test7 = ...
    isfinite(rho200) && ...
    isfinite(rho400) && ...
    rho200 > 0 && ...
    rho400 > 0 && ...
    rho200 > rho400;

fprintf('Density at 200 km: %.6e kg/m^3\n', rho200);
fprintf('Density at 400 km: %.6e kg/m^3\n', rho400);


%% Test 8: FMF condition

fprintf('\n[TEST 8] Free-molecular-flow condition...\n');

Lchar = cfg_test.fmf.characteristic_length_m;
diameter = cfg_test.fmf.collision_diameter_m;
Kn_threshold = cfg_test.fmf.free_molecular_threshold;

% Atmospheric properties returned by ADBSat environment model.
Tinf = param200.Tinf;
Rmean = param200.Rmean;

% Approximate pressure using the local mixture-specific gas constant.
pressure = rho200 * Rmean * Tinf;

% Number density.
kB = 1.380649e-23;

number_density = ...
    pressure / (kB * Tinf);

% Hard-sphere approximation for mean free path.
mean_free_path = ...
    1 / ...
    (sqrt(2) * pi * diameter^2 * number_density);

% Knudsen number.
Kn = mean_free_path / Lchar;

test8 = ...
    isfinite(Kn) && ...
    Kn >= Kn_threshold;

fprintf('Mean free path at 200 km: %.3f m\n', ...
    mean_free_path);

fprintf('Characteristic length:   %.3f m\n', ...
    Lchar);

fprintf('Knudsen number:          %.3f\n', ...
    Kn);

fprintf('FMF threshold:           %.1f\n', ...
    Kn_threshold);
%% Collect results

Test = [ ...
    "Sphere preflight";
    "Baseline CD";
    "Projected area";
    "Near-zero moments";
    "Drag consistency";
    "CoM moment shift";
    "Density trend";
    "FMF condition"];

Passed = [ ...
    test1;
    test2;
    test3;
    test4;
    test5;
    test6;
    test7;
    test8];

test_table = table(Test, Passed);


%% Display summary

fprintf('\n');
fprintf('====================================================\n');
fprintf('SELF-TEST SUMMARY\n');
fprintf('====================================================\n\n');

disp(test_table)

number_passed = sum(Passed);
number_tests = numel(Passed);

fprintf('Passed %d of %d tests.\n', ...
    number_passed, number_tests);


%% Overall result

if all(Passed)

    overall_status = "PASS";

    fprintf('\nFRAMEWORK SELF-TEST: PASS\n');

else

    overall_status = "FAIL";

    fprintf('\nFRAMEWORK SELF-TEST: FAIL\n');

end

fprintf('====================================================\n');


%% Output report

test_report = struct;

test_report.status = overall_status;
test_report.results = test_table;

test_report.baseline_CD = CD;
test_report.projected_area_m2 = area_projected;
test_report.moment_norm = moment_norm;

test_report.drag_N = drag_from_coeff;

test_report.com_shift_error = com_shift_error;

test_report.rho_200_kgm3 = rho200;
test_report.rho_400_kgm3 = rho400;

test_report.Kn_200 = Kn;


%% Save report

output_file = fullfile( ...
    cfg.paths.project_results_dir, ...
    'framework_self_test.mat');

save(output_file, 'test_report');

fprintf('\nSaved self-test report:\n%s\n', ...
    output_file);

end