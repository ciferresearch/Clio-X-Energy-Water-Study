function gap = cliox_receipt_gap(cfg, n, seed)
%CLIOX_RECEIPT_GAP  Distribution of the receipt accounting gap over many draws.
%   A receipt applies annual-average PUE and WUE to the post-execution IT
%   electricity; the simulated "actual" applies effective values, drawn as
%   annual average x m with m mean-one lognormal (CV cfg.uncert.pueCV / wueCV).
%   Both use the same IT electricity, so the relative gap reported in the paper,
%   (annual-average estimate - simulated) / simulated = 1/m - 1, depends only on m.
%   Returns, for facility electricity and water, the mean, median, 95th and
%   99th percentiles of |1/m - 1| over n draws (default 1e6, seed 7).

if nargin < 2, n = 1e6; end
if nargin < 3, seed = 7; end
rng(seed, 'twister');
spec = {'Facility electricity', cfg.uncert.pueCV; 'Water', cfg.uncert.wueCV};
for i = 1:2
    cv = spec{i, 2};
    s = sqrt(log(1 + cv^2));
    m = exp(s * randn(n, 1) - s^2 / 2);
    g = sort(abs(1 ./ m - 1));
    gap(i).name = spec{i, 1};
    gap(i).cv = cv;
    gap(i).n = n;
    gap(i).mean = mean(g);
    gap(i).median = g(ceil(0.50 * n));
    gap(i).p95 = g(ceil(0.95 * n));
    gap(i).p99 = g(ceil(0.99 * n));
end
end
