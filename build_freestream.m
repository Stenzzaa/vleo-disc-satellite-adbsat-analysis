function [param_eq, env] = build_freestream(cfg, altitude_km)
%BUILD_FREESTREAM Generate atmospheric/free-stream parameters for ADBSat.
%   [param_eq, env] = build_freestream(cfg, altitude_km)
%   Inputs:
%       cfg          - Project configuration structure
%       altitude_km  - Orbital altitude [km]
%   Outputs:
%       param_eq     - ADBSat atmospheric/free-stream parameter structure
%       env          - 1x15 environment input array

%% Build environment array

env = build_environment(cfg, altitude_km);


%% Initialise ADBSat parameter structure

param_eq = struct();


%% Run ADBSat NRLMSISE-00 environment model

param_eq = environment( ...
    param_eq, ...
    env(1), ...       % altitude [m]
    env(2), ...       % latitude [deg]
    env(3), ...       % longitude [deg]
    env(4), ...       % day of year
    env(5), ...       % UT seconds
    env(6), ...       % F10.7 average
    env(7), ...       % F10.7 daily
    env(8:14), ...    % seven Ap values
    env(15));         % anomalous oxygen flag


%% Safety checks

requiredFields = {'rho','vinf','s','Rmean','Tinf'};

for k = 1:numel(requiredFields)
    if ~isfield(param_eq, requiredFields{k})
        error('Missing expected ADBSat field: %s', requiredFields{k});
    end
end

end