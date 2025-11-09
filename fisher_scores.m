function scores = fisher_scores(X,y)
%FISHER_SCORES compute Fisher score per band
% X: N x B, y: N x 1 (binary 0/1)
[N,B] = size(X);
scores = zeros(1,B);
for b=1:B
    xb = X(:,b);
    mu1 = mean(xb(y==1));
    mu0 = mean(xb(y==0));
    v1 = var(xb(y==1));
    v0 = var(xb(y==0));
    if isempty(mu1), mu1 = 0; v1 = 1; end
    scores(b) = ( (mu1-mu0).^2 ) / (v1+v0 + eps);
end
end
