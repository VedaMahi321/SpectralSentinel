function jm = jm_distance(X,y)
%JM_DISTANCE compute Jeffries-Matusita per band (approx via Bhattacharyya)
[N,B] = size(X);
jm = zeros(1,B);
for b=1:B
    xb = X(:,b);
    mu1 = mean(xb(y==1));
    mu0 = mean(xb(y==0));
    v1 = var(xb(y==1)) + 1e-6;
    v0 = var(xb(y==0)) + 1e-6;
    % Bhattacharyya distance for 1D Gaussians
    Bdist = 1/8 * ( (mu1-mu0)^2 ) / ( (v1+v0)/2 ) + 0.5*log( ( (v1+v0)/2 ) / sqrt(v1*v0) );
    jm(b) = 2*(1 - exp(-Bdist));
end
end
