function [selectedBands, aucValue] = run_mobs_td(matFile, numBands)
% RUN_MOBS_TD robust wrapper that supports main() as script or function.
% Saves last_result.mat and writes mobs_td_progress.log

if nargin < 1 || isempty(matFile)
    matFile = 'hydice_urban_162.mat';
end
if nargin < 2 || isempty(numBands)
    numBands = 10;
end

logfile = fullfile(pwd,'mobs_td_progress.log');
try fid = fopen(logfile,'w'); if fid>0, fprintf(fid,'MOBS-TD run started: %s\n', datestr(now)); fclose(fid); end; catch, end
logf('Starting MOBS-TD wrapper. Loading %s, k=%d', matFile, numBands);

% load dataset (so main can find it if it expects variables in workspace)
if exist(matFile,'file')
    try
        data = load(matFile);
        logf('Loaded matfile %s', matFile);
    catch
        logf('Failed to load matfile %s', matFile);
        data = struct();
    end
else
    logf('matfile %s not found - continuing (main may load its own files).', matFile);
    data = struct();
end

selectedBands = [];
aucValue = NaN;

% 1) Try calling main as a function main(data,numBands)
try
    logf('Attempting to call main(data, numBands) ...');
    out = main(data, double(numBands)); %#ok<NASGU,NBRAK>
    % Interpret common return formats:
    if isstruct(out)
        if isfield(out,'selectedBands'), selectedBands = out.selectedBands; end
        if isfield(out,'auc'), aucValue = out.auc; end
    elseif isnumeric(out)
        % numeric vector -> selected bands
        selectedBands = out(:)';
    end
catch ME1
    logf('main(data,k) failed: %s', ME1.message);
    % 2) Try calling main() (function with no args)
    try
        logf('Attempting to call main() with no args (fallback) ...');
        main();
        % now try to fetch typical var names from base workspace
        selectedBands = try_get_var_from_base({'selectedBands','result_selected','best_sol','sel','selected'});
        aucValue = try_get_var_from_base({'auc','result_auc','aucValue','best_auc'});
    catch ME2
        logf('main() call failed: %s', ME2.message);
        % 3) If main is a script, execute it in base workspace using evalin
        try
            logf('Attempting to run main as a script in base workspace (evalin) ...');
            evalin('base','main');
            selectedBands = try_get_var_from_base({'selectedBands','result_selected','best_sol','sel','selected'});
            aucValue = try_get_var_from_base({'auc','result_auc','aucValue','best_auc'});
        catch ME3
            logf('Script fallback failed: %s', ME3.message);
        end
    end
end

% Final check and save results
if isempty(selectedBands), selectedBands = []; end
if isempty(aucValue) || ~isnumeric(aucValue), aucValue = NaN; end

% Save result for UI
try
    s.selectedBands = selectedBands(:)';
    s.aucValue = double(aucValue);
    s.timestamp = datestr(now);
    save('last_result.mat','-struct','s');
    logf('Saved last_result.mat -> bands: %s, auc=%.4f', mat2str(s.selectedBands), s.aucValue);
catch MEs
    logf('Failed to save last_result.mat: %s', MEs.message);
end

logf('MOBS-TD wrapper finished.');
end

% ----------------- helpers -----------------
function logf(fmt,varargin)
    try
        tline = sprintf(['[%s] ' fmt '\n'], datestr(now), varargin{:});
        fid = fopen(logfile,'a');
        if fid>0, fwrite(fid,tline); fclose(fid); end
    catch
    end
end

function val = try_get_var_from_base(names)
    val = [];
    for i=1:numel(names)
        nm = names{i};
        try
            if evalin('base',sprintf('exist(''%s'',''var'')',nm))
                t = evalin('base', nm);
                val = t;
                return;
            end
        catch
        end
    end
end
