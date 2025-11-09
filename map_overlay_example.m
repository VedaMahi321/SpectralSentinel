% map_overlay_example.m - overlay heatmap over map image with alpha
mapRGB = imread('map.png');   % supply an RGB map image
mapRGB = im2double(mapRGB);

% assume heatmap (HxW) is normalized [0 1]; resize to match map if sizes differ
[Hmap,Wmap,~] = size(mapRGB);
[Hheat,Wheat] = size(heatmap);
heat_resized = imresize(heatmap, [Hmap Wmap]);

% display
figure;
imshow(mapRGB); hold on;
h = imagesc(heat_resized, 'AlphaData', 0.5);   % adjust alpha for visibility
colormap(gca, turbo);
colorbar;
title('Map + Detection Heatmap');
