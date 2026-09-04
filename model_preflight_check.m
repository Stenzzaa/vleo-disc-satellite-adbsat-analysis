function report = model_preflight_check(cfg, model_name)
%MODEL_PREFLIGHT_CHECK Checks an imported ADBSat model before analysis.
%
% report = model_preflight_check(cfg)
% report = model_preflight_check(cfg, model_name)
%
% Checks:
%   - Model file exists
%   - Required ADBSat mesh fields exist
%   - Panel dimensions are consistent
%   - No NaN or Inf values
%   - All panel areas are positive
%   - Bounding dimensions
%   - Reference length consistency
%   - Surface-normal magnitudes
%   - Material IDs
%   - Centre-of-mass definition and location
%
% This does not replace a dedicated watertight/manifold mesh inspection.

%% Model selection

if nargin < 2 || isempty(model_name)
    model_name = cfg.model.name;
end

model_name = char(model_name);

model_file = fullfile( ...
    cfg.paths.model_dir, ...
    [model_name '.mat']);


%% Header

fprintf('\n');
fprintf('====================================================\n');
fprintf('MODEL PREFLIGHT CHECK\n');
fprintf('====================================================\n');
fprintf('Model: %s\n', model_name);
fprintf('File:  %s\n\n', model_file);


%% File existence

if ~isfile(model_file)
    error('Model file does not exist:\n%s', model_file);
end

S = load(model_file);

if ~isfield(S, 'meshdata')
    error('The MAT file does not contain an ADBSat meshdata structure.');
end

meshdata = S.meshdata;


%% Required ADBSat fields

required_fields = { ...
    'XData', ...
    'YData', ...
    'ZData', ...
    'MatID', ...
    'Areas', ...
    'SurfN', ...
    'BariC', ...
    'Lref'};

missing_fields = required_fields( ...
    ~isfield(meshdata, required_fields));

if ~isempty(missing_fields)

    fprintf('FAIL: Missing required fields:\n');

    disp(missing_fields)

    error('Model preflight failed due to missing mesh fields.');

end


%% Panel count

panel_count = numel(meshdata.Areas);

if panel_count < 1
    error('Model contains no surface panels.');
end


%% Check coordinate dimensions

coordinate_size_ok = ...
    size(meshdata.XData,1) == 3 && ...
    size(meshdata.YData,1) == 3 && ...
    size(meshdata.ZData,1) == 3 && ...
    size(meshdata.XData,2) == panel_count && ...
    size(meshdata.YData,2) == panel_count && ...
    size(meshdata.ZData,2) == panel_count;

if ~coordinate_size_ok
    error('Mesh coordinate dimensions are inconsistent with panel count.');
end


%% Check panel-data dimensions

normal_size_ok = ...
    size(meshdata.SurfN,1) == 3 && ...
    size(meshdata.SurfN,2) == panel_count;

baricentre_size_ok = ...
    size(meshdata.BariC,1) == 3 && ...
    size(meshdata.BariC,2) == panel_count;

if ~normal_size_ok
    error('Surface-normal array dimensions are inconsistent.');
end

if ~baricentre_size_ok
    error('Barycentre array dimensions are inconsistent.');
end


%% Flatten coordinate arrays

x = meshdata.XData(:);
y = meshdata.YData(:);
z = meshdata.ZData(:);


%% Finite-number check

all_numeric_data = [ ...
    x; ...
    y; ...
    z; ...
    meshdata.Areas(:); ...
    meshdata.SurfN(:); ...
    meshdata.BariC(:); ...
    meshdata.Lref];

finite_ok = all(isfinite(all_numeric_data));

if ~finite_ok
    error('Mesh contains NaN or Inf values.');
end


%% Panel-area check

areas = meshdata.Areas(:);

positive_areas = all(areas > 0);

if ~positive_areas
    error('One or more mesh panels have zero or negative area.');
end

total_area = sum(areas);


%% Bounding dimensions

xmin = min(x);
xmax = max(x);

ymin = min(y);
ymax = max(y);

zmin = min(z);
zmax = max(z);

dimension_x = xmax - xmin;
dimension_y = ymax - ymin;
dimension_z = zmax - zmin;


%% Reference-length verification

calculated_Lref = dimension_x;
stored_Lref = meshdata.Lref;

Lref_difference = abs( ...
    stored_Lref - calculated_Lref);

Lref_tolerance = max( ...
    1e-9, ...
    1e-6 * max(abs([stored_Lref calculated_Lref])));

Lref_ok = Lref_difference <= Lref_tolerance;


%% Surface-normal check

normal_magnitude = vecnorm(meshdata.SurfN, 2, 1);

normal_min = min(normal_magnitude);
normal_max = max(normal_magnitude);
normal_mean = mean(normal_magnitude);

normal_tolerance = 1e-6;

normals_unit = all( ...
    abs(normal_magnitude - 1) <= normal_tolerance);


%% Material IDs

material_ids = unique(meshdata.MatID);
number_material_ids = numel(material_ids);


%% Centre of mass

if ~isfield(cfg, 'model') || ...
        ~isfield(cfg.model, 'com_G_m')

    error('cfg.model.com_G_m is not defined.');

end

com = cfg.model.com_G_m(:);

if numel(com) ~= 3 || ...
        ~isnumeric(com) || ...
        any(~isfinite(com))

    error('cfg.model.com_G_m must be a finite 3x1 numeric vector.');

end


%% Is CoM within mesh bounding box?

com_inside_bbox = ...
    com(1) >= xmin && com(1) <= xmax && ...
    com(2) >= ymin && com(2) <= ymax && ...
    com(3) >= zmin && com(3) <= zmax;


%% Build report

report = struct;

report.model = string(model_name);
report.model_file = string(model_file);

report.panel_count = panel_count;

report.total_surface_area_m2 = total_area;

report.bounds_m = [ ...
    xmin xmax;
    ymin ymax;
    zmin zmax];

report.dimensions_m = [ ...
    dimension_x;
    dimension_y;
    dimension_z];

report.Lref_stored_m = stored_Lref;
report.Lref_calculated_m = calculated_Lref;
report.Lref_difference_m = Lref_difference;

report.material_ids = material_ids;
report.number_material_ids = number_material_ids;

report.normal_magnitude_min = normal_min;
report.normal_magnitude_mean = normal_mean;
report.normal_magnitude_max = normal_max;

report.com_G_m = com;
report.com_inside_bounding_box = com_inside_bbox;


%% Display geometry summary

fprintf('Geometry\n');
fprintf('----------------------------------------------------\n');

fprintf('Panels:                %d\n', panel_count);
fprintf('Total surface area:    %.9f m^2\n', total_area);

fprintf('\nBounding dimensions:\n');
fprintf('X dimension:           %.9f m\n', dimension_x);
fprintf('Y dimension:           %.9f m\n', dimension_y);
fprintf('Z dimension:           %.9f m\n', dimension_z);

fprintf('\nReference length:\n');
fprintf('Stored Lref:           %.9f m\n', stored_Lref);
fprintf('Calculated X span:     %.9f m\n', calculated_Lref);
fprintf('Difference:            %.3e m\n', Lref_difference);

fprintf('\nMaterial IDs:\n');
disp(material_ids.')

fprintf('Number of IDs:         %d\n', number_material_ids);

fprintf('\nSurface normals:\n');
fprintf('Minimum magnitude:     %.9f\n', normal_min);
fprintf('Mean magnitude:        %.9f\n', normal_mean);
fprintf('Maximum magnitude:     %.9f\n', normal_max);

fprintf('\nCentre of mass:\n');
fprintf('X:                     %.9f m\n', com(1));
fprintf('Y:                     %.9f m\n', com(2));
fprintf('Z:                     %.9f m\n', com(3));


%% PASS / WARNING summary

fprintf('\n');
fprintf('====================================================\n');
fprintf('PREFLIGHT SUMMARY\n');
fprintf('====================================================\n');

fprintf('PASS: Model file successfully loaded.\n');
fprintf('PASS: Required ADBSat mesh fields are present.\n');
fprintf('PASS: Panel arrays are dimensionally consistent.\n');
fprintf('PASS: No NaN or Inf values detected.\n');
fprintf('PASS: All panel areas are positive.\n');

if Lref_ok

    fprintf('PASS: Lref agrees with the model X-span.\n');

else

    fprintf('WARNING: Lref does not agree with the X-span.\n');

end

if normals_unit

    fprintf('PASS: Surface normals are unit magnitude.\n');

else

    fprintf(['WARNING: Some surface normals are not exactly ' ...
        'unit magnitude.\n']);

end

if com_inside_bbox

    fprintf('PASS: Centre of mass lies inside the mesh bounding box.\n');

else

    fprintf(['WARNING: Centre of mass lies outside the mesh ' ...
        'bounding box.\n']);

end

fprintf('\n');


%% Overall status

critical_pass = ...
    finite_ok && ...
    positive_areas && ...
    coordinate_size_ok && ...
    normal_size_ok && ...
    baricentre_size_ok && ...
    Lref_ok;

if critical_pass

    report.status = "PASS";

    fprintf('OVERALL PREFLIGHT STATUS: PASS\n');

else

    report.status = "CHECK";

    fprintf('OVERALL PREFLIGHT STATUS: CHECK REQUIRED\n');

end

fprintf('====================================================\n');


%% Save report

if ~exist(cfg.paths.project_results_dir, 'dir')
    mkdir(cfg.paths.project_results_dir)
end

output_file = fullfile( ...
    cfg.paths.project_results_dir, ...
    ['preflight_' model_name '.mat']);

save(output_file, 'report');

fprintf('\nSaved report:\n%s\n', output_file);

end