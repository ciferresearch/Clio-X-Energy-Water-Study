function res = cliox_simulate(cfg, progressFcn)
%CLIOX_SIMULATE  Full pipeline: estimates -> display -> simulated choices -> tests.
%   res = cliox_simulate(cfg)
%   res = cliox_simulate(cfg, @(frac, msg) false)   % progress callback;
%         return true from the callback to cancel.
%
%   For each sample size n (users per condition) and each of cfg.mc.nSim
%   independent simulated studies:
%     1. true post-execution resources are drawn around the estimates;
%     2. each user's choice is drawn from the condition's choice
%        probabilities (display is built from PRE-execution estimates);
%     3. success = choosing the provider with the lowest TRUE metric;
%     4. two-proportion z-tests with family-wise correction.
%   Power is the share of studies that reject H0 for a comparison.

if nargin < 2, progressFcn = []; end
cliox_validate(cfg);
rng(cfg.mc.seed, 'twister');

est  = cliox_estimate(cfg);
J    = numel(est.E);
nSim = cfg.mc.nSim;
tr   = cliox_truth(cfg, est, nSim);
[Pc, Z] = cliox_choice_probs(cfg, est);
cmp  = cliox_comparisons(cfg);

nG = round(cfg.mc.nGrid(:)');
G  = numel(nG);
C  = numel(cfg.cond.name);
K  = numel(cmp.a);
inc = find(cfg.cond.include);

nanGC = nan(G, C);  nanGK = nan(G, K);
res.succMean = nanGC; res.succLo = nanGC; res.succHi = nanGC;
res.Echosen  = nanGC; res.Wchosen = nanGC;
res.power = nanGK; res.powerLo = nanGK; res.powerHi = nanGK;
res.powerBenefit = nanGK; res.powerHarm = nanGK;
res.diffMean = nanGK; res.diffLo = nanGK; res.diffHi = nanGK;
res.dEmean = nanGK; res.dElo = nanGK; res.dEhi = nanGK;
res.dWmean = nanGK; res.dWlo = nanGK; res.dWhi = nanGK;

chunk = max(1, round(cfg.mc.chunk));
best  = tr.best(:)';
nSteps = G * numel(inc); step = 0;
for g = 1:G
    n = nG(g);
    succ = nan(C, nSim); Ech = nan(C, nSim); Wch = nan(C, nSim);
    for c = inc
        cp = cumsum(Pc(c, :)); cp(end) = 1;
        for s1 = 1:chunk:nSim
            s2 = min(nSim, s1 + chunk - 1); m = s2 - s1 + 1;
            u  = rand(n, m);
            ch = ones(n, m);
            for j = 1:J-1, ch = ch + (u > cp(j)); end
            counts = zeros(J, m);
            for j = 1:J, counts(j, :) = sum(ch == j, 1); end
            succ(c, s1:s2) = counts(sub2ind([J m], best(s1:s2), 1:m));
            Ech(c, s1:s2)  = sum(counts .* tr.Eb(s1:s2, :)', 1) / n;   % electricity on truth basis
            Wch(c, s1:s2)  = sum(counts .* tr.W(s1:s2, :)', 1) / n;
        end
        step = step + 1;
        if ~isempty(progressFcn) && progressFcn(step / nSteps, ...
                sprintf('n = %d per condition: %s', n, cfg.cond.name{c}))
            error('cliox:cancelled', 'Simulation cancelled by user.');
        end
    end
    rate = succ / n;
    for c = inc
        res.succMean(g, c) = mean(rate(c, :));
        q = cliox_quantile(rate(c, :), [0.025 0.975]);
        res.succLo(g, c) = q(1); res.succHi(g, c) = q(2);
        res.Echosen(g, c) = mean(Ech(c, :));
        res.Wchosen(g, c) = mean(Wch(c, :));
    end
    if K > 0
        rej = cliox_tests(succ, n, cmp, cfg.mc);
        for k = 1:K
            a = cmp.a(k); b = cmp.b(k);
            d = rate(a, :) - rate(b, :);
            pw = mean(rej(k, :));
            se = sqrt(pw * (1 - pw) / nSim);
            res.power(g, k)   = pw;
            res.powerLo(g, k) = max(0, pw - 1.96 * se);
            res.powerHi(g, k) = min(1, pw + 1.96 * se);
            res.powerBenefit(g, k) = mean(rej(k, :) & d > 0);
            res.powerHarm(g, k)    = mean(rej(k, :) & d < 0);
            [res.diffMean(g, k), res.diffLo(g, k), res.diffHi(g, k)] = summ(d);
            [res.dEmean(g, k), res.dElo(g, k), res.dEhi(g, k)] = summ(Ech(b, :) - Ech(a, :));
            [res.dWmean(g, k), res.dWlo(g, k), res.dWhi(g, k)] = summ(Wch(b, :) - Wch(a, :));
        end
    end
end

% --- Analytic cross-checks --------------------------------------------
expSucc = (Pc * tr.bestFreq(:))';          % P(choose true best) per condition
nAnalytic = nan(1, K); nRequired = nan(1, K);
for k = 1:K
    nAnalytic(k) = analyticN(expSucc(cmp.a(k)), expSucc(cmp.b(k)), K, cfg.mc);
    nRequired(k) = firstCross(nG, res.power(:, k)', cfg.mc.targetPower);
end

res.cfg = cfg;
res.est = est;
res.truth = struct('bestFreq', tr.bestFreq, 'estimateAccuracy', tr.estimateAccuracy, ...
    'Emean', mean(tr.E, 1), 'Efmean', mean(tr.Ef, 1), 'Wmean', mean(tr.W, 1), 'basis', tr.basis);
res.pChoice = Pc;
res.zDisplayed = Z;
res.expSucc = expSucc;
res.cmp = cmp;
res.n = nG;
res.nAnalytic = nAnalytic;
res.nRequired = nRequired;
res.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
end

function [m, lo, hi] = summ(x)
m = mean(x);
q = cliox_quantile(x, [0.025 0.975]);
lo = q(1); hi = q(2);
end

function n = analyticN(p1, p2, K, mc)
% Normal-approximation n per group for a two-proportion test.
a = mc.alpha;
if ~strcmpi(mc.correction, 'none'), a = a / K; end  % conservative (Bonferroni)
if strcmpi(mc.sides, 'two-sided'), a = a / 2; elseif p1 <= p2, n = Inf; return; end
if abs(p1 - p2) < 1e-12, n = Inf; return; end
za = -sqrt(2) * erfcinv(2 * (1 - a));
zb = -sqrt(2) * erfcinv(2 * mc.targetPower);
pb = (p1 + p2) / 2;
n = ceil((za * sqrt(2 * pb * (1 - pb)) + zb * sqrt(p1*(1-p1) + p2*(1-p2)))^2 / (p1 - p2)^2);
end

function n = firstCross(x, y, target)
n = NaN;
i = find(y >= target, 1);
if isempty(i), return; end
if i == 1, n = x(1); return; end
n = ceil(x(i-1) + (target - y(i-1)) * (x(i) - x(i-1)) / (y(i) - y(i-1)));
end
