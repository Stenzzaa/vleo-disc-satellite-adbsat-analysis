%% refined_internal_layout_agility.m
%
% Refined internal layout for disc_lenticular_v03.
%
% Objectives:
% 1. realise aerodynamic design CoM of approximately [+6, 0, 0] mm;
% 2. remove the unwanted lateral CoM offset;
% 3. reduce the difference between Ixx and Iyy;
% 4. improve pitch-axis agility without changing external CAD;
% 5. retain the same component masses used in the concept mass budget.
%
% IMPORTANT:
% This remains a concept-level packaging model.
% Component positions are engineering layout assumptions and have not
% undergone detailed mechanical interference / harness / thermal checks.
%
% Coordinate convention:
% +X = ram direction
% +Y = lateral
% +Z = telescope / nadir direction

if ~exist('cfg','var')
    project_config
end

clc

%% ================================================================
% SETTINGS
% ================================================================

nominal_mass_kg = 50.0;

mass_sensitivity_kg = [40 45.5 50 55];

% Current working effective reaction-wheel body-axis torque assumption.
% Keep explicitly labelled as an engineering assumption until a final
% actuator is selected.

T_eff_Nm = 6.5e-3;

% VHR-class upper-bound benchmark, NOT a hard requirement for this
% moderate-resolution mission.

slew_rate_benchmark_deg_s = 4.5;

% Final shadow-ON local derivative scaled to 200 km

dMy_dalpha_200_Nm_rad = 4.91745392e-05;

%% ================================================================
% COMPONENT NAMES AND MASSES
% ================================================================

Name = { ...
'Telescope optical assembly'
'Focal-plane assembly'
'External baffle'
'Payload data handling unit'
'Primary structure'
'Telescope mount'
'Battery pack'
'PCDU'
'Body-mounted solar cells'
'Reaction wheel 1'
'Reaction wheel 2'
'Reaction wheel 3'
'Reaction wheel 4'
'Star tracker 1'
'Star tracker 2'
'IMU'
'Magnetorquers'
'GNSS receiver'
'EP thruster'
'EP PPU'
'Propellant tank dry'
'Xenon propellant'
'X-band transmitter'
'S-band transceiver'
'Antennas'
'On-board computer'
'Harness'
'Thermal control'};

m = [ ...
3.20
0.80
0.25
1.10
11.50
2.00
2.20
2.00
2.60
0.85
0.85
0.85
0.85
0.35
0.35
0.30
0.90
0.35
1.60
2.20
1.00
2.00
1.60
0.60
0.50
1.00
2.20
1.50];

%% ================================================================
% ORIGINAL STARTING LAYOUT
% ================================================================

x_original = [ ...
 0
 0.10
 0
-0.12
 0
 0
 0.30
 0.22
 0
 0.18
 0.18
-0.18
-0.18
 0.15
 0.15
 0.05
-0.25
-0.20
-0.40
-0.30
 0.25
 0.25
-0.15
-0.18
-0.10
 0.10
 0
 0];

y_original = [ ...
 0
 0
 0
 0.08
 0
 0
 0
-0.12
 0
 0.18
-0.18
 0.18
-0.18
 0.25
-0.25
 0.10
 0
 0.15
 0
 0.12
 0.15
 0.15
-0.20
 0.22
 0
-0.22
 0
 0];

z_original = [ ...
-0.005
 0.010
 0.0775
 0
 0
 0.020
-0.020
 0
 0
 0
 0
 0
 0
-0.030
-0.030
 0
 0
-0.030
 0
 0
 0
 0
 0
 0
 0
 0
 0
 0];

%% ================================================================
% REFINED INTERNAL LAYOUT
% ================================================================
%
% External geometry is unchanged.
%
% Major design logic:
%
% - telescope / structure / baffle remain fixed;
% - EP thruster remains at -X;
% - reaction-wheel square remains unchanged;
% - star trackers remain symmetric;
% - movable electronics, power and propulsion hardware are redistributed;
% - battery X and Z positions provide final fine CoM trim;
% - tank/propellant Y position removes lateral CoM offset;
% - azimuthal spread is increased to reduce Iyy/Ixx imbalance.

x = x_original;
y = y_original;
z = z_original;

%% Focal-plane assembly

x(2) = +0.095;
y(2) = -0.020;

%% Payload data handling unit

x(4) = -0.060;
y(4) = +0.095;

%% Battery pack
%
% Refined X position selected to close the +6 mm system CoM target.

x(7) = +0.2323863636;
y(7) = -0.010;

% Refined Z position removes the residual Z-CoM offset.

z(7) = -0.0090340909;

%% PCDU

x(8) = +0.180;
y(8) = -0.200;

%% IMU

x(16) = +0.065;
y(16) = +0.130;

%% Magnetorquers

x(17) = -0.155;
y(17) = -0.030;

%% GNSS receiver

x(18) = -0.115;
y(18) = +0.200;

%% EP thruster
%
% Retained at its existing rearward location.

x(19) = -0.400;
y(19) = 0;

%% EP PPU

x(20) = -0.185;
y(20) = +0.150;

%% Propellant tank and xenon
%
% Tank and propellant remain co-located.
% Y = +0.214 m closes the total lateral first moment.

x(21) = +0.210;
y(21) = +0.214;

x(22) = +0.210;
y(22) = +0.214;

%% X-band transmitter

x(23) = -0.090;
y(23) = -0.335;

%% S-band transceiver

x(24) = -0.095;
y(24) = +0.305;

%% Antennas

x(25) = -0.050;
y(25) = -0.025;

%% On-board computer

x(26) = +0.090;
y(26) = -0.355;

%% ================================================================
% MASS / CoM CHECK
% ================================================================

mass_explicit_kg = sum(m);

r_com = [ ...
    sum(m.*x), ...
    sum(m.*y), ...
    sum(m.*z)] / mass_explicit_kg;

fprintf('\n');
fprintf('====================================================\n');
fprintf('REFINED INTERNAL LAYOUT - MASS / CoM\n');
fprintf('====================================================\n');

fprintf('Explicit wet mass = %.3f kg\n', ...
    mass_explicit_kg);

fprintf('\nRefined centre of mass:\n');

fprintf('X = %+.6f mm\n', ...
    r_com(1)*1000);

fprintf('Y = %+.6f mm\n', ...
    r_com(2)*1000);

fprintf('Z = %+.6f mm\n', ...
    r_com(3)*1000);

fprintf('\nTarget:\n');
fprintf('[+6.000000, 0.000000, 0.000000] mm\n');

fprintf('\nCoM errors:\n');

fprintf('dX = %+.6f mm\n', ...
    (r_com(1)-0.006)*1000);

fprintf('dY = %+.6f mm\n', ...
    r_com(2)*1000);

fprintf('dZ = %+.6f mm\n', ...
    r_com(3)*1000);

%% ================================================================
% OWN-INERTIA MODELS
% ================================================================

nComp = numel(m);

Iown = zeros(3,3,nComp);

%% Telescope

Iown(:,:,1) = ...
    cylinderInertiaZ( ...
    m(1), ...
    0.20, ...
    0.085);

%% FPA

Iown(:,:,2) = ...
    cuboidInertia( ...
    m(2), ...
    0.12, ...
    0.10, ...
    0.04);

%% Baffle

Iown(:,:,3) = ...
    hollowCylinderInertiaZ( ...
    m(3), ...
    0.050, ...
    0.045, ...
    0.055);

%% Payload handling

Iown(:,:,4) = ...
    cuboidInertia( ...
    m(4), ...
    0.12, ...
    0.10, ...
    0.03);

%% Main structure

Iown(:,:,5) = ...
    solidDiscInertiaZ( ...
    m(5), ...
    0.50, ...
    0.10);

%% Telescope mount

Iown(:,:,6) = ...
    cylinderInertiaZ( ...
    m(6), ...
    0.225, ...
    0.010);

%% Battery

Iown(:,:,7) = ...
    cuboidInertia( ...
    m(7), ...
    0.20, ...
    0.14, ...
    0.05);

%% PCDU

Iown(:,:,8) = ...
    cuboidInertia( ...
    m(8), ...
    0.16, ...
    0.12, ...
    0.04);

%% Solar cells

Iown(:,:,9) = ...
    twoFaceAnnulusInertia( ...
    m(9), ...
    0.50, ...
    0.05, ...
    0.048);

%% Star trackers

Iown(:,:,14) = ...
    cuboidInertia( ...
    m(14), ...
    0.10, ...
    0.06, ...
    0.06);

Iown(:,:,15) = ...
    cuboidInertia( ...
    m(15), ...
    0.10, ...
    0.06, ...
    0.06);

%% IMU

Iown(:,:,16) = ...
    cuboidInertia( ...
    m(16), ...
    0.08, ...
    0.08, ...
    0.03);

%% GNSS

Iown(:,:,18) = ...
    cuboidInertia( ...
    m(18), ...
    0.10, ...
    0.08, ...
    0.03);

%% PPU

Iown(:,:,20) = ...
    cuboidInertia( ...
    m(20), ...
    0.18, ...
    0.14, ...
    0.05);

%% X-band

Iown(:,:,23) = ...
    cuboidInertia( ...
    m(23), ...
    0.14, ...
    0.12, ...
    0.04);

%% S-band

Iown(:,:,24) = ...
    cuboidInertia( ...
    m(24), ...
    0.10, ...
    0.08, ...
    0.03);

%% OBC

Iown(:,:,26) = ...
    cuboidInertia( ...
    m(26), ...
    0.12, ...
    0.10, ...
    0.03);

%% Harness

Iown(:,:,27) = ...
    solidDiscInertiaZ( ...
    m(27), ...
    0.45, ...
    0.08);

%% Thermal system

Iown(:,:,28) = ...
    solidDiscInertiaZ( ...
    m(28), ...
    0.45, ...
    0.08);

%% ================================================================
% CALCULATE REFINED INERTIA TENSOR
% ================================================================

r = [x y z];

I_refined = zeros(3);

for i = 1:nComp

    d = ...
        r(i,:)' - ...
        r_com';

    I_parallel = ...
        m(i) * ...
        ( ...
        dot(d,d)*eye(3) ...
        - d*d' ...
        );

    I_refined = ...
        I_refined + ...
        Iown(:,:,i) + ...
        I_parallel;

end

I_refined = ...
    0.5 * ...
    (I_refined + I_refined');

[V_ref,D_ref] = eig(I_refined);

principal_refined = ...
    sort(diag(D_ref));

fprintf('\n');
fprintf('====================================================\n');
fprintf('REFINED 45.5 kg INERTIA TENSOR\n');
fprintf('====================================================\n\n');

disp(I_refined);

fprintf('Ixx = %.6f kg m^2\n', ...
    I_refined(1,1));

fprintf('Iyy = %.6f kg m^2\n', ...
    I_refined(2,2));

fprintf('Izz = %.6f kg m^2\n', ...
    I_refined(3,3));

fprintf('\nIyy/Ixx = %.6f\n', ...
    I_refined(2,2) / ...
    I_refined(1,1));

fprintf('\nPrincipal moments:\n');

disp(principal_refined');

%% ================================================================
% ORIGINAL INERTIA FOR COMPARISON
% ================================================================

r_original = [ ...
    x_original ...
    y_original ...
    z_original];

r_com_original = ...
    sum(m .* r_original,1) / ...
    mass_explicit_kg;

I_original = zeros(3);

for i = 1:nComp

    d = ...
        r_original(i,:)' - ...
        r_com_original';

    I_parallel = ...
        m(i) * ...
        ( ...
        dot(d,d)*eye(3) ...
        - d*d' ...
        );

    I_original = ...
        I_original + ...
        Iown(:,:,i) + ...
        I_parallel;

end

I_original = ...
    0.5 * ...
    (I_original + I_original');

fprintf('\n');
fprintf('====================================================\n');
fprintf('ORIGINAL VS REFINED INERTIA\n');
fprintf('====================================================\n');

fprintf('\nOriginal:\n');

fprintf('Ixx = %.6f\n', ...
    I_original(1,1));

fprintf('Iyy = %.6f\n', ...
    I_original(2,2));

fprintf('Izz = %.6f\n', ...
    I_original(3,3));

fprintf('\nRefined:\n');

fprintf('Ixx = %.6f\n', ...
    I_refined(1,1));

fprintf('Iyy = %.6f\n', ...
    I_refined(2,2));

fprintf('Izz = %.6f\n', ...
    I_refined(3,3));

fprintf('\nPitch-inertia change:\n');

fprintf('dIyy = %+.6f kg m^2\n', ...
    I_refined(2,2) - ...
    I_original(2,2));

fprintf('Iyy change = %+.3f %%\n', ...
    100 * ...
    ( ...
    I_refined(2,2) - ...
    I_original(2,2) ...
    ) / ...
    I_original(2,2));

%% ================================================================
% SCALE TO 50 kg NOMINAL CASE
% ================================================================

scale_50 = ...
    nominal_mass_kg / ...
    mass_explicit_kg;

I50 = ...
    I_refined * ...
    scale_50;

Ixx = I50(1,1);
Iyy = I50(2,2);
Izz = I50(3,3);

fprintf('\n');
fprintf('====================================================\n');
fprintf('REFINED 50 kg NOMINAL INERTIA\n');
fprintf('====================================================\n');

fprintf('Ixx = %.6f kg m^2\n', Ixx);
fprintf('Iyy = %.6f kg m^2\n', Iyy);
fprintf('Izz = %.6f kg m^2\n', Izz);

fprintf('Iyy/Ixx = %.6f\n', ...
    Iyy/Ixx);

%% ================================================================
% SLEW ASSESSMENT
% ================================================================

slew_angles_deg = [30 45 60 90];

I_axis = [ ...
    Ixx ...
    Iyy ...
    Izz];

axis_names = ["X";"Y";"Z"];

nAngles = numel(slew_angles_deg);
nRows = 3*nAngles;

Axis = strings(nRows,1);
SlewAngle_deg = zeros(nRows,1);
Inertia_kgm2 = zeros(nRows,1);
AssumedTorque_Nm = zeros(nRows,1);
SlewTime_s = zeros(nRows,1);
PeakRate_deg_s = zeros(nRows,1);
MomentumRequired_Nms = zeros(nRows,1);
RateRatioToBenchmark = zeros(nRows,1);

row = 0;

for axis = 1:3

    for j = 1:nAngles

        row = row + 1;

        theta = ...
            deg2rad( ...
            slew_angles_deg(j));

        I = ...
            I_axis(axis);

        t_slew = ...
            2 * ...
            sqrt( ...
            theta * I / ...
            T_eff_Nm);

        omega_peak = ...
            sqrt( ...
            theta * ...
            T_eff_Nm / ...
            I);

        h_required = ...
            I * ...
            omega_peak;

        Axis(row) = ...
            axis_names(axis);

        SlewAngle_deg(row) = ...
            slew_angles_deg(j);

        Inertia_kgm2(row) = ...
            I;

        AssumedTorque_Nm(row) = ...
            T_eff_Nm;

        SlewTime_s(row) = ...
            t_slew;

        PeakRate_deg_s(row) = ...
            rad2deg(omega_peak);

        MomentumRequired_Nms(row) = ...
            h_required;

        RateRatioToBenchmark(row) = ...
            rad2deg(omega_peak) / ...
            slew_rate_benchmark_deg_s;

    end

end

results_slew = table( ...
    Axis, ...
    SlewAngle_deg, ...
    Inertia_kgm2, ...
    AssumedTorque_Nm, ...
    SlewTime_s, ...
    PeakRate_deg_s, ...
    MomentumRequired_Nms, ...
    RateRatioToBenchmark);

fprintf('\n');
fprintf('====================================================\n');
fprintf('REFINED 50 kg SLEW ASSESSMENT\n');
fprintf('====================================================\n\n');

disp(results_slew);

%% ================================================================
% 30 DEG PITCH RESULT
% ================================================================

idx_pitch30 = ...
    results_slew.Axis == "Y" & ...
    results_slew.SlewAngle_deg == 30;

fprintf('\n');
fprintf('====================================================\n');
fprintf('30 DEGREE PITCH MANOEUVRE\n');
fprintf('====================================================\n');

fprintf('Pitch inertia Iyy = %.6f kg m^2\n', ...
    Iyy);

fprintf('Assumed effective torque = %.3f mN m\n', ...
    T_eff_Nm*1000);

fprintf('Slew time = %.3f s\n', ...
    results_slew.SlewTime_s(idx_pitch30));

fprintf('Peak rate = %.3f deg/s\n', ...
    results_slew.PeakRate_deg_s(idx_pitch30));

fprintf('Momentum required = %.6f N m s\n', ...
    results_slew.MomentumRequired_Nms(idx_pitch30));

%% ================================================================
% TORQUE REQUIRED FOR 4.5 DEG/S BENCHMARK
% ================================================================

omega_benchmark = ...
    deg2rad( ...
    slew_rate_benchmark_deg_s);

theta30 = ...
    deg2rad(30);

T_required_4p5 = ...
    Iyy * ...
    omega_benchmark^2 / ...
    theta30;

H_at_4p5 = ...
    Iyy * ...
    omega_benchmark;

fprintf('\n');
fprintf('====================================================\n');
fprintf('VHR-CLASS 4.5 deg/s BENCHMARK\n');
fprintf('====================================================\n');

fprintf(['This is an upper-bound benchmark, not a hard mission ' ...
    'requirement for the present moderate-resolution concept.\n\n']);

fprintf('Required pitch-axis torque = %.3f mN m\n', ...
    T_required_4p5*1000);

fprintf('Pitch momentum at 4.5 deg/s = %.6f N m s\n', ...
    H_at_4p5);

%% ================================================================
% MASS SENSITIVITY
% ================================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf('REFINED MASS SENSITIVITY\n');
fprintf('====================================================\n');

for k = 1:numel(mass_sensitivity_kg)

    Mtest = ...
        mass_sensitivity_kg(k);

    Itest = ...
        I_refined * ...
        (Mtest/mass_explicit_kg);

    Iyy_test = ...
        Itest(2,2);

    t30 = ...
        2 * ...
        sqrt( ...
        theta30 * ...
        Iyy_test / ...
        T_eff_Nm);

    omega30 = ...
        sqrt( ...
        theta30 * ...
        T_eff_Nm / ...
        Iyy_test);

    fprintf('\nMass = %.1f kg\n', ...
        Mtest);

    fprintf( ...
        'Ixx/Iyy/Izz = %.3f / %.3f / %.3f kg m^2\n', ...
        Itest(1,1), ...
        Itest(2,2), ...
        Itest(3,3));

    fprintf( ...
        '30 deg pitch slew = %.2f s\n', ...
        t30);

    fprintf( ...
        'Peak rate = %.2f deg/s\n', ...
        rad2deg(omega30));

end

%% ================================================================
% PITCH DIVERGENCE TIMESCALE
% ================================================================

tau_pitch_200_s = ...
    sqrt( ...
    Iyy / ...
    dMy_dalpha_200_Nm_rad);

fprintf('\n');
fprintf('====================================================\n');
fprintf('REFINED LOCAL PITCH-DIVERGENCE TIMESCALE\n');
fprintf('====================================================\n');

fprintf('Iyy = %.6f kg m^2\n', ...
    Iyy);

fprintf('dMy/dalpha at 200 km = %.8e N m/rad\n', ...
    dMy_dalpha_200_Nm_rad);

fprintf('tau = %.2f s\n', ...
    tau_pitch_200_s);

fprintf('\n');
fprintf(['This remains an open-loop aerodynamic timescale, ' ...
    'not an ACS settling-time prediction.\n']);

%% ================================================================
% SAVE RESULTS
% ================================================================

components_refined = table( ...
    string(Name), ...
    m, ...
    x_original, ...
    y_original, ...
    z_original, ...
    x, ...
    y, ...
    z, ...
    'VariableNames', { ...
    'Component', ...
    'Mass_kg', ...
    'X_original_m', ...
    'Y_original_m', ...
    'Z_original_m', ...
    'X_refined_m', ...
    'Y_refined_m', ...
    'Z_refined_m'});

summary_refined = struct();

summary_refined.mass_explicit_kg = ...
    mass_explicit_kg;

summary_refined.CoM_refined_m = ...
    r_com;

summary_refined.I_refined_45p5kg_kgm2 = ...
    I_refined;

summary_refined.I_refined_50kg_kgm2 = ...
    I50;

summary_refined.pitch_inertia_50kg_kgm2 = ...
    Iyy;

summary_refined.pitch30_slew_time_s = ...
    results_slew.SlewTime_s(idx_pitch30);

summary_refined.pitch30_peak_rate_deg_s = ...
    results_slew.PeakRate_deg_s(idx_pitch30);

summary_refined.pitch30_momentum_Nms = ...
    results_slew.MomentumRequired_Nms(idx_pitch30);

summary_refined.torque_for_4p5_deg_s_Nm = ...
    T_required_4p5;

summary_refined.momentum_at_4p5_deg_s_Nms = ...
    H_at_4p5;

summary_refined.pitch_divergence_tau_200_s = ...
    tau_pitch_200_s;

writetable( ...
    components_refined, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'refined_internal_layout.csv'));

writetable( ...
    results_slew, ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'refined_agility_slew_results.csv'));

save( ...
    fullfile( ...
        cfg.paths.project_results_dir, ...
        'refined_internal_layout_agility.mat'), ...
    'components_refined', ...
    'results_slew', ...
    'summary_refined');

fprintf('\n');
fprintf('====================================================\n');
fprintf('REFINED INTERNAL LAYOUT ASSESSMENT COMPLETE\n');
fprintf('====================================================\n');

fprintf('External aerodynamic CAD unchanged.\n');

fprintf(['Detailed mechanical packaging/interference checks are ' ...
    'outside this concept-level assessment.\n']);

%% ================================================================
% LOCAL FUNCTIONS
% ================================================================

function I = cuboidInertia(m,a,b,c)

I = diag([ ...
    m*(b^2+c^2)/12, ...
    m*(a^2+c^2)/12, ...
    m*(a^2+b^2)/12]);

end

function I = cylinderInertiaZ(m,r,h)

Izz = ...
    0.5*m*r^2;

Itrans = ...
    m*(3*r^2+h^2)/12;

I = diag([ ...
    Itrans ...
    Itrans ...
    Izz]);

end

function I = hollowCylinderInertiaZ(m,ro,ri,h)

Izz = ...
    0.5*m*(ro^2+ri^2);

Itrans = ...
    m*(3*(ro^2+ri^2)+h^2)/12;

I = diag([ ...
    Itrans ...
    Itrans ...
    Izz]);

end

function I = solidDiscInertiaZ(m,r,t)

Izz = ...
    0.5*m*r^2;

Ixx = ...
    0.25*m*r^2 + ...
    m*t^2/12;

I = diag([ ...
    Ixx ...
    Ixx ...
    Izz]);

end

function I = twoFaceAnnulusInertia(m,ro,ri,zface)

Izz = ...
    0.5*m*(ro^2+ri^2);

Ixx = ...
    0.25*m*(ro^2+ri^2) + ...
    m*zface^2;

I = diag([ ...
    Ixx ...
    Ixx ...
    Izz]);

end