function [reject, padj, praw] = cliox_tests(succ, n, cmp, mc)
%CLIOX_TESTS  Two-proportion z-tests for every comparison in every simulated study.
%   succ: C x nSim success counts. Returns K x nSim logical rejections after
%   the family-wise correction in mc.correction ('None'|'Bonferroni'|'Holm').

K = numel(cmp.a);
nSim = size(succ, 2);
praw = ones(K, nSim);
for k = 1:K
    x1 = succ(cmp.a(k), :);  x2 = succ(cmp.b(k), :);
    d  = (x1 - x2) / n;
    pool = (x1 + x2) / (2 * n);
    se = sqrt(pool .* (1 - pool) * (2 / n));
    z = zeros(1, nSim);
    v = se > 0;
    z(v) = d(v) ./ se(v);
    if strcmpi(mc.sides, 'one-sided')
        praw(k, :) = 0.5 * erfc(z / sqrt(2));        % H1: treatment > reference
    else
        praw(k, :) = erfc(abs(z) / sqrt(2));
    end
end

switch lower(mc.correction)
    case 'none'
        padj = praw;
    case 'bonferroni'
        padj = min(1, praw * K);
    case 'holm'
        [ps, ix] = sort(praw, 1);
        adj = cummax(min(1, bsxfun(@times, ps, (K:-1:1)')), 1);
        padj = zeros(K, nSim);
        lin = ix + repmat((0:nSim-1) * K, K, 1);
        padj(lin) = adj;
    otherwise
        error('cliox:correction', 'Unknown correction "%s".', mc.correction);
end
reject = padj < mc.alpha;
end
