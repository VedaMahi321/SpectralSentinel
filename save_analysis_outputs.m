function save_analysis_outputs(algorithmName, selectedBands, aucValue, heatmap, scores, redundancy, paretoIdx, mask, figHandle)
% SAVE_ANALYSIS_OUTPUTS Save figures and results for report (timestamped).
% Usage:
%   save_analysis_outputs(algorithmName, selectedBands, aucValue, heatmap, scores, redundancy, paretoIdx, mask, figHandle)
%
% - algorithmName: string label like 'Fisher' or 'MOBS-TD'
% - selectedBands: vector of selected band indices
% - aucValue: numeric AUC (or NaN)
% - heatmap: HxW numeric matrix (detection map). If empty, function will attempt fallback.
% - scores: 1xB vector of band scores (may be empty)
% - redundancy: 1xB vector (may be empty)
% - paretoIdx: indices of Pareto points in the scores/redundancy arrays (may be empty)
% - mask: binary ground-truth mask (optional) to save last_mask.mat
% - figHandle: optional UI/figure handle for snapshot. If empty, a combined figure is still produced.

% --- Safety and defaults ---
if nargin < 1 || isempty(algorithmName), algorithmName = 'ALG'; end
if nargin < 2, selectedBands = []; end
if nargin < 3 || isempty(aucValue), aucValue = NaN; end
if nargin < 4, heatmap = []; end
if nargin < 5, scores = []; end
if nargin < 6, redundancy = []; end
if nargin < 7, paretoIdx = []; end
if nargin < 8, mask = []; end
if nargin < 9, figHandle = []; end

% sanitize name for filenames
safeAlg = regexprep(algorithmName,'[^\w\-]','_');

timestamp = datestr(now,'yyyymmdd_HHMMSS');

outPrefix = sprintf('%s_%s', safeAlg, timestamp);
resultsMat = fullfile(pwd, ['results_' timestamp '.mat']);

% --- Save numeric results ---
try
    selectedBands_save = selectedBands(:)';
    aucVal_save = double(aucValue);
    redundancy_save = redundancy;
    scores_save = scores;
    paretoIdx_save = paretoIdx;
    tstamp = datestr(now);
    save(resultsMat,'selectedBands_save','aucVal_save','redundancy_save','scores_save','paretoIdx_save','tstamp');
catch ME
    warning('Failed to save results mat: %s', ME.message);
end

% Save last_result.mat for UI compatibility
try
    s.selectedBands = selectedBands(:)';
    s.aucValue = double(aucValue);
    s.timestamp = datestr(now);
    save('last_result.mat','-struct','s');
catch
    warning('Could not write last_result.mat');
end

% Save last_mask.mat if mask provided
if ~isempty(mask)
    try
        save('last_mask.mat','mask');
    catch
        warning('Could not write last_mask.mat');
    end
end

% --- Heatmap image ---
heatfile = fullfile(pwd, [outPrefix '_heatmap.png']);
try
    if ~isempty(heatmap)
        hfig = figure('Visible','off','Units','pixels','Position',[100 100 600 500]);
        imagesc(heatmap); axis image off; colormap(gca, turbo);
        title(sprintf('%s Detection Heatmap (AUC=%0.3f)', algorithmName, double(aucValue)), 'Interpreter', 'none');
        % colorbar
        try colorbar('eastoutside'); catch, end

        % export
        try
            exportgraphics(hfig, heatfile, 'Resolution',150);
        catch
            saveas(hfig, heatfile);
        end
        close(hfig);
    else
        % fallback: create blank placeholder heatmap
        blank = ones(300,300,3) * 0.95;
        imwrite(blank, heatfile);
    end
catch ME
    warning('Could not create heatmap image: %s', ME.message);
end

% --- Bands plot image ---
bandsfile = fullfile(pwd, [outPrefix '_bands.png']);
try
    if ~isempty(scores)
        hfig = figure('Visible','off','Units','pixels','Position',[100 100 800 300]);
        plot(scores, '-o','LineWidth',1.2); hold on;
        xlabel('Band index'); ylabel('Score');
        title(sprintf('%s Band Scores and Selected Bands', algorithmName), 'Interpreter', 'none');
        ylim([min(scores)-0.02 max(scores)+0.02]);
        % mark selected bands
        for b = selectedBands
            if b>=1 && b<=numel(scores)
                xline(b,'--r','LineWidth',1);
                text(b, max(scores), num2str(b),'Rotation',90,'Color','r','HorizontalAlignment','center','FontSize',8);
            end
        end
        grid on;
        try
            exportgraphics(hfig, bandsfile, 'Resolution',150);
        catch
            saveas(hfig, bandsfile);
        end
        close(hfig);
    else
        blank = ones(200,400,3) * 0.98;
        imwrite(blank, bandsfile);
    end
catch ME
    warning('Could not create bands image: %s', ME.message);
end

% --- Pareto plot image ---
paretofile = fullfile(pwd, [outPrefix '_pareto.png']);
try
    if ~isempty(redundancy) && ~isempty(scores)
        hfig = figure('Visible','off','Units','pixels','Position',[100 100 600 400]);
        scatter(redundancy, scores, 36, 'b','filled'); hold on;
        if ~isempty(paretoIdx)
            scatter(redundancy(paretoIdx), scores(paretoIdx), 80, 'g','filled');
            plot(redundancy(paretoIdx), scores(paretoIdx), '-g','LineWidth',1.5);
        end
        xlabel('Redundancy'); ylabel('Score / Separability');
        title(sprintf('%s Pareto (Redundancy vs Score)', algorithmName), 'Interpreter', 'none');
        grid on;
        try
            exportgraphics(hfig, paretofile, 'Resolution',150);
        catch
            saveas(hfig, paretofile);
        end
        close(hfig);
    else
        blank = ones(300,300,3) * 0.97;
        imwrite(blank, paretofile);
    end
catch ME
    warning('Could not create pareto image: %s', ME.message);
end

% --- Combined figure (tiled) ---
combinedFile = fullfile(pwd, sprintf('figure_combined_%s_%s.png', safeAlg, timestamp));
try
    cf = figure('Visible','off','Units','pixels','Position',[50 50 1400 900]);
    t = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

    % left large heatmap
    ax1 = nexttile([2 1]);
    if exist(heatfile,'file')
        I = imread(heatfile);
        imshow(I,'Parent',ax1); axis(ax1,'off');
    else
        if ~isempty(heatmap)
            imagesc(ax1,heatmap); axis(ax1,'image'); colormap(ax1,turbo);
        else
            text(ax1,0.1,0.5,'No heatmap','FontSize',12);
            axis(ax1,'off');
        end
    end
    title(ax1, sprintf('%s Detection Heatmap (AUC=%0.3f)', algorithmName, double(aucValue)), 'Interpreter', 'none');

    % top-right bands
    ax2 = nexttile;
    if exist(bandsfile,'file')
        Ib = imread(bandsfile);
        imshow(Ib,'Parent',ax2); axis(ax2,'off');
    elseif ~isempty(scores)
        plot(ax2, scores, '-o'); hold(ax2,'on');
        for b = selectedBands
            if b>=1 && b<=numel(scores)
                xline(ax2,b,'--r');
            end
        end
        hold(ax2,'off');
    else
        text(ax2,0.1,0.5,'Bands figure missing','FontSize',12);
        axis(ax2,'off');
    end
    title(ax2, 'Band Scores & Selection', 'Interpreter', 'none');

    % bottom-right pareto
    ax3 = nexttile;
    if exist(paretofile,'file')
        Ip = imread(paretofile);
        imshow(Ip,'Parent',ax3); axis(ax3,'off');
    elseif ~isempty(redundancy) && ~isempty(scores)
        scatter(ax3, redundancy, scores, 36, 'b','filled'); hold(ax3,'on');
        if ~isempty(paretoIdx)
            scatter(ax3, redundancy(paretoIdx), scores(paretoIdx), 80, 'g','filled');
        end
        hold(ax3,'off');
    else
        text(ax3,0.1,0.5,'Pareto missing','FontSize',12);
        axis(ax3,'off');
    end
    title(ax3, 'Pareto / Redundancy', 'Interpreter', 'none');

    % save combined
    try
        exportgraphics(cf, combinedFile, 'Resolution',150);
    catch
        saveas(cf, combinedFile);
    end
    close(cf);
catch ME
    warning('Could not create combined figure: %s', ME.message);
end

% --- UI snapshot if figHandle provided ---
if ~isempty(figHandle) && ishandle(figHandle)
    try
        uiSnapFile = fullfile(pwd, sprintf('%s_%s_ui-snapshot.png', safeAlg, timestamp));
        F = getframe(figHandle);
        imwrite(F.cdata, uiSnapFile);
    catch
        % ignore snapshot failures
    end
end

% --- report_data.mat (small summary) ---
try
    selectedBands = selectedBands(:)';
    aucValue = double(aucValue);
    timestamp = datestr(now);
    save('report_data.mat','selectedBands','aucValue','timestamp');
catch
    warning('Could not save report_data.mat');
end

fprintf('Saved results to %s and images: %s, %s, %s, combined: %s\n', resultsMat, heatfile, bandsfile, paretofile, combinedFile);
end
