function mobs_td_log(msg, varargin)
% MOBS_TD_LOG Append a timestamped message to mobs_td_progress.log
%   mobs_td_log('Iteration %d: bestAUC=%.3f', iter, bestAUC)

try
    logfile = fullfile(pwd,'mobs_td_progress.log');
    fid = fopen(logfile,'a');
    if fid < 0, return; end
    tline = sprintf(['[%s] ' msg '\n'], datestr(now), varargin{:});
    fwrite(fid, tline);
    fclose(fid);
catch
    % ignore
end
end
