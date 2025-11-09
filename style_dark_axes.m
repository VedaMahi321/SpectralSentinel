function style_dark_axes(ax)
% STYLE_DARK_AXES - set axis colors for dark look (use before export)
if nargin<1, ax = gca; end
set(ax, 'Color', [0.07 0.07 0.07]);
set(ax, 'XColor', [0.9 0.9 0.9], 'YColor', [0.9 0.9 0.9], 'GridColor', [0.6 0.6 0.6]);
set(ax, 'FontSize', 12, 'Box', 'on');
colormap(ax, parula); % or turbo
end
