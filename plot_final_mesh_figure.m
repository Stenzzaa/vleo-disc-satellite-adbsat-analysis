clear
clc
close all

project_config

%% ================================================================
% FINAL OBJ FILE
% ================================================================

objFile = fullfile( ...
    cfg.paths.obj_dir, ...
    [cfg.model.name '.obj']);

if ~isfile(objFile)
    error('OBJ file not found: %s', objFile);
end

fprintf('Loading:\n%s\n\n', objFile);

%% ================================================================
% READ OBJ MESH
% ================================================================

[V,F] = read_obj_mesh(objFile);

fprintf('Vertices: %d\n', size(V,1));
fprintf('Panels:   %d\n', size(F,1));

%% ================================================================
% ROTATE FOR DISPLAY ONLY
% ================================================================
%
% Rotate 180 degrees about the X-axis so that the telescope/baffle
% appears on the lower, nadir-facing side in the dissertation figure.
%
% IMPORTANT:
% This does NOT alter the OBJ file or aerodynamic model.

Vplot = V;

Vplot(:,2) = -V(:,2);
Vplot(:,3) = -V(:,3);

%% ================================================================
% PLOT FINAL SURFACE MESH
% ================================================================

fig = figure( ...
    'Color','w', ...
    'Position',[100 100 1200 850]);

trisurf( ...
    F, ...
    Vplot(:,1), ...
    Vplot(:,2), ...
    Vplot(:,3), ...
    'FaceColor',[0.92 0.92 0.92], ...
    'EdgeColor','k', ...
    'LineWidth',0.20);

axis equal
axis off

% Clean isometric view
view(135,25);

camproj('orthographic');

lighting gouraud
camlight('headlight');

%% ================================================================
% EXPORT DISSERTATION FIGURE
% ================================================================

outputFile = fullfile( ...
    cfg.paths.project_results_dir, ...
    'Figure_3_4_final_mesh.png');

exportgraphics( ...
    fig, ...
    outputFile, ...
    'Resolution',600, ...
    'BackgroundColor','white');

fprintf('\nSaved figure to:\n%s\n', outputFile);

%% ================================================================
% LOCAL FUNCTION
% ================================================================

function [V,F] = read_obj_mesh(filename)

    lines = readlines(filename);

    V = zeros(0,3);
    F = zeros(0,3);

    for i = 1:numel(lines)

        line = strtrim(lines(i));

        if startsWith(line,"v ")

            values = sscanf(line,'v %f %f %f');

            V(end+1,:) = values(1:3)';

        elseif startsWith(line,"f ")

            parts = split(line);
            parts = parts(2:end);

            idx = zeros(1,numel(parts));

            for j = 1:numel(parts)

                token = split(parts(j),'/');

                idx(j) = str2double(token(1));

            end

            % OBJ is expected to be triangular.
            % Fan triangulation is retained for robustness.
            for j = 2:(numel(idx)-1)

                F(end+1,:) = ...
                    [idx(1), idx(j), idx(j+1)];

            end

        end

    end

end