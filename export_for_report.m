% export_for_report.m
% Automatically creates report images with algorithm + date in filename

clear; close all; clc;
proj = 'D:\MOBS-TD-Hyperspectral-Band-Selection-main\MOBS-TD-Hyperspectral-Band-Selection-main';
cd(proj);
addpath(genpath(pwd));

fprintf('\n=== Export for Report (auto-timestamped) ===\n');

% Load results
if exist('last_result.mat','file')
    R = load('last_result.mat');
else
    error('last_result.mat not found. Run main.m or GUI first.');
end

% Try to load mask
if exist('last_mask.mat','file')
    M = load('last_mask.mat'); 
    mask = M.mask;
else
    mask = []; 
    warning('last_mask.mat not found; mask empty');
end

% Determine algorithm name (if stored, else fallback)
if isfield(R, 'algorithm')
    algName = R.algorithm;
elseif isfield(R, 'alg') || isfield(R, 'algUsed')
    algName = R.alg;
else
    algName = 'UnknownAlg';
end
algName = strrep(algName, ' ', '_'); % clean up spaces

% Create timestamp string
stamp = datestr(now,'yyyymmdd_HHMMSS');

% Load produced images if available
heatname = dir('heatmap_*.png');
bandsname = dir('bands_*.png');
paretoname = dir('pareto_*.png');

if ~isempty(heatname); heatfile = heatname(end).name; else heatfile=''; end
if ~isempty(bandsname); bandsfile = bandsname(end).name; else bandsfile=''; end
if ~isempty(paretoname); paretofile = paretoname(end).name; else paretofile=''; end

% Create combined figure layout
f = figure('Color','w','Position',[100 100 1400 900]);
t = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

% --- Left large: Heatmap
ax1 = nexttile([2 1]);
if ~isempty(heatfile)
    I = imread(heatfile);
    imshow(I);
    title(sprintf('Detection Heatmap (%s, AUC=%s)', algName, num2str(R.aucValue,'%0.3f')));
else
    text(0.2,0.5,'No heatmap available','FontSize',14);
    axis off;
end

% --- Top-right: Bands
ax2 = nexttile;
if ~isempty(bandsfile)
    Ib = imread(bandsfile);
    imshow(Ib);
    title('Spectral plot & selected bands');
else
    text(0.3,0.5,'Bands figure missing','FontSize',12);
    axis off;
end

% --- Bottom-right: Pareto
ax3 = nexttile;
if ~isempty(paretofile)
    Ip = imread(paretofile);
    imshow(Ip);
    title('Pareto front');
else
    text(0.3,0.5,'Pareto figure missing','FontSize',12);
    axis off;
end

% --- Save combined figure with algorithm + timestamp
combinedName = sprintf('figure_combined_%s_%s.png', algName, stamp);
saveas(f, fullfile(proj, combinedName));
fprintf('Saved combined figure: %s\n', combinedName);

% --- Copy or rename originals with algorithm + timestamp
if ~isempty(heatfile)
    copyfile(heatfile, fullfile(proj, sprintf('heatmap_report_%s_%s.png', algName, stamp)));
end
if ~isempty(bandsfile)
    copyfile(bandsfile, fullfile(proj, sprintf('bands_report_%s_%s.png', algName, stamp)));
end
if ~isempty(paretofile)
    copyfile(paretofile, fullfile(proj, sprintf('pareto_report_%s_%s.png', algName, stamp)));
end

% --- Save summary data
selectedBands = R.selectedBands;
aucValue = R.aucValue;
timestamp = R.timestamp;
algorithm = algName;

save(fullfile(proj, sprintf('report_data_%s_%s.mat', algName, stamp)), ...
     'selectedBands','aucValue','timestamp','algorithm');

fprintf('Export complete.\n');
fprintf('Algorithm: %s | AUC=%.4f | Time=%s\n', algName, aucValue, timestamp);
