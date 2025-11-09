function paretoIdx = pareto_front(scores, redundancy)
% PARETO_FRONT  Return indices of Pareto-optimal points.
%   We treat 'scores' as a value to maximize and 'redundancy' to minimize.
%   Inputs:
%     scores     - 1 x B or B x 1 vector (higher = better)
%     redundancy - 1 x B or B x 1 vector (lower = better)
%   Output:
%     paretoIdx  - indices of Pareto-optimal points (in input order)

scores = scores(:);
redundancy = redundancy(:);
B = numel(scores);

is_dominated = false(B,1);

for i = 1:B
    for j = 1:B
        if i==j, continue; end
        % j dominates i if:
        % (scores(j) >= scores(i) AND redundancy(j) <= redundancy(i))
        % with at least one strict inequality
        if (scores(j) >= scores(i)) && (redundancy(j) <= redundancy(i))
            if (scores(j) > scores(i)) || (redundancy(j) < redundancy(i))
                is_dominated(i) = true;
                break;
            end
        end
    end
end

paretoIdx = find(~is_dominated);

% Optionally sort pareto by redundancy ascending or score descending for plotting
[~,ord] = sortrows([redundancy(paretoIdx), -scores(paretoIdx)]);
paretoIdx = paretoIdx(ord);
end

