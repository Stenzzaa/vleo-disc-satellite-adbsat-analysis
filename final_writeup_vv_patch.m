%% final_writeup_vv_patch.m
%
% Adds final verification / reproducibility evidence to the existing
% FINAL_WRITEUP_RESULTS package.
%
% No original results are modified or deleted.

if ~exist('cfg','var')
    project_config
end

clc

source_root = ...
    cfg.paths.project_results_dir;

package_root = fullfile( ...
    source_root, ...
    'FINAL_WRITEUP_RESULTS');

vv_folder = fullfile( ...
    package_root, ...
    '09_Verification_and_Validation');

if ~exist(package_root,'dir')
    error('FINAL_WRITEUP_RESULTS folder does not exist.');
end

if ~exist(vv_folder,'dir')
    mkdir(vv_folder);
end

fprintf('\n');
fprintf('====================================================\n');
fprintf('FINAL V&V PACKAGE PATCH\n');
fprintf('====================================================\n');

%% ------------------------------------------------
% 1. Sphere validation
% -------------------------------------------------

sphere_patterns = { ...
    '*sphere*validation*.csv'
    '*sphere*validation*.mat'
    '*sphere*validation*.png'
    '*sphere*.csv'
    '*sphere*.mat'
    '*sphere*.png'
    };

fprintf('\nSearching for sphere validation evidence...\n');

copy_recursive_patterns( ...
    source_root, ...
    vv_folder, ...
    sphere_patterns);

%% ------------------------------------------------
% 2. Shadow-OFF small-angle diagnostic
% -------------------------------------------------

shadow_patterns = { ...
    'small_angle_shadowOFF_diagnostic.csv'
    '*small_angle*shadowOFF*.csv'
    '*small_angle*shadowOFF*.mat'
    '*small_angle*shadowOFF*.png'
    '*shadowOFF*diagnostic*.csv'
    '*shadowOFF*diagnostic*.mat'
    '*shadowOFF*diagnostic*.png'
    };

fprintf('\nSearching for shadow-OFF diagnostic evidence...\n');

copy_recursive_patterns( ...
    source_root, ...
    vv_folder, ...
    shadow_patterns);

%% ------------------------------------------------
% 3. Run metadata / reproducibility
% -------------------------------------------------

metadata_patterns = { ...
    '*run_metadata*.mat'
    '*metadata*.mat'
    '*analysis_metadata*.mat'
    '*project_metadata*.mat'
    };

fprintf('\nSearching for run metadata...\n');

copy_recursive_patterns( ...
    source_root, ...
    vv_folder, ...
    metadata_patterns);

%% ------------------------------------------------
% Rebuild complete manifest
% -------------------------------------------------

all_files = dir( ...
    fullfile( ...
        package_root, ...
        '**', ...
        '*'));

all_files = ...
    all_files(~[all_files.isdir]);

Category = strings(numel(all_files),1);
File = strings(numel(all_files),1);
RelativePath = strings(numel(all_files),1);

for i = 1:numel(all_files)

    full_name = fullfile( ...
        all_files(i).folder, ...
        all_files(i).name);

    rel = erase( ...
        full_name, ...
        [package_root filesep]);

    RelativePath(i) = string(rel);

    parts = split( ...
        string(rel), ...
        filesep);

    if numel(parts) > 1
        Category(i) = parts(1);
    else
        Category(i) = "Package Root";
    end

    File(i) = string(all_files(i).name);

end

manifest = table( ...
    Category, ...
    File, ...
    RelativePath);

manifest = ...
    sortrows( ...
        manifest, ...
        {'Category','File'});

writetable( ...
    manifest, ...
    fullfile( ...
        package_root, ...
        'results_manifest.csv'));

%% ------------------------------------------------
% Final folder contents
% -------------------------------------------------

vv_files = dir( ...
    fullfile( ...
        vv_folder, ...
        '*'));

vv_files = ...
    vv_files(~[vv_files.isdir]);

fprintf('\n');
fprintf('====================================================\n');
fprintf('09_Verification_and_Validation CONTENTS\n');
fprintf('====================================================\n');

for i = 1:numel(vv_files)
    fprintf('%s\n', vv_files(i).name);
end

fprintf('\n');
fprintf('====================================================\n');
fprintf('FINAL RESULTS ARCHIVE CLOSED\n');
fprintf('====================================================\n');

fprintf('Package:\n%s\n', package_root);

fprintf('\nNo further simulations required.\n');
fprintf('Ready for dissertation writing.\n');

%% ================================================================
% LOCAL FUNCTION
% ================================================================

function copy_recursive_patterns(source_root,destination,patterns)

already_copied = strings(0,1);

for p = 1:numel(patterns)

    matches = dir( ...
        fullfile( ...
            source_root, ...
            '**', ...
            patterns{p}));

    for k = 1:numel(matches)

        if matches(k).isdir
            continue
        end

        filename = matches(k).name;
        lower_name = lower(filename);

        % Exclude old geometry-development results
        reject = ...
            contains(lower_name,'v02') || ...
            contains(lower_name,'v04') || ...
            contains(lower_name,'v05') || ...
            contains(lower_name,'v06') || ...
            contains(lower_name,'v07');

        if reject
            continue
        end

        if any(already_copied == string(filename))
            continue
        end

        source_file = fullfile( ...
            matches(k).folder, ...
            filename);

        destination_file = fullfile( ...
            destination, ...
            filename);

        copyfile( ...
            source_file, ...
            destination_file);

        already_copied(end+1,1) = ...
            string(filename);

        fprintf('Copied: %s\n', filename);

    end

end

end