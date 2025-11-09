function [fpr,tpr,auc,pd] = compute_roc(y_true, scores, pfa_target)
% y_true: binary labels (0/1)
% scores: detection scores (higher = target)
% pfa_target: desired Pfa for Pd computation (e.g. 1e-3 or 0.01)
if nargin<3, pfa_target = 0.01; end
[x,y,th,auc] = perfcurve(y_true, scores, 1);
fpr = x; tpr = y;
% find Pd at closest Pfa
[~, idx] = min(abs(fpr - pfa_target));
pd = tpr(idx);
end
