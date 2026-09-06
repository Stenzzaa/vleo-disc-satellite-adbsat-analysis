function env = build_environment(cfg, altitude_km)
%BUILD_ENVIRONMENT Build the 1x15 ADBSat NRLMSISE-00 environment array.
%
%   env = build_environment(cfg, altitude_km)
%
%   Inputs:
%       cfg          - Project configuration structure
%       altitude_km  - Orbital altitude in kilometres
%
%   Output:
%       env          - 1x15 ADBSat environment array

%% Input checks

validateattributes(altitude_km, {'numeric'}, ...
    {'scalar','real','finite','positive'}, ...
    mfilename, 'altitude_km');

if cfg.env.day_of_year < 1 || cfg.env.day_of_year > 365
    error('Day of year must be between 1 and 365.');
end

if cfg.env.ut_seconds < 0 || cfg.env.ut_seconds >= 86400
    error('UT seconds must be between 0 and 86399.');
end

if numel(cfg.env.ap) ~= 7
    error('The Ap geomagnetic index must contain exactly 7 values.');
end


%% Unit conversion

altitude_m = altitude_km * 1000;


%% Construct ADBSat environment array

env = [ ...
    altitude_m, ...                   % env(1)    altitude [m]
    cfg.env.latitude_deg, ...         % env(2)    latitude [deg]
    cfg.env.longitude_deg, ...        % env(3)    longitude [deg]
    cfg.env.day_of_year, ...          % env(4)    day of year
    cfg.env.ut_seconds, ...           % env(5)    UT seconds
    cfg.env.f107_average, ...         % env(6)    81-day F10.7 average
    cfg.env.f107_daily, ...           % env(7)    daily F10.7
    cfg.env.ap(:).', ...              % env(8:14) seven Ap values
    cfg.env.anomalous_oxygen ...      % env(15)   anomalous oxygen flag
    ];


%% Final safety check

if numel(env) ~= 15
    error('ADBSat environment array must contain exactly 15 elements.');
end

end