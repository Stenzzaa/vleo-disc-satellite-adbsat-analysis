function metadata = save_run_metadata( ...
    cfg, ...
    run_flags, ...
    analysis_start, ...
    analysis_end, ...
    elapsed_seconds)
%SAVE_RUN_METADATA Records the configuration used for an analysis run.
% back to the model, environment, CoM, analysis settings and MATLAB files
% used to generate them.

fprintf('\n');
fprintf('====================================================\n');
fprintf('SAVING RUN METADATA\n');
fprintf('====================================================\n');


%% Run identifier

run_id = ...
    ['run_' datestr(analysis_start, 'yyyymmdd_HHMMSS')];

metadata = struct;

metadata.run_id = string(run_id);

metadata.analysis_start = analysis_start;
metadata.analysis_end = analysis_end;
metadata.elapsed_seconds = elapsed_seconds;


%% MATLAB environment

metadata.matlab = struct;

metadata.matlab.version = string(version);
metadata.matlab.release = string(version('-release'));
metadata.matlab.computer = string(computer);
metadata.matlab.working_directory = string(pwd);


%% Complete configuration snapshot

% Saving the complete cfg structure is intentional.
% It preserves every project setting used for the run.

metadata.cfg = cfg;


%% Analysis-selection snapshot

metadata.analysis_flags = run_flags;


%% Model information

metadata.model = struct;

metadata.model.name = string(cfg.model.name);
metadata.model.com_G_m = cfg.model.com_G_m(:);

model_file = fullfile( ...
    cfg.paths.model_dir, ...
    [char(cfg.model.name) '.mat']);

metadata.model.file = string(model_file);


if isfile(model_file)

    model_info = dir(model_file);

    metadata.model.file_bytes = model_info.bytes;
    metadata.model.file_modified = string(model_info.date);

    model_data = load(model_file);

    if isfield(model_data, 'meshdata')

        meshdata = model_data.meshdata;

        metadata.model.panel_count = ...
            numel(meshdata.Areas);

        metadata.model.total_surface_area_m2 = ...
            sum(meshdata.Areas(:));

        metadata.model.Lref_m = ...
            meshdata.Lref;

        metadata.model.material_ids = ...
            unique(meshdata.MatID(:));

    end

else

    warning('Model MAT file could not be found for metadata.');

end


%% ADBSat installation information

metadata.adbsat = struct;

metadata.adbsat.ADBSatFcn = ...
    string(which('ADBSatFcn'));

metadata.adbsat.calc_coeff = ...
    string(which('calc_coeff'));

metadata.adbsat.environment = ...
    string(which('environment'));

metadata.adbsat.ADBSatImport = ...
    string(which('ADBSatImport'));

metadata.adbsat.coeff_sentman = ...
    string(which('coeff_sentman'));

metadata.adbsat.coeff_CLL = ...
    string(which('coeff_CLL'));


%% Project-code information

project_functions = { ...
    'run_project_analysis', ...
    'project_config', ...
    'run_adbsat_case', ...
    'build_freestream', ...
    'build_gsi', ...
    'shift_moment_to_com', ...
    'model_preflight_check', ...
    'framework_self_test', ...
    'fmf_check', ...
    'altitude_sweep', ...
    'environment_sensitivity', ...
    'attitude_sweep', ...
    'small_angle_check', ...
    'gsi_sensitivity', ...
    'mesh_sensitivity'};

nFunctions = numel(project_functions);

Function = strings(nFunctions,1);
Path = strings(nFunctions,1);
Modified = strings(nFunctions,1);

for i = 1:nFunctions

    Function(i) = string(project_functions{i});

    file_path = which(project_functions{i});

    Path(i) = string(file_path);

    if ~isempty(file_path) && isfile(file_path)

        file_info = dir(file_path);

        Modified(i) = string(file_info.date);

    else

        Modified(i) = "Not found";

    end

end

metadata.project_files = table( ...
    Function, ...
    Path, ...
    Modified);


%% Results generated during this run

results_dir = cfg.paths.project_results_dir;

result_files = dir(results_dir);

result_files = ...
    result_files(~[result_files.isdir]);

generated_names = strings(0,1);

if ~isempty(result_files)

    start_dn = datenum(analysis_start) - 2/86400;
    end_dn = datenum(analysis_end) + 2/86400;

    generated_mask = ...
        [result_files.datenum] >= start_dn & ...
        [result_files.datenum] <= end_dn;

    generated = result_files(generated_mask);

    if ~isempty(generated)

        generated_names = ...
            string({generated.name}).';

    end

end

metadata.generated_result_files = generated_names;


%% Save metadata

metadata_file = fullfile( ...
    results_dir, ...
    [run_id '_metadata.mat']);

save( ...
    metadata_file, ...
    'metadata');


%% Display summary

fprintf('Run ID:       %s\n', run_id);
fprintf('Model:        %s\n', cfg.model.name);
fprintf('Started:      %s\n', char(analysis_start));
fprintf('Finished:     %s\n', char(analysis_end));
fprintf('Runtime:      %.2f seconds\n', elapsed_seconds);

fprintf('\nMetadata file:\n%s\n', metadata_file);

fprintf('\nFiles generated or updated during run: %d\n', ...
    numel(generated_names));

fprintf('====================================================\n');

end