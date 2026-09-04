%% prepare_writeup_results.m
%
% Creates a clean, curated results package for dissertation write-up.
%
% IMPORTANT:
% - Original results are NOT moved or deleted.
% - Only copies are placed in the write-up folder.
% - Historical v02/v04/v05/v06/v07 development files are excluded.
% - Raw per-attitude ADBSat files remain in the original archive.
%
% Final geometry:
% disc_lenticular_v03
%
% Final aerodynamic CoM:
% approximately [+6.0, 0, 0] mm

if ~exist('cfg','var')
    project_config
end

clc

%% ================================================================
% PATHS
% ================================================================

source_root = ...
    cfg.paths.project_results_dir;

package_root = fullfile( ...
    source_root, ...
    'FINAL_WRITEUP_RESULTS');

fprintf('\n');
fprintf('====================================================\n');
fprintf('PREPARING FINAL WRITE-UP RESULTS PACKAGE\n');
fprintf('====================================================\n');

fprintf('Source:\n%s\n\n', ...
    source_root);

fprintf('Destination:\n%s\n\n', ...
    package_root);

%% ================================================================
% RECREATE CLEAN PACKAGE
% ================================================================

if exist(package_root,'dir')

    fprintf('Existing FINAL_WRITEUP_RESULTS folder found.\n');
    fprintf('Removing old package and rebuilding it...\n\n');

    rmdir(package_root,'s');

end

mkdir(package_root);

%% ================================================================
% SUBFOLDERS
% ================================================================

folders = { ...
    '01_Geometry_and_Mesh'
    '02_Baseline'
    '03_Operational_Attitude'
    '04_Altitude_and_Environment'
    '05_GSI_and_Accommodation'
    '06_Materials_and_Coatings'
    '07_Stability_and_CoM'
    '08_High_Agility_and_Mass_Properties'
    '09_Verification_and_Validation'
    '10_Final_Figures'
    };

for i = 1:numel(folders)

    mkdir( ...
        fullfile( ...
        package_root, ...
        folders{i}));

end

%% ================================================================
% MANIFEST STORAGE
% ================================================================

manifest_category = {};
manifest_file = {};
manifest_status = {};

%% ================================================================
% 01 GEOMETRY AND MESH
% ================================================================

dest = fullfile( ...
    package_root, ...
    '01_Geometry_and_Mesh');

patterns = { ...
    'mesh_geometry.csv'
    'mesh_convergence_medium_to_fine.csv'
    '*mesh_sensitivity*.csv'
    '*mesh_sensitivity*.mat'
    '*mesh_convergence*.png'
    };

[manifest_category,manifest_file,manifest_status] = ...
    copy_patterns( ...
    source_root, ...
    dest, ...
    patterns, ...
    'Geometry and Mesh', ...
    manifest_category, ...
    manifest_file, ...
    manifest_status);

%% ================================================================
% 02 BASELINE
% ================================================================

dest = fullfile( ...
    package_root, ...
    '02_Baseline');

patterns = { ...
    '*baseline*.csv'
    '*baseline*.mat'
    '*baseline*.png'
    };

[manifest_category,manifest_file,manifest_status] = ...
    copy_patterns( ...
    source_root, ...
    dest, ...
    patterns, ...
    'Baseline', ...
    manifest_category, ...
    manifest_file, ...
    manifest_status);

%% ================================================================
% 03 OPERATIONAL ATTITUDE
% ================================================================

dest = fullfile( ...
    package_root, ...
    '03_Operational_Attitude');

patterns = { ...
    'operational_pitch_sweep.csv'
    '*operational_pitch*.mat'
    '*operational_pitch*.png'
    'sideslip_sweep_results.csv'
    '*sideslip*.mat'
    '*sideslip*.png'
    };

[manifest_category,manifest_file,manifest_status] = ...
    copy_patterns( ...
    source_root, ...
    dest, ...
    patterns, ...
    'Operational Attitude', ...
    manifest_category, ...
    manifest_file, ...
    manifest_status);

%% ================================================================
% 04 ALTITUDE AND ENVIRONMENT
% ================================================================

dest = fullfile( ...
    package_root, ...
    '04_Altitude_and_Environment');

patterns = { ...
    'altitude_sweep_summary.csv'
    '*altitude_sweep*.mat'
    '*altitude_sweep*.png'
    'fmf_check_summary.csv'
    '*fmf_check*.mat'
    '*environment*.csv'
    '*environment*.mat'
    '*environment*.png'
    };

[manifest_category,manifest_file,manifest_status] = ...
    copy_patterns( ...
    source_root, ...
    dest, ...
    patterns, ...
    'Altitude and Environment', ...
    manifest_category, ...
    manifest_file, ...
    manifest_status);

%% ================================================================
% 05 GSI AND ACCOMMODATION
% ================================================================

dest = fullfile( ...
    package_root, ...
    '05_GSI_and_Accommodation');

patterns = { ...
    'gsi_sensitivity_comparison.csv'
    '*gsi_sensitivity*.mat'
    '*gsi_sensitivity*.png'
    'accommodation_sensitivity_sentman.csv'
    '*accommodation_sensitivity*.mat'
    '*accommodation_sensitivity*.png'
    '*accommodation_offnominal*.csv'
    '*accommodation_offnominal*.mat'
    '*accommodation_offnominal*.png'
    };

[manifest_category,manifest_file,manifest_status] = ...
    copy_patterns( ...
    source_root, ...
    dest, ...
    patterns, ...
    'GSI and Accommodation', ...
    manifest_category, ...
    manifest_file, ...
    manifest_status);

%% ================================================================
% 06 MATERIALS AND COATINGS
% ================================================================

dest = fullfile( ...
    package_root, ...
    '06_Materials_and_Coatings');

patterns = { ...
    'material_surface_results.csv'
    '*material_surface*.mat'
    '*material_surface*.png'
    '*surface_comparison*.csv'
    '*surface_comparison*.mat'
    '*surface_comparison*.png'
    };

[manifest_category,manifest_file,manifest_status] = ...
    copy_patterns( ...
    source_root, ...
    dest, ...
    patterns, ...
    'Materials and Coatings', ...
    manifest_category, ...
    manifest_file, ...
    manifest_status);

%% ================================================================
% 07 STABILITY AND CoM
% ================================================================

dest = fullfile( ...
    package_root, ...
    '07_Stability_and_CoM');

patterns = { ...
    'com_xz_optimised_comparison.csv'
    'com_xz_sensitivity_v03.mat'
    '*com_sensitivity_baffle*.csv'
    '*com_sensitivity_baffle*.mat'
    '*com_xz*.png'
    'stability_com_trade_shadowON_data.csv'
    'stability_com_trade_shadowON_summary.mat'
    'stability_com_trade_shadowON.png'
    };

[manifest_category,manifest_file,manifest_status] = ...
    copy_patterns( ...
    source_root, ...
    dest, ...
    patterns, ...
    'Stability and CoM', ...
    manifest_category, ...
    manifest_file, ...
    manifest_status);

%% ================================================================
% 08 HIGH AGILITY AND MASS PROPERTIES
% ================================================================

dest = fullfile( ...
    package_root, ...
    '08_High_Agility_and_Mass_Properties');

patterns = { ...
    'high_agility_aerodynamic_results.csv'
    'high_agility_pitch_results.csv'
    'high_agility_sideslip_results.csv'
    'high_agility_kinematic_requirements.csv'
    'high_agility_assessment_summary.mat'
    'high_agility_aerodynamic_envelope.png'
    'mass_properties_component_model.csv'
    'mass_properties_agility_summary.mat'
    'agility_slew_results.csv'
    'refined_internal_layout.csv'
    'refined_agility_slew_results.csv'
    'refined_internal_layout_agility.mat'
    };

[manifest_category,manifest_file,manifest_status] = ...
    copy_patterns( ...
    source_root, ...
    dest, ...
    patterns, ...
    'High Agility and Mass Properties', ...
    manifest_category, ...
    manifest_file, ...
    manifest_status);

%% ================================================================
% 09 VERIFICATION AND VALIDATION
% ================================================================

dest = fullfile( ...
    package_root, ...
    '09_Verification_and_Validation');

patterns = { ...
    '*framework_self_test*.csv'
    '*framework_self_test*.mat'
    '*self_test*.csv'
    '*self_test*.mat'
    '*sphere*.csv'
    '*sphere*.mat'
    '*sphere*.png'
    'preflight_disc_lenticular_v03*.mat'
    'preflight_disc_lenticular_v03*.csv'
    };

[manifest_category,manifest_file,manifest_status] = ...
    copy_patterns( ...
    source_root, ...
    dest, ...
    patterns, ...
    'Verification and Validation', ...
    manifest_category, ...
    manifest_file, ...
    manifest_status);

%% ================================================================
% 10 FINAL FIGURES
% ================================================================
%
% Collect every final v03 PNG from the result directory.
%
% Historical design variants are excluded below.

dest = fullfile( ...
    package_root, ...
    '10_Final_Figures');

png_files = dir( ...
    fullfile( ...
    source_root, ...
    '*.png'));

for i = 1:numel(png_files)

    filename = ...
        png_files(i).name;

    filename_lower = ...
        lower(filename);

    %% Exclude development geometries

    reject = ...
        contains(filename_lower,'v02') || ...
        contains(filename_lower,'v04') || ...
        contains(filename_lower,'v05') || ...
        contains(filename_lower,'v06') || ...
        contains(filename_lower,'v07');

    if reject
        continue
    end

    copyfile( ...
        fullfile( ...
            png_files(i).folder, ...
            filename), ...
        fullfile( ...
            dest, ...
            filename));

    manifest_category{end+1,1} = ...
        'Final Figures';

    manifest_file{end+1,1} = ...
        filename;

    manifest_status{end+1,1} = ...
        'Copied';

end

%% ================================================================
% COPY FINAL MODEL REFERENCE
% ================================================================
%
% Include the final model MAT as geometry provenance.
% This is NOT an aerodynamic result but makes the package traceable.

final_model = fullfile( ...
    cfg.paths.model_dir, ...
    'disc_lenticular_v03.mat');

if isfile(final_model)

    copyfile( ...
        final_model, ...
        fullfile( ...
            package_root, ...
            '01_Geometry_and_Mesh', ...
            'disc_lenticular_v03.mat'));

    manifest_category{end+1,1} = ...
        'Geometry and Mesh';

    manifest_file{end+1,1} = ...
        'disc_lenticular_v03.mat';

    manifest_status{end+1,1} = ...
        'Copied';

else

    warning( ...
        'Final model MAT not found: %s', ...
        final_model);

end

%% ================================================================
% BUILD MANIFEST
% ================================================================

manifest = table( ...
    string(manifest_category), ...
    string(manifest_file), ...
    string(manifest_status), ...
    'VariableNames', { ...
    'Category', ...
    'File', ...
    'Status'});

%% Remove duplicate manifest rows

manifest = ...
    unique( ...
    manifest, ...
    'rows', ...
    'stable');

%% Sort by category then filename

manifest = ...
    sortrows( ...
    manifest, ...
    {'Category','File'});

writetable( ...
    manifest, ...
    fullfile( ...
        package_root, ...
        'results_manifest.csv'));

%% ================================================================
% WRITE FINAL KEY RESULTS CSV
% ================================================================
%
% These are the agreed headline values for the write-up.
%
% This is intentionally small and contains only established final
% quantities rather than every intermediate result.

Metric = [ ...
    "Final geometry"
    "Fine mesh panel count"
    "Fine mesh reference length"
    "Fine mesh reference area"
    "Design X CoM"
    "Nominal altitude"
    "Nominal drag"
    "Nominal CMy"
    "Nominal My"
    "Operational drag variation"
    "Operational max absolute My"
    "Altitude drag ratio 200 to 400 km"
    "Minimum FMF Knudsen number"
    "Maximum Sentman-CLL drag difference"
    "Maximum off-nominal accommodation drag increase"
    "Local shadow-ON dCMy/dalpha at +6 mm"
    "Local-neutral X CoM shadow ON"
    "High-agility maximum drag ratio"
    "High-agility maximum total aerodynamic moment"
    "Refined conceptual wet mass"
    "Nominal agility mass"
    "Refined nominal Ixx"
    "Refined nominal Iyy"
    "Refined nominal Izz"
    "30 degree pitch slew time at assumed 6.5 mNm"
    "30 degree pitch peak rate at assumed 6.5 mNm"
    "VHR benchmark pitch torque for 4.5 deg/s"
    "VHR benchmark pitch momentum at 4.5 deg/s"
    ];

Value = [ ...
    "disc_lenticular_v03"
    "8800"
    "0.9996521 m"
    "0.84376298 m^2"
    "+6.0 mm"
    "300 km"
    "3.86848e-05 N"
    "+1.13752e-03"
    "+1.47831e-07 N m"
    "3.3926 x"
    "2.37e-07 N m"
    "383.206 x"
    "398.9"
    "0.514 %"
    "21.85 %"
    "+1.3410e-02 rad^-1"
    "+34.5 mm"
    "6.670 x"
    "1.54822e-06 N m"
    "45.5 kg"
    "50 kg"
    "2.17642 kg m^2"
    "2.21533 kg m^2"
    "4.33658 kg m^2"
    "26.72 s"
    "2.246 deg/s"
    "26.10 mN m"
    "0.17399 N m s"
    ];

Notes = [ ...
    "Frozen external geometry"
    "Final fine mesh"
    "Tessellated value"
    "ADBSat reference area"
    "Conceptual internal layout target"
    "Quiet baseline environment"
    "AoA 0 deg, AoS 0 deg, Sentman alpha=1"
    "About +6 mm design CoM"
    "About +6 mm design CoM"
    "Across operational +/-30 deg pitch envelope"
    "Operational +/-30 deg sweep; occurs near -15 deg"
    "Nominal attitude"
    "200 km"
    "Fully accommodating GSI comparison"
    "Sentman alpha 1 to 0.4 at +/-30 deg"
    "Six non-zero small-angle shadow-ON points"
    "Local derivative neutralisation, not zero CMy"
    "Extended +/-90 deg high-agility envelope"
    "At AoA -90 deg, 300 km"
    "Explicit subsystem build-up"
    "Rounded sensitivity case"
    "50 kg scaled refined layout"
    "50 kg scaled refined layout"
    "50 kg scaled refined layout"
    "Concept-level actuator assumption"
    "Concept-level actuator assumption"
    "Upper-bound VHR-class benchmark"
    "Upper-bound VHR-class benchmark"
    ];

key_results = table( ...
    Metric, ...
    Value, ...
    Notes);

writetable( ...
    key_results, ...
    fullfile( ...
        package_root, ...
        'final_key_results.csv'));

%% ================================================================
% FINAL AUDIT OF PACKAGE
% ================================================================

all_files = dir( ...
    fullfile( ...
        package_root, ...
        '**', ...
        '*'));

all_files = ...
    all_files(~[all_files.isdir]);

fprintf('\n');
fprintf('====================================================\n');
fprintf('FINAL WRITE-UP PACKAGE COMPLETE\n');
fprintf('====================================================\n');

fprintf('Total packaged files: %d\n', ...
    numel(all_files));

fprintf('\nPackage location:\n%s\n', ...
    package_root);

fprintf('\nImportant files at package root:\n');
fprintf('  results_manifest.csv\n');
fprintf('  final_key_results.csv\n');

fprintf('\nHistorical development geometries were not copied.\n');

fprintf(['Original working results remain untouched in the ' ...
    'project results directory.\n']);

fprintf('\nREADY FOR DISSERTATION WRITE-UP.\n');

%% ================================================================
% LOCAL FUNCTION
% ================================================================

function [categories,files,statuses] = ...
    copy_patterns( ...
    source_root, ...
    destination, ...
    patterns, ...
    category, ...
    categories, ...
    files, ...
    statuses)

for p = 1:numel(patterns)

    matches = dir( ...
        fullfile( ...
            source_root, ...
            patterns{p}));

    for k = 1:numel(matches)

        if matches(k).isdir
            continue
        end

        filename = ...
            matches(k).name;

        filename_lower = ...
            lower(filename);

        %% Reject historical design-development files

        reject = ...
            contains(filename_lower,'disc_lenticular_v02') || ...
            contains(filename_lower,'disc_lenticular_v04') || ...
            contains(filename_lower,'disc_lenticular_v05') || ...
            contains(filename_lower,'disc_lenticular_v06') || ...
            contains(filename_lower,'disc_lenticular_v07') || ...
            contains(filename_lower,'v04_balance');

        if reject
            continue
        end

        source_file = ...
            fullfile( ...
                matches(k).folder, ...
                filename);

        destination_file = ...
            fullfile( ...
                destination, ...
                filename);

        copyfile( ...
            source_file, ...
            destination_file);

        categories{end+1,1} = ...
            category;

        files{end+1,1} = ...
            filename;

        statuses{end+1,1} = ...
            'Copied';

    end

end

end