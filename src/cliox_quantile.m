function q = cliox_quantile(x, p)
%CLIOX_QUANTILE  Linear-interpolation quantiles (no Statistics Toolbox needed).
x = sort(x(isfinite(x)));
n = numel(x);
q = nan(size(p));
if n == 0, return; end
if n == 1, q(:) = x; return; end
h = (n - 1) * p + 1;
lo = floor(h); hi = min(lo + 1, n);
q = x(lo) + (h - lo) .* (x(hi) - x(lo));
end
