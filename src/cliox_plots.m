function cliox_plots(kind, varargin)
%CLIOX_PLOTS  Plotting routines shared by the GUI (uiaxes) and batch runs (axes).
%   cliox_plots('resources', axE, axW, est)
%   cliox_plots('choices',   ax, res)
%   cliox_plots('power',     ax, res)
%   cliox_plots('success',   ax, res)
%   cliox_plots('outcomes',  axE, axW, res, g)      g = index into res.n
%   cliox_plots('sweep',     axP, axS, sw)
%   cliox_plots('receipt',   axP, axC, rc)
switch lower(kind)
    case 'resources', plotResources(varargin{:});
    case 'choices',   plotChoices(varargin{:});
    case 'power',     plotPower(varargin{:});
    case 'success',   plotSuccess(varargin{:});
    case 'outcomes',  plotOutcomes(varargin{:});
    case 'sweep',     plotSweep(varargin{:});
    case 'receipt',   plotReceipt(varargin{:});
    otherwise, error('cliox:plot', 'Unknown plot "%s".', kind);
end
end

% -----------------------------------------------------------------------
function col = condColors(n)
base = [0.45 0.45 0.45; 0.90 0.50 0.10; 0.15 0.45 0.80; 0.20 0.62 0.30; ...
        0.60 0.30 0.70; 0.80 0.25 0.30; 0.10 0.65 0.70; 0.55 0.45 0.20];
col = base(mod((1:n) - 1, size(base, 1)) + 1, :);
end

function l = nlim(n)
l = [min(n) max(n)];
if l(1) == l(2), l = l + [-1 1] * max(1, 0.1 * l(1)); end
end

function prep(ax)
cla(ax); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
end

function plotResources(axE, axW, est)
J = numel(est.E);
prep(axE);
Ef = est.Ef; Ef(~isfinite(Ef)) = 0;
h = bar(axE, 1:J, 1000 * [est.E(:) Ef(:)], 'grouped');
set(h(1), 'FaceColor', [0.62 0.76 0.92]); set(h(2), 'FaceColor', [0.15 0.45 0.80]);
for j = 1:J
    if isfinite(est.Ef(j)), s = sprintf('%.1f', 1000 * est.Ef(j)); else, s = 'N/A'; end
    text(axE, j + 0.15, 1000 * max(est.Ef(j), 0), s, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end
set(axE, 'XTick', 1:J, 'XTickLabel', est.name, 'XLim', [0.4 J + 0.6]);
ylabel(axE, 'Transaction electricity (Wh)');
title(axE, 'Electricity: IT and facility (IT \times PUE)');
legend(axE, {'IT', 'Facility'}, 'Location', 'northwest');
yl = ylim(axE); ylim(axE, [0 yl(2) * 1.2]);
hold(axE, 'off');

prep(axW);
Wv = 1000 * est.W; Wv(~isfinite(Wv)) = 0;
bar(axW, 1:J, Wv, 0.6, 'FaceColor', [0.10 0.65 0.70]);
for j = 1:J
    if isfinite(est.W(j))
        s = sprintf('%.1f mL (%s)', 1000 * est.W(j), est.labels{j});
    else
        s = 'N/A (no WUE)';
    end
    text(axW, j, Wv(j), s, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end
set(axW, 'XTick', 1:J, 'XTickLabel', est.name, 'XLim', [0.4 J + 0.6]);
ylabel(axW, 'Transaction water (mL)');
title(axW, 'Water  W = E_{IT} \times WUE  (rating shown)');
yl = ylim(axW); ylim(axW, [0 max(yl(2), 1e-3) * 1.3]);
hold(axW, 'off');
end

function plotChoices(ax, res)
inc = find(res.cfg.cond.include);
J = numel(res.est.E);
Y = [res.pChoice(inc, :); res.truth.bestFreq]';
prep(ax);
h = bar(ax, 1:J, Y, 'grouped');
col = condColors(numel(res.cfg.cond.name));
for i = 1:numel(inc), set(h(i), 'FaceColor', col(inc(i), :)); end
set(h(end), 'FaceColor', [0.1 0.1 0.1]);
set(ax, 'XTick', 1:J, 'XTickLabel', res.est.name, 'XLim', [0.4 J + 0.6]);
plot(ax, [0.4 J + 0.6], [1 1] / J, 'k:');
ylabel(ax, 'Probability');
title(ax, 'Choice probability vs. P(truly lowest)');
legend(ax, [res.cfg.cond.name(inc), {'P(truly lowest)'}], 'Location', 'northeastoutside', 'Interpreter', 'none');
ylim(ax, [0 1]);
hold(ax, 'off');
end

function plotPower(ax, res)
prep(ax);
K = numel(res.cmp.a);
col = condColors(numel(res.cfg.cond.name));
mk = {'o', 's', '^', 'd', 'v', 'p', 'h', '>'};
for k = 1:K
    ls = '-';
    if res.cmp.b(k) ~= find(strcmpi(res.cfg.cond.type, 'none'), 1), ls = '--'; end
    plot(ax, res.n, res.power(:, k), [ls mk{mod(k-1, 8) + 1}], 'Color', col(res.cmp.a(k), :), ...
        'LineWidth', 1.5, 'MarkerFaceColor', col(res.cmp.a(k), :));
end
plot(ax, [min(res.n) max(res.n)], res.cfg.mc.targetPower * [1 1], 'k--');
plot(ax, [min(res.n) max(res.n)], res.cfg.mc.alpha * [1 1], 'k:');
xlabel(ax, 'Users per condition');
ylabel(ax, 'Power (share of simulated studies rejecting H_0)');
title(ax, sprintf('Power, %s, %s correction (dashed = vs WUE only)', res.cfg.mc.sides, res.cfg.mc.correction));
if K > 0, legend(ax, res.cmp.name, 'Location', 'southeast', 'Interpreter', 'none'); end
ylim(ax, [0 1]); xlim(ax, nlim(res.n));
hold(ax, 'off');
end

function plotSuccess(ax, res)
prep(ax);
inc = find(res.cfg.cond.include);
col = condColors(numel(res.cfg.cond.name));
h = [];
for i = 1:numel(inc)
    c = inc(i);
    h(i) = plot(ax, res.n, 100 * res.succMean(:, c), '-o', 'Color', col(c, :), 'LineWidth', 1.5, ...
        'MarkerFaceColor', col(c, :));
    plot(ax, res.n, 100 * res.succLo(:, c), ':', 'Color', col(c, :));
    plot(ax, res.n, 100 * res.succHi(:, c), ':', 'Color', col(c, :));
end
plot(ax, [min(res.n) max(res.n)], 100 / numel(res.est.E) * [1 1], 'k--');
xlabel(ax, 'Users per condition');
ylabel(ax, 'Chose truly lowest-resource provider (%)');
title(ax, 'Selection accuracy (dotted: 95% range a single study could observe)');
legend(ax, h, res.cfg.cond.name(inc), 'Location', 'northeast', 'Interpreter', 'none');
xlim(ax, nlim(res.n));
hold(ax, 'off');
end

function plotOutcomes(axE, axW, res, g)
inc = find(res.cfg.cond.include);
col = condColors(numel(res.cfg.cond.name));
vals = {1000 * res.Echosen(g, inc), 1000 * res.Wchosen(g, inc)};
axs = {axE, axW};
yl = {sprintf('Mean %s electricity of chosen provider (Wh)', res.truth.basis), 'Mean water of chosen provider (mL)'};
tt = {'Electricity per transaction', 'Water per transaction'};
for a = 1:2
    ax = axs{a};
    prep(ax);
    for i = 1:numel(inc)
        bar(ax, i, vals{a}(i), 0.6, 'FaceColor', col(inc(i), :));
        text(ax, i, vals{a}(i), sprintf('%.2f', vals{a}(i)), 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom');
    end
    set(ax, 'XTick', 1:numel(inc), 'XTickLabel', res.cfg.cond.name(inc), 'XLim', [0.4 numel(inc) + 0.6]);
    ylabel(ax, yl{a});
    title(ax, sprintf('%s (true values, n = %d)', tt{a}, res.n(g)));
    y = ylim(ax); ylim(ax, [0 y(2) * 1.12]);
    hold(ax, 'off');
end
end

function plotSweep(axP, axS, sw)
cfgNames = sw.condName;
col = condColors(numel(cfgNames));
prep(axP);
K = numel(sw.cmpName);
for k = 1:K
    ls = '-o'; if sw.cmpB(k) ~= sw.ctl, ls = '--s'; end
    plot(axP, sw.values, sw.power(:, k), ls, 'LineWidth', 1.5, 'Color', col(sw.cmpA(k), :));
end
xl = strrep(sw.path, '_', '\_');
if isfield(sw, 'label') && ~isempty(sw.label), xl = sw.label; end
xlabel(axP, xl);
ylabel(axP, 'Power');
title(axP, sprintf('Power vs parameter (n = %d per condition)', sw.n));
if K > 0, legend(axP, sw.cmpName, 'Location', 'southeast', 'Interpreter', 'none'); end
ylim(axP, [0 1]);
hold(axP, 'off');

prep(axS);
inc = find(any(isfinite(sw.succ), 1));
h = [];
for i = 1:numel(inc)
    h(i) = plot(axS, sw.values, 100 * sw.succ(:, inc(i)), '-o', 'LineWidth', 1.5, 'Color', col(inc(i), :));
end
h(end+1) = plot(axS, sw.values, 100 * sw.estimateAccuracy, 'k--', 'LineWidth', 1.2);
xlabel(axS, xl);
ylabel(axS, '%');
title(axS, 'Selection accuracy and estimate accuracy');
legend(axS, h, [cfgNames(inc), {'Estimates pick true best'}], 'Location', 'southeast', 'Interpreter', 'none');
ylim(axS, [0 100]);
hold(axS, 'off');
end

function plotReceipt(axP, axC, rc)
prep(axP);
x = [rc.tStart; rc.tEnd]; x = x(:)';
y = [rc.Pk; rc.Pk];      y = y(:)';
plot(axP, x, y, '-', 'LineWidth', 1.5, 'Color', [0.15 0.45 0.80]);
plot(axP, x, y * rc.share, '-', 'LineWidth', 1.5, 'Color', [0.90 0.50 0.10]);
xlabel(axP, 'Time (s)'); ylabel(axP, 'kW');
title(axP, sprintf('%s: telemetry intervals', rc.provider));
legend(axP, {'Pool IT power P_k', 'Allocated P_k s_k'}, 'Location', 'southeast');
yl = ylim(axP); ylim(axP, [0 yl(2) * 1.1]);
hold(axP, 'off');

prep(axC);
tmax = max(rc.durPost, rc.durPre);
h1 = plot(axC, [0 rc.tEnd], [0 1000 * rc.cumE], '-o', 'LineWidth', 1.5, 'Color', [0.62 0.76 0.92]);
plot(axC, [0 tmax], 1000 * rc.Epre * [1 1], '--', 'Color', [0.62 0.76 0.92]);
hh = h1; nm = {'IT electricity'};
if isfinite(rc.pue)
    h2 = plot(axC, [0 rc.tEnd], [0 1000 * rc.cumE * rc.pue], '-s', 'LineWidth', 1.5, 'Color', [0.15 0.45 0.80]);
    plot(axC, [0 tmax], 1000 * rc.Efpre * [1 1], '--', 'Color', [0.15 0.45 0.80]);
    hh = [h1 h2]; nm = {'IT electricity', 'Facility (IT \times PUE)'};
end
xlabel(axC, 'Time (s)'); ylabel(axC, 'Cumulative allocated electricity (Wh)');
title(axC, 'Post-execution vs. pre-execution estimate (dashed)');
legend(axC, hh, nm, 'Location', 'southeast');
hold(axC, 'off');
end
