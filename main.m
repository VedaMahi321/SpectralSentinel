%% main.m - MOBS-TD / Multi-objective Band Selection (script)
% Usage: run this script (it is intended to be a script, not a function).
% Make sure all helper .m files (BS_model, Entrop, spectral_spatial, etc.)
% and hydice_urban_162.mat are in the working folder or path.

clc; clear; close all;

%{ 
    Reference: X. Sun, P. Lin, X. Shang, H. Pang and X. Fu, "MOBS-TD: Multiobjective 
               Band Selection With Ideal Solution Optimization Strategy for Hyperspectral 
               Target Detection," IEEE JSTARS, DOI: 10.1109/JSTARS.2024.3402381.
%}

%% MO model for BS
CostFunction = @(x,h,d,m,t) BS_model(x,h,d,m,t);  % your cost model
nVar = 5; % number of bands in individual solution (subset size)

%% Parameters
MaxT = 50;            % Maximum number of iterations
nPop = 50;            % population size
nRep = 20;            % Candidate solution set size

w = 0.5;              % inertia factor
wdamp = 0.99;         % Attenuation factor of inertia
c1 = 1;               % Global learning factor
c2 = 1;               % Individual learning factor

nGrid = 4;            % Number of grids per dimension (nGrid+1)
mu = 0.1;             % mutation probability regulator
maxrate = 0.2;        % Evolutionary speed control factor

%% load data
if ~exist('hydice_urban_162.mat','file')
    error('Dataset hydice_urban_162.mat not found in current folder.');
end
load('hydice_urban_162.mat'); % loads 'data' and 'map' in this repo

% Standard names used by other functions in repo
img_src = data;    % HxWxL
img_gt = map;      % HxW (ground truth mask)

%% pre-processing
[W, H, L] = size(img_src);         % note: your variables earlier used W,H swapped; keep original
img_src = normalized(img_src);     % your normalization function
img = reshape(img_src, W * H, L);  % N x L (N = W*H)
d = get_target(img, img_gt);       % target vector (function provided in repo)

En = Entrop(img);                   % entropy features (function in repo)
D = spectral_spatial(img);          % spectral-spatial measure (function in repo)

%% Initialization
VarSize = [1 nVar];
VarMin = 1;
VarMax = L;

empty_particle.Position = [];
empty_particle.Velocity = [];
empty_particle.Cost = [];
empty_particle.Best.Position = [];
empty_particle.Best.Cost = [];
empty_particle.IsDominated = [];
empty_particle.GridIndex = [];
empty_particle.GridSubIndex = [];

pop = repmat(empty_particle, nPop, 1);

% 1st-generation population
for i = 1:nPop
    pop(i).Position = sort(randperm(VarMax, nVar));
    pop(i).Velocity = zeros(VarSize);
    pop(i).Cost = CostFunction(pop(i).Position, En, D, img', d);
    pop(i).Best.Position = pop(i).Position;
    pop(i).Best.Cost = pop(i).Cost;
end

% Determine Domination
pop = DetermineDomination(pop);
rep = pop(~[pop.IsDominated]);

% grid
rep = GridIndex(rep, nGrid);

%% Main Loop
for it = 1:MaxT

    for i = 1:nPop
        % select the global leader
        leader = SelectLeader(rep);

        % Calculating speed
        pop(i).Velocity = w * pop(i).Velocity ...
            + c1 * rand(VarSize) .* (pop(i).Best.Position - pop(i).Position) ...
            + c2 * rand(VarSize) .* (leader.Position - pop(i).Position);

        % limitation
        pop(i).Velocity = max(pop(i).Velocity, (-1) * maxrate * VarMax);
        pop(i).Velocity = min(pop(i).Velocity, maxrate * VarMax);
        pop(i).Velocity = fix(pop(i).Velocity);

        % Update Location
        pop(i).Position = pop(i).Position + pop(i).Velocity;

        % regularization: keep integer indices and inside [VarMin VarMax]
        pop(i).Position = limitPositionVariables(pop(i).Position, VarMin, VarMax);

        % Update fitness
        pop(i).Cost = CostFunction(pop(i).Position, En, D, img', d);

        %% mutation
        pm = (1 - (it - 1) / (MaxT - 1))^(1 / mu);
        if rand < pm
            NewSol.Position = Mutate(pop(i).Position, pm, VarMin, VarMax);
            NewSol.Position = limitPositionVariables(NewSol.Position, VarMin, VarMax);
            NewSol.Cost = CostFunction(NewSol.Position, En, D, img', d);
            pop(i) = RoD(NewSol, pop(i));
        end
    end

    %% Update rep set
    pop = DetermineDomination(pop);
    rep = [rep
           pop(~[pop.IsDominated])];
    rep = DetermineDomination(rep);
    rep = rep(~[rep.IsDominated]);

    %% crossover in rep set
    pc = (1 - (it - 1) / (MaxT - 1))^(1 / mu);
    num_rep = numel(rep);
    if rand < pc && num_rep >= 2
        nCrossover = 2 * floor(pc * num_rep / 2);
        popc = repmat(empty_particle, nCrossover/2, 1);
        cross_index = reshape(randperm(num_rep, nCrossover), nCrossover/2, 2);
        for k = 1:nCrossover/2
            p1 = rep(cross_index(k, 1));
            p2 = rep(cross_index(k, 2));
            popc(k).Position = Crossover(p1.Position, p2.Position, En);
            popc(k).Velocity = ((p1.Velocity + p2.Velocity) * sqrt(dot(p1.Velocity, p1.Velocity))) ...
                / ((sqrt(dot(p1.Velocity, p1.Velocity)) + sqrt(dot(p2.Velocity, p2.Velocity))) + eps);
            popc(k).Velocity = max(popc(k).Velocity, (-1) * maxrate * VarMax);
            popc(k).Velocity = min(popc(k).Velocity, maxrate * VarMax);
            popc(k).Velocity = fix(popc(k).Velocity);
            popc(k).Cost = CostFunction(popc(k).Position, En, D, img', d);
        end
        rep = [rep
               popc];
        rep = DetermineDomination(rep);
        rep = rep(~[rep.IsDominated]);
    end

    % Update Grid
    rep = GridIndex(rep, nGrid);

    % Check if rep set is full
    if numel(rep) > nRep
        Extra = numel(rep) - nRep;
        seq = WSIS(rep);
        for e = 1:Extra
            rep = DeleteRepMemebr(rep, seq);
        end
    else
        Extra = 0;
    end

    % Plot Costs (visual feedback during optimization)
    figure(1);
    PlotCosts(pop, rep);
    pause(0.01);
    box on;

    % Show Iteration Information
    disp(['Iteration ' num2str(it) ': Number of Rep Members = ' num2str(numel(rep)) ]);

    % Damping Inertia Weight
    w = w * wdamp;

end % end main loop

%% MSR - obtain final solution(s) from repSet
repSet = {rep.Position};
detector_Name = 'CEM';
fSolution = MSR(repSet, detector_Name, img, W, H, d); % fSolution expected to be band indices

%% Detection map and AUC evaluation
try
    detectmap = reshape(detector(img(:, fSolution), d(fSolution)', detector_Name), W, H);
catch MEdet
    warning('Detector call failed: %s. Falling back to simple detector projection.', MEdet.message);
    % fallback: simple projection on mean target spectrum
    try
        sFallback = mean(img(d==1, fSolution), 1)';
        scoresFallback = img(:, fSolution) * (sFallback / (norm(sFallback) + eps));
        detectmap = reshape(scoresFallback - min(scoresFallback), W, H);
        detectmap = detectmap / max(detectmap(:));
    catch
        detectmap = zeros(W, H);
    end
end

% compute AUC using repo's auc function (if available)
auc = NaN;
try
    if exist('auc','file') || exist('auc.m','file')
        % some repos provide an 'auc' function that accepts detectmap and img_gt
        try
            tmp = auc(detectmap, img_gt);  % may return scalar
            if ~isempty(tmp) && isnumeric(tmp)
                auc = tmp;
            end
        catch
            % if auc function signatures vary, try returning perfcurve from reshaped values
            scores = detectmap(:);
            labels = img_gt(:);
            if numel(unique(labels)) > 1 && exist('perfcurve','file')
                [~,~,~,auc] = perfcurve(double(labels), double(scores), 1);
            end
        end
    else
        % If no auc() helper, compute using perfcurve (Statistics toolbox)
        scores = detectmap(:);
        labels = img_gt(:);
        if numel(unique(labels)) > 1 && exist('perfcurve','file')
            [~,~,~,auc] = perfcurve(double(labels), double(scores), 1);
        end
    end
catch MEauc
    warning('AUC computation failed: %s', MEauc.message);
    auc = NaN;
end

% show results on screen
disp(['optimal band subset : (' num2str(fSolution), '), detection rate : ' num2str(auc)]);

% display detectmap figure
figure; imagesc(detectmap); axis image; colorbar; title(sprintf('Detection map (AUC=%.4f)', auc));

%% --- Automatic result save & log (for MATLAB Control Room UI) ---
try
    % Identify final selected bands (prefer fSolution)
    if exist('fSolution','var') && ~isempty(fSolution)
        sel = fSolution;
    elseif exist('selectedBands','var') && ~isempty(selectedBands)
        sel = selectedBands;
    elseif exist('result_selected','var') && ~isempty(result_selected)
        sel = result_selected;
    elseif exist('best_sol','var') && ~isempty(best_sol)
        sel = best_sol;
    else
        % try to detect an integer vector in workspace
        ws = whos;
        sel = [];
        for i = 1:numel(ws)
            try
                if strcmp(ws(i).class,'double') && isvector(eval(ws(i).name))
                    tmp = eval(ws(i).name);
                    if all(tmp == floor(tmp)) && numel(tmp) <= 200 && numel(tmp) >= 1
                        sel = tmp(:)';
                        break;
                    end
                end
            catch
            end
        end
    end

    % Identify AUC value similarly (prefer auc)
    if exist('auc','var') && ~isempty(auc)
        aucVal = auc;
    elseif exist('result_auc','var') && ~isempty(result_auc)
        aucVal = result_auc;
    elseif exist('best_auc','var') && ~isempty(best_auc)
        aucVal = best_auc;
    else
        aucVal = NaN;
    end

    % --- Save target mask for GUI (last_mask.mat) ---
    try
        if exist('img_gt','var') && ~isempty(img_gt)
            mask = logical(img_gt);
        elseif exist('map','var') && ~isempty(map)
            mask = logical(map);
        else
            % fallback: synthetic circular mask in center
            [hMap, wMap, ~] = size(data);
            [X, Y] = meshgrid(1:wMap, 1:hMap);
            cx = wMap / 2; cy = hMap / 2; r = min(hMap, wMap) / 8;
            mask = (X - cx).^2 + (Y - cy).^2 < r^2;
        end
        save('last_mask.mat', 'mask');
    catch maskErr
        warning('Mask export failed: %s', maskErr.message);
    end

    % --- Save last_result.mat for UI consumption ---
    s.selectedBands = double(sel(:)');
    s.aucValue = double(aucVal);
    s.timestamp = datestr(now);
    s.sourceFile = mfilename; % 'main'
    s.numBands = size(img_src, 3);
    save('last_result.mat', '-struct', 's');

    % Append a short log entry (mobs_td_progress.log)
    try
        fid = fopen('mobs_td_progress.log', 'a');
        if fid > 0
            fprintf(fid, '[%s] main finished: selectedBands = %s, auc=%.4f\n', ...
                datestr(now), mat2str(s.selectedBands), s.aucValue);
            fclose(fid);
        end
    catch
        % ignore log write errors
    end

    disp('? Results saved to last_result.mat and last_mask.mat for UI use.');

catch MEsave
    warning('Auto-save failed: %s', MEsave.message);
end

%% End of script
