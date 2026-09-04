function out = run_adbsat_case(cfg, model_name, altitude_km, ...
    aoa_deg, aos_deg, gsi_model, override)
%RUN_ADBSAT_CASE Run one complete ADBSat aerodynamic case.
%
%   out = run_adbsat_case(cfg, model_name, altitude_km, ...
%       aoa_deg, aos_deg, gsi_model)
%
%   out = run_adbsat_case(..., override)
%   Inputs:
%       cfg          - Project configuration structure
%       model_name   - Imported ADBSat model name, without .mat
%       altitude_km  - Orbital altitude [km]
%       aoa_deg      - Angle of attack [deg]
%       aos_deg      - Angle of sideslip [deg]
%       gsi_model    - 'sentman' or 'CLL'
%       override     - Optional GSIM parameter overrides
%   Output:
%       out          - Structure containing case inputs and results

%% Optional GSIM override

if nargin < 7
    override = struct();
end


%% Input checks

validateattributes(altitude_km, {'numeric'}, ...
    {'scalar','real','finite','positive'});

validateattributes(aoa_deg, {'numeric'}, ...
    {'scalar','real','finite'});

validateattributes(aos_deg, {'numeric'}, ...
    {'scalar','real','finite'});


%% Locate model

modPath = fullfile( ...
    cfg.paths.model_dir, ...
    [model_name '.mat']);

if ~isfile(modPath)
    error('ADBSat model file not found: %s', modPath);
end


%% Build atmospheric conditions

[param_eq, env] = build_freestream(cfg, altitude_km);


%% Add gas-surface interaction model

param_eq = build_gsi( ...
    cfg, ...
    param_eq, ...
    gsi_model, ...
    override);


%% Generate unique output filename

switch lower(string(param_eq.gsi_model))

    case "sentman"

        gsi_tag = sprintf( ...
            'sentman_alpha_%g', ...
            param_eq.alpha);

    case "cll"

        gsi_tag = sprintf( ...
            'CLL_alphaN_%g_sigmaT_%g', ...
            param_eq.alphaN, ...
            param_eq.sigmaT);

    otherwise

        gsi_tag = char(param_eq.gsi_model);

end

result_name = sprintf( ...
    '%s_%gkm_%s_AoA_%g_AoS_%g', ...
    model_name, ...
    altitude_km, ...
    gsi_tag, ...
    aoa_deg, ...
    aos_deg);

resPath = fullfile( ...
    cfg.paths.project_results_dir, ...
    result_name);

%% Run ADBSat

pathOut = ADBSatFcn( ...
    modPath, ...
    resPath, ...
    param_eq, ...
    aoa_deg, ...
    aos_deg, ...
    cfg.flags.shadow, ...
    cfg.flags.solar, ...
    env, ...
    cfg.flags.delete_temp, ...
    cfg.flags.verbose);


%% Locate result file

if isfile(pathOut)

    result_file = pathOut;

elseif isfile([pathOut '.mat'])

    result_file = [pathOut '.mat'];

elseif isfile([resPath '.mat'])

    result_file = [resPath '.mat'];

else

    error('ADBSat result file could not be located.');

end


%% Load ADBSat results

R = load(result_file);


%% Build organised output structure

out.model = model_name;

out.altitude_km = altitude_km;
out.aoa_deg = aoa_deg;
out.aos_deg = aos_deg;

out.gsi_model = param_eq.gsi_model;

out.environment = env;
out.param_eq = param_eq;

out.rho_kgm3 = param_eq.rho(6);
out.vinf_ms = param_eq.vinf;
out.speed_ratio = param_eq.s;
out.Tinf_K = param_eq.Tinf;
out.Tw_K = param_eq.Tw;

out.result_file = result_file;
%% Retain complete raw ADBSat result

out.raw = R;

%% Extract aerodynamic results

if isfield(R, 'AreaProj')
    out.AreaProj_m2 = R.AreaProj;
else
    out.AreaProj_m2 = NaN;
end

if isfield(R, 'AreaRef')
    out.AreaRef_m2 = R.AreaRef;
else
    out.AreaRef_m2 = NaN;
end

if isfield(R, 'Cf_w')
    out.Cf_w = R.Cf_w;
else
    out.Cf_w = [NaN; NaN; NaN];
end

if isfield(R, 'Cf_f')
    out.Cf_f = R.Cf_f;
else
    out.Cf_f = [NaN; NaN; NaN];
end

if isfield(R, 'Cm_B')

    % Native ADBSat moment coefficient about mesh origin
    out.Cm_origin_B = R.Cm_B;

else

    out.Cm_origin_B = [NaN; NaN; NaN];

end
%% Shift aerodynamic moment to spacecraft centre of mass

if isfield(cfg.model, 'com_G_m')

    moment_shift = shift_moment_to_com( ...
        out, ...
        cfg.model.com_G_m);

    out.com_G_m = moment_shift.com_G_m;

    out.Cf_B = moment_shift.Cf_B;

    out.Cm_com_B = moment_shift.Cm_com_B;

    out.delta_Cm_B = moment_shift.delta_Cm_B;

else

    out.com_G_m = [0; 0; 0];

    out.Cm_com_B = out.Cm_origin_B;

    out.delta_Cm_B = [0; 0; 0];

end

% Backwards-compatible field used by existing scripts.
% From this point onward Cm_B represents the moment about the spacecraft CoM.
out.Cm_B = out.Cm_com_B;

end