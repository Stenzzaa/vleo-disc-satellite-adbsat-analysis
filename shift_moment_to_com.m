function out_shift = shift_moment_to_com(case_out, com_G_m)
%SHIFT_MOMENT_TO_COM Shift ADBSat moments from mesh origin to spacecraft CoM.
%   out_shift = shift_moment_to_com(case_out, com_G_m)
%   Inputs:
%       case_out  - Structure returned by run_adbsat_case.m
%
%       com_G_m   - Centre-of-mass position relative to the imported
%                   mesh origin, expressed in ADBSat geometric axes [m]
%                   Format: [x; y; z]
%
%   Output:
%       out_shift - Structure containing moments about the mesh origin
%                   and the specified centre of mass.

%% Check centre-of-mass input

validateattributes(com_G_m, {'numeric'}, ...
    {'vector','numel',3,'real','finite'}, ...
    mfilename, 'com_G_m');

com_G_m = com_G_m(:);


%% Check required ADBSat results

if ~isfield(case_out, 'Cf_f')
    error('case_out.Cf_f is missing.');
end

if ~isfield(case_out, 'Cm_origin_B')
    error('case_out.Cm_origin_B is missing.');
end

if ~isfield(case_out, 'raw') || ~isfield(case_out.raw, 'LenRef')
    error('ADBSat reference length LenRef is missing.');
end


%% ADBSat coordinate transformations

% Body to geometric axes
L_gb = [ ...
    1  0  0;
    0 -1  0;
    0  0 -1];

% Body to flight axes
L_fb = [ ...
   -1  0  0;
    0  1  0;
    0  0 -1];


%% Reference length

LenRef_m = case_out.raw.LenRef;

if ~isfinite(LenRef_m) || LenRef_m <= 0
    error('LenRef must be positive and finite.');
end


%% Convert force coefficient to body axes

Cf_f = case_out.Cf_f(:);

Cf_B = L_fb' * Cf_f;


%% Convert CoM location from geometric to body axes

com_B_m = L_gb' * com_G_m;


%% Original ADBSat moment coefficient

Cm_origin_B = case_out.Cm_origin_B(:);


%% Shift moment reference from mesh origin to CoM

delta_Cm_B = ...
    cross(com_B_m / LenRef_m, Cf_B);

Cm_com_B = ...
    Cm_origin_B - delta_Cm_B;


%% Organised output

out_shift.com_G_m = com_G_m;
out_shift.com_B_m = com_B_m;

out_shift.LenRef_m = LenRef_m;

out_shift.Cf_B = Cf_B;

out_shift.Cm_origin_B = Cm_origin_B;
out_shift.delta_Cm_B = delta_Cm_B;
out_shift.Cm_com_B = Cm_com_B;

end