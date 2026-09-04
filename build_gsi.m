function param_eq = build_gsi(cfg, param_eq, model, override)
%BUILD_GSI Add gas-surface interaction parameters to ADBSat param_eq.
%   param_eq = build_gsi(cfg, param_eq, model)
%   param_eq = build_gsi(cfg, param_eq, model, override)
%   Inputs:
%       cfg       - Project configuration structure
%       param_eq  - Structure produced by build_freestream
%       model     - 'sentman' or 'CLL'
%       override  - Optional structure containing alternative
%                   accommodation parameters for sensitivity studies
%   Output:
%       param_eq  - ADBSat parameter structure ready for the chosen GSIM

%% Optional override

if nargin < 4
    override = struct();
end

%% General checks

if ~isstruct(param_eq)
    error('param_eq must be a structure.');
end

if ~isfield(param_eq, 'Tinf')
    error('param_eq.Tinf is missing. Run build_freestream first.');
end

if ~isfield(param_eq, 'rho')
    error('param_eq.rho is missing. Run build_freestream first.');
end

if ~isfield(param_eq, 'vinf')
    error('param_eq.vinf is missing. Run build_freestream first.');
end

if ~isfield(param_eq, 's')
    error('param_eq.s is missing. Run build_freestream first.');
end

%% Wall temperature

param_eq.Tw = cfg.gsi.wall_temperature_K;

if ~isfinite(param_eq.Tw) || param_eq.Tw <= 0
    error('Wall temperature must be a positive finite value.');
end

%% Select gas-surface interaction model

switch lower(string(model))

    case "sentman"

        param_eq.gsi_model = 'sentman';

        % Use override value when supplied
        if isfield(override, 'alpha')
            param_eq.alpha = override.alpha;
        else
            param_eq.alpha = cfg.gsi.sentman.alpha;
        end

        % Accommodation coefficient validation
        if any(param_eq.alpha < 0 | param_eq.alpha > 1)
            error('Sentman alpha must lie between 0 and 1.');
        end


    case "cll"

        param_eq.gsi_model = 'CLL';

        % Normal thermal energy accommodation
        if isfield(override, 'alphaN')
            param_eq.alphaN = override.alphaN;
        else
            param_eq.alphaN = cfg.gsi.cll.alphaN;
        end

        % Tangential momentum accommodation
        if isfield(override, 'sigmaT')
            param_eq.sigmaT = override.sigmaT;
        else
            param_eq.sigmaT = cfg.gsi.cll.sigmaT;
        end

        % CLL parameter validation
        if any(param_eq.alphaN <= 0 | param_eq.alphaN > 1)
            error('CLL alphaN must be greater than 0 and no greater than 1.');
        end

        if any(param_eq.sigmaT < 0 | param_eq.sigmaT > 1)
            error('CLL sigmaT must lie between 0 and 1.');
        end


    otherwise

        error('Unsupported GSIM. Use ''sentman'' or ''CLL''.');

end

end