function control_room_matlab()
% CONTROL_ROOM_MATLAB - Hyperspectral Control Room UI (full rewrite)
% Place this file in the same folder as your MOBS-TD code and helper functions:
%   run_mobs_td.m, pareto_front.m, generate_synthetic_scene.m,
%   fisher_scores.m, jm_distance.m, greedy_selection.m, simulate_detection.m
%
% Usage:
%   control_room_matlab

% ---------------- UI setup ----------------
fig = uifigure('Name','Hyperspectral Control Room','Position',[50 50 1280 780]);

% Top controls
uilabel(fig,'Text','Algorithm:','Position',[20 740 70 22]);
ddAlg = uidropdown(fig,'Items',{'Fisher','JM','Greedy','MOBS-TD (MATLAB)'},...
    'Position',[95 740 220 24],'Value','Fisher');

uilabel(fig,'Text','SNR (dB):','Position',[340 740 60 22]);
sldSNR = uislider(fig,'Position',[405 750 260 3],'Limits',[5 40],'Value',20);

uilabel(fig,'Text','Shift:','Position',[690 740 40 22]);
sldShift = uislider(fig,'Position',[740 750 260 3],'Limits',[-0.2 0.2],'Value',0);

uilabel(fig,'Text','Total Bands:','Position',[20 700 80 22]);
edB = uieditfield(fig,'numeric','Value',80,'Position',[110 700 70 24]);

uilabel(fig,'Text','Select k:','Position',[200 700 60 22]);
edK = uieditfield(fig,'numeric','Value',10,'Position',[260 700 60 24]);

uilabel(fig,'Text','Preselect m (0=no preselect):','Position',[340 700 170 22]);
edM = uieditfield(fig,'numeric','Value',30,'Position',[520 700 80 24]);

btnRun = uibutton(fig,'push','Text','Run Analysis',...
    'Position',[620 688 120 36],'ButtonPushedFcn',@(btn,event) runCallback());

lblStatus = uilabel(fig,'Text','Ready','Position',[760 700 480 24],'FontWeight','bold');

% Progress log box (top-right, above plots)
txtLog = uitextarea(fig,'Position',[980 560 280 200],'Editable','off','Value',{'MOBS-TD progress will appear here...'});
txtLog.FontName = 'Courier New';
txtLog.FontSize = 10;

% Axes: heatmap left, scores top-right, pareto bottom-right
axHeat = uiaxes(fig,'Position',[20 120 480 600]); title(axHeat,'Detection Heatmap');
axBands = uiaxes(fig,'Position',[520 420 680 250]); title(axBands,'Band Scores / Selected');
axPareto = uiaxes(fig,'Position',[520 120 680 280]); title(axPareto,'Pareto (Redundancy vs Separability)');

% ---------------- Callback ----------------
    function runCallback()
        lblStatus.Text = 'Running...';
        drawnow;

        % read controls
        alg = ddAlg.Value;
        snr = sldSNR.Value;
        shift = sldShift.Value;
        B = max(1, round(edB.Value));
        k = max(1, round(edK.Value));
        m = max(0, round(edM.Value));  % preselection param

        tStart = tic;
        % generate synthetic scene
        [cube, mask] = generate_synthetic_scene(100,100,B,snr,shift);
        X = reshape(cube, [], B);
        y = reshape(mask, [], 1);

        scores = zeros(1,B);
        selected = [];
        aucVal = NaN;
        scoreLabel = '';

        % shared matfile used by run_mobs_td wrapper (adjust if different)
        matfile = 'hydice_urban_162.mat';

        % ensure any old log/last_result are removed safely
        logfile = fullfile(pwd,'mobs_td_progress.log');
        lastmat = fullfile(pwd,'last_result.mat');
        if exist(logfile,'file'), delete(logfile); end
        if exist(lastmat,'file'), delete(lastmat); end

        switch alg
            case 'Fisher'
                scores = fisher_scores(X,y);
                [~, ord] = sort(scores,'ascend');
                selected = ord(end-k+1:end);
                scoreLabel = 'Fisher Score';

            case 'JM'
                scores = jm_distance(X,y);
                [~, ord] = sort(scores,'ascend');
                selected = ord(end-k+1:end);
                scoreLabel = 'JM Distance';

            case 'Greedy'
                if m > 0 && m < B
                    % preselect top-m by Fisher then greedy on those
                    fScores = fisher_scores(X,y);
                    [~, idxf] = sort(fScores,'descend');
                    preIdx = idxf(1:min(m,B));
                    N = size(X,1);
                    perm = randperm(N);
                    mid = round(N/2);
                    Xtr = X(perm(1:mid), preIdx); ytr = y(perm(1:mid));
                    Xv  = X(perm(mid+1:end), preIdx); yv = y(perm(mid+1:end));
                    [selLocal, bestAUC] = greedy_selection(Xtr,ytr,Xv,yv,k);
                    selected = preIdx(selLocal);
                    aucVal = bestAUC;
                    scores = zeros(1,B);
                    scores(preIdx) = fScores(preIdx);
                    scoreLabel = sprintf('Greedy (preselect %d) (AUC=%.3f)', m, aucVal);
                else
                    % full greedy (may be slow)
                    N = size(X,1);
                    perm = randperm(N);
                    mid = round(N/2);
                    Xtr = X(perm(1:mid),:); ytr = y(perm(1:mid));
                    Xv  = X(perm(mid+1:end),:); yv = y(perm(mid+1:end));
                    [selLocal, bestAUC] = greedy_selection(Xtr,ytr,Xv,yv,k);
                    selected = selLocal;
                    aucVal = bestAUC;
                    scores = zeros(1,B); scores(selected) = 1;
                    scoreLabel = sprintf('Greedy (AUC=%.3f)', aucVal);
                end

            case 'MOBS-TD (MATLAB)'
                lblStatus.Text = 'Running MOBS-TD (MATLAB)...';
                drawnow;
                % Use parfeval if available (background execution)
                usePar = exist('parfeval','file')==2;
                if usePar
                    % ensure a pool exists
                    try
                        pool = gcp('nocreate');
                        if isempty(pool)
                            parpool('local');
                        end
                    catch
                        usePar = false;
                    end
                end

                if usePar
                    % run background and poll logfile
                    f = parfeval(@run_mobs_td, 2, matfile, k);
                    while ~strcmp(f.State,'finished')
                        pause(0.4);
                        if exist(logfile,'file')
                            try
                                txtLog.Value = read_log_tail(logfile, 60);
                            catch
                                % ignore log read errors
                            end
                        end
                        drawnow;
                    end
                    % fetch outputs
                    try
                        [selBands, aucOut] = fetchOutputs(f);
                        selected = selBands(:)';
                        aucVal = aucOut;
                    catch MEf
                        uialert(fig, sprintf('Error fetching MOBS-TD outputs: %s', MEf.message),'MOBS-TD error');
                        lblStatus.Text = 'Error fetching outputs';
                        drawnow;
                        return;
                    end
                else
                    % synchronous call with timer-driven UI polling
                    t = timer('ExecutionMode','fixedSpacing','Period',0.5,'TimerFcn',@(~,~) update_log_ui());
                    start(t);
                    try
                        [selBands, aucOut] = run_mobs_td(matfile, k);
                        selected = selBands(:)';
                        aucVal = aucOut;
                    catch MErun
                        stop(t); delete(t);
                        uialert(fig, sprintf('Error calling run_mobs_td(): %s', MErun.message),'MOBS-TD error');
                        lblStatus.Text = 'Error (see alert)';
                        drawnow;
                        return;
                    end
                    stop(t); delete(t);
                    if exist(logfile,'file')
                        txtLog.Value = read_log_tail(logfile, 200);
                    end
                end

                % set scores vector for plotting
                scores = zeros(1,B);
                for b = selected
                    if b>=1 && b<=B, scores(b) = 1; end
                end
                scoreLabel = sprintf('MOBS-TD (AUC=%.3f)', aucVal);

            otherwise
                scores = fisher_scores(X,y);
                [~, ord] = sort(scores,'ascend');
                selected = ord(end-k+1:end);
                scoreLabel = 'Fisher (fallback)';
        end % switch

        % detection simulation
        try
            [heatmap, detAuc] = simulate_detection(cube, selected, mask);
        catch ME
            warning('simulate_detection failed: %s', ME.message);
            H = size(cube,1); W = size(cube,2);
            heatmap = zeros(H,W);
            detAuc = NaN;
        end

        % Pareto: placeholder redundancy (replace with real redundancy if available)
        redundancy = rand(1,B);
        if numel(redundancy) ~= numel(scores)
            redundancy = rand(1,numel(scores));
        end
        try
            paretoIdx = pareto_front(scores, redundancy);
        catch
            paretoIdx = [];
        end

        % ---------- Safety checks / fallbacks ----------
         % ensure selected is numeric row vector with valid indices
        if isempty(selected) || ~isnumeric(selected)
         % fallback to Fisher top-k
         try
              Xall = reshape(cube, [], size(cube,3));
               fScores = fisher_scores(Xall, reshape(mask,[],1)); %#ok<NASGU>
                [~, idxf] = sort(fScores, 'descend');
                selected = idxf(1:min(k, numel(idxf)));
                        lblStatus.Text = sprintf('Fallback: used Fisher top-%d bands', numel(selected));
          catch
              % last resort: all bands
             selected = 1:size(cube,3);
              lblStatus.Text = 'Fallback: used all bands';
           end
        end

        % ensure indices are within range
        selected = selected(selected >= 1 & selected <= size(cube,3));
        if isempty(selected)
            selected = 1:size(cube,3);
            lblStatus.Text = 'Fallback: selected reset to all bands (index error)';
        end

        % Now call simulate_detection safely
        try
           [heatmap, detAuc] = simulate_detection(cube, selected, mask);
        catch ME
          warning('simulate_detection failed: %s', ME.message);
           % fallback: simple variance saliency
            Xall = reshape(cube, [], size(cube,3));
           scoresFallback = mean(Xall,2);
            scoresFallback = scoresFallback - min(scoresFallback);
           if max(scoresFallback)>0
                scoresFallback = scoresFallback / max(scoresFallback);
            end
            heatmap = reshape(scoresFallback, size(cube,1), size(cube,2));
            detAuc = NaN;
    end


        % ---------- Plotting ----------
        % Heatmap
        cla(axHeat);
        imagesc(axHeat, heatmap);
        axis(axHeat,'image');
        axHeat.YDir = 'normal';
        colormap(axHeat, turbo);
        try
            cb = colorbar(axHeat,'eastoutside'); cb.Label.String = '';
        catch
            colorbar(axHeat);
        end
        title(axHeat, sprintf('Detection Heatmap (AUC=%.3f)', detAuc));
        axHeat.XTick = []; axHeat.YTick = [];

        % Band scores & selected lines
        cla(axBands);
        plot(axBands, scores, '-o', 'MarkerFaceColor','w','LineWidth',1.2);
        hold(axBands,'on');
        ymin = min(scores) - 0.02; ymax = max(scores) + 0.02;
        if ymin==ymax, ymax = ymin + 0.1; end
        ylim(axBands,[ymin ymax]);
        for b = selected
            if b>=1 && b<=numel(scores)
                xline(axBands, b, '--r','LineWidth',1);
                text(axBands, b, ymax - 0.01*(ymax-ymin), num2str(b), 'Rotation',90, 'Color','r',...
                    'HorizontalAlignment','center','FontSize',8);
            end
        end
        hold(axBands,'off');
        title(axBands, scoreLabel);
        xlabel(axBands,'Band Index');

        % Pareto plot
        cla(axPareto);
        scatter(axPareto, redundancy, scores, 36, 'b', 'filled');
        hold(axPareto,'on');
        if ~isempty(paretoIdx)
            plot(axPareto, redundancy(paretoIdx), scores(paretoIdx), '-g', 'LineWidth',2);
            scatter(axPareto, redundancy(paretoIdx), scores(paretoIdx), 80, 'g', 'filled');
        end
        xlabel(axPareto,'Redundancy');
        ylabel(axPareto,'Separability / Score');
        title(axPareto,'Pareto (Redundancy vs Separability)');
        hold(axPareto,'off');

        % status & save
        tElapsed = toc(tStart);
        lblStatus.Text = sprintf('Done (k=%d) | Selected: %s | Time: %.1fs', k, mat2str(selected), tElapsed);

        % Save results and export axes (per-axis PNGs) + snapshot
        try
            % ---------- NEW EXPORT BLOCK (timestamped + algorithm tagging) ----------
            timestamp = datestr(now,'yyyy-mm-dd_HHMMSS');
            fname = fullfile(pwd, ['results_' timestamp '.mat']);
            save(fname,'selected','aucVal','detAuc','scores','redundancy','paretoIdx','tElapsed');

            % Algorithm-safe name
            algSafe = regexprep(alg,'\s+','-');
            stampForName = datestr(now,'yyyymmdd_HHMMSS');

            % Create per-axis report filenames (algorithm + timestamp)
            heat_png = fullfile(pwd, sprintf('%s_%s_heatmap.png', algSafe, stampForName));
            bands_png = fullfile(pwd, sprintf('%s_%s_bands.png', algSafe, stampForName));
            pareto_png = fullfile(pwd, sprintf('%s_%s_pareto.png', algSafe, stampForName));

            % Export axes to those files (use exportgraphics if available)
            try
                if exist('exportgraphics','file')
                    exportgraphics(axHeat, heat_png, 'Resolution',150);
                    exportgraphics(axBands, bands_png, 'Resolution',150);
                    exportgraphics(axPareto, pareto_png, 'Resolution',150);
                else
                    frm = getframe(axHeat); imwrite(frm.cdata, heat_png);
                    frm = getframe(axBands); imwrite(frm.cdata, bands_png);
                    frm = getframe(axPareto); imwrite(frm.cdata, pareto_png);
                end
            catch MEexp
                % last resort capture
                try frm = getframe(axHeat); imwrite(frm.cdata, heat_png); end
                try frm = getframe(axBands); imwrite(frm.cdata, bands_png); end
                try frm = getframe(axPareto); imwrite(frm.cdata, pareto_png); end
                txtLog.Value = [{['Export axes fallback: ' MEexp.message]}; txtLog.Value];
            end

            % UI snapshot (fallback)
            try
                uiSnap = fullfile(pwd, sprintf('%s_%s_ui-snapshot.png', algSafe, stampForName));
                F = getframe(fig);
                imwrite(F.cdata, uiSnap);
            catch
                % ignore
            end

            % Build combined figure: left heatmap, right: bands (top) + pareto (bottom)
            try
                % Read images (use generated images)
                if exist(heat_png,'file'), I1 = imread(heat_png); else I1 = uint8(ones(600,600,3)*255); end
                if exist(bands_png,'file'), I2 = imread(bands_png); else I2 = uint8(ones(300,300,3)*255); end
                if exist(pareto_png,'file'), I3 = imread(pareto_png); else I3 = uint8(ones(300,300,3)*255); end

                % Resize to compose
                targetHeight = size(I1,1);
                rightWidth = round(size(I1,2)/2);
                I2r = imresize(I2, [round(targetHeight/2) rightWidth]);
                I3r = imresize(I3, [round(targetHeight/2) rightWidth]);

                rightCol = cat(1, I2r, I3r);
                if size(rightCol,1) ~= targetHeight
                    rightCol = imresize(rightCol, [targetHeight size(rightCol,2)]);
                end

                combined = cat(2, imresize(I1, [targetHeight size(I1,2)]), rightCol);

                combinedName = fullfile(pwd, sprintf('figure_combined_%s_%s.png', algSafe, stampForName));
                imwrite(combined, combinedName);
                txtLog.Value = [{['Saved combined figure: ' combinedName]}; txtLog.Value];
            catch MEcomb
                txtLog.Value = [{['Combined figure failed: ' MEcomb.message]}; txtLog.Value];
                combinedName = '';
            end

            % Save lightweight report data
            try
                reportDataName = fullfile(pwd, sprintf('report_data_%s_%s.mat', algSafe, stampForName));
                if exist('aucVal','var') && ~isempty(aucVal)
                    aucToSave = aucVal;
                elseif exist('detAuc','var') && ~isempty(detAuc)
                    aucToSave = detAuc;
                else
                    aucToSave = NaN;
                end
                timestampOut = datestr(now,'yyyy-mm-dd HH:MM:SS');
                selectedBands = selected;
                algorithm = alg;
                save(reportDataName,'selectedBands','aucToSave','timestampOut','algorithm');
                txtLog.Value = [{['Saved report data: ' reportDataName]}; txtLog.Value];
            catch MErep
                txtLog.Value = [{['Saving report_data failed: ' MErep.message]}; txtLog.Value];
            end

            fprintf('Saved results to %s and images: %s, %s, %s\n', fname, heat_png, bands_png, pareto_png);
        catch MEsave
            warning('Saving results failed: %s', MEsave.message);
            txtLog.Value = [{['Saving results failed: ' MEsave.message]}; txtLog.Value];
        end

        drawnow;
    end % runCallback

% ---------------- helper functions for log UI ----------------
    function lines = read_log_tail(fname, nlines)
        lines = {'No log yet.'};
        try
            if ~exist(fname,'file'), return; end
            fid = fopen(fname,'r');
            if fid < 0, return; end
            raw = fread(fid, '*char')';
            fclose(fid);
            if isempty(raw), lines = {'(empty)'}; return; end
            C = regexp(raw, '\r\n|\r|\n', 'split');
            if isempty(C), lines = {'(empty)'}; return; end
            startIdx = max(1, length(C)-nlines+1);
            lines = C(startIdx:end);
        catch
            lines = {'(read_log_tail failed)'};
        end
    end

    function update_log_ui()
        logfile_local = fullfile(pwd,'mobs_td_progress.log');
        if exist(logfile_local,'file')
            try
                txt = read_log_tail(logfile_local, 60);
                txtLog.Value = txt;
                drawnow;
            catch
                % ignore log update errors
            end
        end
    end

end % main function
