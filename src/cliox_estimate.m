function est = cliox_estimate(cfg)
%CLIOX_ESTIMATE  Pre-execution transaction estimates using the paper's method.
%   E_IT  = sum_k P_k * dt_k * s_k    (kWh; dt_k = interval seconds / 3600)
%   E_fac = E_IT * PUE                 (kWh; NaN when PUE is not reported)
%   W     = E_IT * WUE                 (L;   NaN when WUE is not reported)
%   Water uses IT electricity, because WUE is water per kWh of IT
%   electricity; it is allocated only through E_IT (no second share factor).
%   The index and ratings use the electricity basis in cfg.index.energyBasis.

p  = cfg.prov;
J  = numel(p.powerKW);
dt = cfg.telemetry.dtS;
E  = zeros(1, J);
est.intervals = cell(1, J);
for j = 1:J
    [dts, Pk, sk] = cliox_intervals(p.durationS(j), dt, p.powerKW(j), p.share(j));
    E(j) = sum(Pk .* (dts / 3600) .* sk);
    est.intervals{j} = struct('dtS', dts, 'P', Pk, 's', sk);
end
Ef = E .* p.pue;                % NaN propagates: "cannot be established"
W  = E .* p.wue;

basis = cfg.index.energyBasis;
Eb = cliox_energy_basis(E, Ef, basis);
[R, labels, level, Eref, Wref] = cliox_index(Eb, W, cfg.index, basis);

est.name   = p.name;
est.E      = E;          % IT electricity, kWh
est.Ef     = Ef;         % facility electricity, kWh
est.Eb     = Eb;         % electricity on the display basis, kWh
est.basis  = basis;
est.W      = W;          % water, L
est.pue    = p.pue;
est.wue    = p.wue;
est.R      = R;
est.labels = labels;
est.level  = level;
est.Eref   = Eref;
est.Wref   = Wref;
est.metric = cliox_metric(Eb, W, R, cfg.truth.criterion);
fin = find(isfinite(est.metric));
[~, k] = min(est.metric(fin));
est.best = fin(k);              % provider the estimates identify as lowest
end

function [dts, Pk, sk] = cliox_intervals(durS, dt, P, s)
nK  = max(1, ceil(durS / dt - 1e-9));
dts = dt * ones(1, nK);
dts(end) = durS - dt * (nK - 1);
Pk = P * ones(1, nK);
sk = s * ones(1, nK);
end
