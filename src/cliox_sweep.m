function sw = cliox_sweep(cfg, path, values, n, progressFcn)
%CLIOX_SWEEP  One-at-a-time sensitivity analysis at a fixed sample size.
%   sw = cliox_sweep(cfg, 'cond.attention(4)', linspace(0,0.5,11), 300)
%   Uses the same random seed for every value (common random numbers), so
%   differences between values reflect the parameter, not simulation noise.

if nargin < 5, progressFcn = []; end
cfg.mc.nGrid = n;
V = numel(values);
cmp = cliox_comparisons(cfg);
C = numel(cfg.cond.name); K = numel(cmp.a);
sw.path = path; sw.values = values(:)'; sw.n = n;
sw.succ = nan(V, C); sw.power = nan(V, K);
sw.dE = nan(V, K); sw.dW = nan(V, K);
sw.estimateAccuracy = nan(1, V);
sw.labels = cell(V, 1);
sw.condName = cfg.cond.name; sw.cmpName = cmp.name;
sw.cmpA = cmp.a; sw.cmpB = cmp.b;
ctl = find(strcmpi(cfg.cond.type, 'none'), 1); if isempty(ctl), ctl = 0; end
sw.ctl = ctl;
for i = 1:V
    c2 = cliox_setparam(cfg, path, values(i));
    r = cliox_simulate(c2);
    sw.succ(i, :)  = r.succMean(1, :);
    sw.power(i, :) = r.power(1, :);
    sw.dE(i, :) = r.dEmean(1, :);
    sw.dW(i, :) = r.dWmean(1, :);
    sw.estimateAccuracy(i) = r.truth.estimateAccuracy;
    sw.labels{i} = strjoin(r.est.labels, '/');
    if ~isempty(progressFcn) && progressFcn(i / V, sprintf('%s = %g', path, values(i)))
        error('cliox:cancelled', 'Sweep cancelled by user.');
    end
end
end
