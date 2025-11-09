function [selected, bestAUC] = greedy_selection(Xtrain, ytrain, Xval, yval, k)
%GREEDY_SELECTION Greedy wrapper selecting k bands by validation AUC
% Xtrain, Xval: N x B, ytrain,yval: N x1

B = size(Xtrain,2);
selected = [];
remaining = 1:B;
bestAUC = 0;

for t=1:k
    bestBand = NaN; bestScore = -Inf;
    for idx = remaining
        cand = [selected, idx];
        % Train random forest (TreeBagger) on selected bands
        Mdl = TreeBagger(40, Xtrain(:,cand), ytrain, 'Method','classification','OOBPrediction','off');
        % Predict on validation
        [~,scores] = predict(Mdl, Xval(:,cand));
        % scores(:,2) is positive-class probability
        posScores = scores(:,2);
        [~,~,~,auc] = perfcurve(yval, posScores, 1);
        if auc > bestScore
            bestScore = auc;
            bestBand = idx;
        end
    end
    selected = [selected, bestBand];
    remaining(remaining==bestBand) = [];
    bestAUC = bestScore;
    fprintf('Greedy selected band %d (AUC=%.4f)\n', bestBand, bestScore);
end
end
