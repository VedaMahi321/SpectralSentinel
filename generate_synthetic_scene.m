function [cube, mask] = generate_synthetic_scene(H, W, B, snr_db, shift)
%GENERATE_SYNTHETIC_SCENE create HxWxB synthetic hyperspectral cube and mask
%   [cube, mask] = generate_synthetic_scene(H,W,B,snr_db,shift)

if nargin<1, H=100; end
if nargin<2, W=100; end
if nargin<3, B=80; end
if nargin<4, snr_db=20; end
if nargin<5, shift=0.0; end

rng(42);
noise_power = 10.^(-snr_db/10);

background = 0.5 + 0.1*randn(H,W,B);
target = 0.6 + shift + 0.1*randn(H,W,B);

mask = zeros(H,W);
cx = round(H/2); cy = round(W/2); r = round(min(H,W)/10);
for i=1:H
    for j=1:W
        if (i-cx)^2 + (j-cy)^2 < r^2
            mask(i,j) = 1;
            background(i,j,:) = target(i,j,:);
        end
    end
end

noise = sqrt(noise_power).*randn(H,W,B);
cube = background + noise;
cube = min(max(cube,0),1); % clip to [0,1]
end
