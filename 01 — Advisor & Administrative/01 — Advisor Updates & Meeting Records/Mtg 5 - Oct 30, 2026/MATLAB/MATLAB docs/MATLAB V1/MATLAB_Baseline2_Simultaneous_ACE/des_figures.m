function des_figures(M, T, P, S, B, outDir)
%DES_FIGURES  Export the dashboard figures at 300 dpi.
%   Styled to match the dark workbook dashboard: ground in amber, edge in cyan.

bg   = [0.043 0.090 0.153];
panel= [0.075 0.145 0.235];
gold = [0.949 0.757 0.306];
cyan = [0.498 0.820 0.910];
white= [1 1 1];

% ---------------------------------------------- figure 1: latency histogram
f1 = figure('Color', bg, 'Position', [60 60 1200 650], 'Name', 'Latency distribution');
ax = axes('Parent', f1, 'Color', panel, 'XColor', white, 'YColor', white, ...
          'FontName', 'Arial', 'FontSize', 11);
hold(ax, 'on');
h = bar(ax, [B.ground, B.edge], 'grouped');
set(h(1), 'FaceColor', gold, 'EdgeColor', 'none');
set(h(2), 'FaceColor', cyan, 'EdgeColor', 'none');
set(ax, 'XTick', 1:numel(B.label), 'XTickLabel', B.label, 'Box', 'off');
xlabel(ax, 'End to end latency (s)', 'Color', white, 'FontSize', 12);
ylabel(ax, 'Observations', 'Color', white, 'FontSize', 12);
title(ax, 'Ground vs Edge end to end latency distribution', 'Color', white, 'FontSize', 14);
lg = legend(ax, {'Ground', 'Edge'});
des_style_legend(lg, white, panel, 'northeast');
txt = sprintf(['N = %d paired observations    Ground mean %.1f s, median %.1f s' ...
               '    Edge mean %.1f s, median %.1f s    %d replications'], ...
               B.n, B.gMean, B.gMedian, B.eMean, B.eMedian, M.cfg.replications);
annotation(f1, 'textbox', [0.08 0.005 0.86 0.05], 'String', txt, 'Color', white, ...
           'EdgeColor', 'none', 'FontName', 'Arial', 'FontSize', 10, ...
           'HorizontalAlignment', 'center');
des_save(f1, fullfile(outDir, 'fig1_latency_histogram.png'));

% ------------------------------------------- figure 2: per replication view
f2 = figure('Color', bg, 'Position', [80 80 1200 650], 'Name', 'Replications');
ax = axes('Parent', f2, 'Color', panel, 'XColor', white, 'YColor', white, ...
          'FontName', 'Arial', 'FontSize', 11);
hold(ax, 'on');
h = bar(ax, [T.gMean, T.eMean], 'grouped');
set(h(1), 'FaceColor', gold, 'EdgeColor', 'none');
set(h(2), 'FaceColor', cyan, 'EdgeColor', 'none');
plot(ax, 1:numel(T.rep), repmat(P.latMean, numel(T.rep), 1), '--', ...
     'Color', white, 'LineWidth', 1.2);
set(ax, 'XTick', 1:numel(T.rep), 'Box', 'off');
xlabel(ax, 'Replication', 'Color', white, 'FontSize', 12);
ylabel(ax, 'Mean latency (s)', 'Color', white, 'FontSize', 12);
title(ax, sprintf('Mean latency by replication   (paired difference %.1f s, 95%% interval %.1f to %.1f)', ...
      P.latMean, P.latLow, P.latHigh), 'Color', white, 'FontSize', 13);
lg = legend(ax, {'Ground', 'Edge', 'Mean paired difference'});
des_style_legend(lg, white, panel, 'northeast');
des_save(f2, fullfile(outDir, 'fig2_replications.png'));

% ------------------------------------------------- figure 3: scenario sweep
f3 = figure('Color', bg, 'Position', [100 100 1200 650], 'Name', 'Scenarios');
ax = axes('Parent', f3, 'Color', panel, 'XColor', white, 'YColor', white, ...
          'FontName', 'Arial', 'FontSize', 11);
hold(ax, 'on');
h = bar(ax, [S.gMean, S.eMean], 'grouped');
set(h(1), 'FaceColor', gold, 'EdgeColor', 'none');
set(h(2), 'FaceColor', cyan, 'EdgeColor', 'none');
labels = cell(numel(S.name), 1);
for i = 1:numel(S.name)
    labels{i} = strrep(S.name{i}, '_', ' ');
end
set(ax, 'XTick', 1:numel(S.name), 'XTickLabel', labels, 'Box', 'off');
ylabel(ax, 'Mean latency (s)', 'Color', white, 'FontSize', 12);
title(ax, 'Scenario sweep: the edge path is allowed to lose', 'Color', white, 'FontSize', 14);
lg = legend(ax, {'Ground', 'Edge'});
des_style_legend(lg, white, panel, 'northwest');
des_save(f3, fullfile(outDir, 'fig3_scenarios.png'));

fprintf('Figures written: fig1_latency_histogram.png, fig2_replications.png, fig3_scenarios.png\n');
end

% ------------------------------------------------------------------------
function des_save(fh, target)
%DES_SAVE  300 dpi export, with a fallback for older releases.
try
    exportgraphics(fh, target, 'Resolution', 300, 'BackgroundColor', 'current');
catch
    set(fh, 'InvertHardcopy', 'off', 'PaperPositionMode', 'auto');
    print(fh, target, '-dpng', '-r300');
end
end

% ------------------------------------------------------------------------
function des_style_legend(lg, white, panel, loc)
%DES_STYLE_LEGEND  Legend styling that degrades quietly on older releases.
set(lg, 'Location', loc);
try
    set(lg, 'TextColor', white, 'Color', panel, 'EdgeColor', panel);
catch
    set(lg, 'Color', panel);
end
end
