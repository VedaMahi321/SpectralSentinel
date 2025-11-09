function [heatmap, auc] = simulate_detection(cube, selectedBands, mask)
% Robust simulate_detection: accepts cube HxWxB or empty cube (fallback)
% Returns heatmap (HxW) and auc (NaN if cannot compute)

% Validate cube
if nargin < 1 || isempty(cube)
    error('simulate_detection:MissingCube','Hyperspectral cube is required (cube argument).');
end
if ~isnumeric(cube)
    cube = double(cube);
end

% Spatial and spectral sizes
sz = size(cube);
if numel(sz) == 2
    error('simulate_detection:BadInput','Cube must be HxWxB.');
end
% normalize dimension vector to [H W B]
H = int64(sz(1));
W = int64(sz(2));
if numel(sz) >= 3
    B = int64(sz(3));
else
    B = int64(1);
end

% default outputs
heatmap = zeros(double(H), double(W));
auc = NaN;

% mask fallback: load last_mask.mat if none provided
if nargin < 3 || isempty(mask)
    if exist('last_mask.mat','file')
        tmp = load('last_mask.mat');
        if isfield(tmp,'mask')
            mask = tmp.mask;
        else
            mask = false(double(H), double(W));
        end
    else
        mask = false(double(H), double(W));
    end
end
if ~islogical(mask)
    mask = mask ~= 0;
end
% reshape data (N x B)
N = double(H) * double(W);
X = reshape(cube, N, double(B));

% sanitize selectedBands; fallback to Fisher if empty
if nargin < 2 || isempty(selectedBands) || ~isnumeric(selectedBands)
    selectedBands = [];
end
selectedBands = unique(round(selectedBands(:)'));
selectedBands = selectedBands(selectedBands>=1 & selectedBands<=double(B));
if isempty(selectedBands)
    % Fisher fallback: call fisher_scores if available
    try
        fScores = fisher_scores(X, reshape(mask,[],1)); % returns vector length B
        [~, idxf] = sort(fScores, 'descend');
        k = min(10, numel(idxf));
        selectedBands = idxf(1:k);
        warning('simulate_detection:NoBands','No valid selectedBands provided — falling back to top-%d Fisher bands.', k);
    catch
        selectedBands = 1:double(B);
        warning('simulate_detection:FallbackAll','Fisher not available — falling back to all bands.');
    end
end

% Now safe to use selectedBands (integer vector)
Xsel = X(:, double(selectedBands));

% If no target pixels, return variance saliency
y = reshape(mask, [], 1);
if ~any(y)
    varvec = var(reshape(cube, [], double(B)), 0, 1);
    if all(varvec==0)
        heatmap = zeros(double(H), double(W));
        auc = NaN;
        return
    end
    proj = X * (varvec(:) ./ (norm(varvec)+eps));
    proj = proj - min(proj(:));
    if max(proj) > 0
        proj = proj / max(proj);
    end
    heatmap = reshape(proj, double(H), double(W));
    auc = NaN;
    return
end

% Compute matched-filter-like detector (CEM fallback)
try
    tSpec = mean(Xsel(y==1,:),1)'; % kx1
    bSpec = mean(Xsel(y==0,:),1)'; % kx1
    Rb = cov(Xsel(y==0,:), 1);
    reg = 1e-6 * trace(Rb) / size(Rb,1);
    Rb = Rb + reg * eye(size(Rb));
    s = (tSpec - bSpec);
    w = (Rb \ s);
    denom = (s' * w);
    if abs(denom) > eps
        w = w / denom;
    end
    scores = Xsel * w;
catch ME
    warning('simulate_detection:detFail','Detector failed (%s). Using mean-projection fallback.', ME.message);
    sFallback = mean(Xsel(y==1,:),1)';
    if all(sFallback==0)
        scores = mean(Xsel,2);
    else
        scores = Xsel * (sFallback / (norm(sFallback)+eps));
    end
end

% normalize and return
scores = scores - min(scores);
if max(scores) > 0
    scores = scores / max(scores);
end
heatmap = reshape(scores, double(H), double(W));

% compute AUC if labels exist
try
    if numel(unique(y))>1 && exist('perfcurve','file')
        [~,~,~,auc] = perfcurve(double(y), double(scores), 1);
    else
        auc = NaN;
    end
catch
    auc = NaN;
end

end
