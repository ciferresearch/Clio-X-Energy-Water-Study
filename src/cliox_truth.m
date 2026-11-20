function tr = cliox_truth(cfg, est, nSim)
%CLIOX_TRUTH  Draw the post-execution "true" resource use for each simulated study.
%   True IT power, duration, effective PUE and effective WUE = estimate x
%   mean-one lognormal multiplier (CVs in cfg.uncert). Unreported PUE/WUE
%   use cfg.prov.pueTrue / wueTrue. The correct choice in study s is the
%   provider with the lowest true metric (cfg.truth.criterion) on the
%   electricity basis cfg.truth.energyBasis. Rows = studies, cols = providers.

p = cfg.prov;
J = numel(p.powerKW);
mP = lognmult(cfg.uncert.powerCV,    nSim, J);
mD = lognmult(cfg.uncert.durationCV, nSim, J);
mW = lognmult(cfg.uncert.wueCV,      nSim, J);
mU = lognmult(cfg.uncert.pueCV,      nSim, J);

wueBase = p.wue;  wueBase(isnan(wueBase)) = p.wueTrue(isnan(wueBase));
pueBase = p.pue;  pueBase(isnan(pueBase)) = p.pueTrue(isnan(pueBase));

E  = bsxfun(@times, mP .* mD, p.powerKW .* p.durationS / 3600 .* p.share);  % IT
Ef = E .* bsxfun(@times, mU, pueBase);                                        % facility
W  = E .* bsxfun(@times, mW, wueBase);                                        % water

basis = cfg.truth.energyBasis;
Eb = cliox_energy_basis(E, Ef, basis);
w = cfg.index.energyWeight;
if strcmpi(cfg.index.refMode, 'mean')
    Eit  = p.powerKW .* p.durationS / 3600 .* p.share;   % estimated IT electricity
    Eref = mean(cliox_energy_basis(Eit, Eit .* pueBase, basis));
    Wref = mean(Eit .* wueBase);
else
    Eref = cliox_eref(cfg.index, basis);
    Wref = cfg.index.Wref;
end
R = w * Eb / Eref + (1 - w) * W / Wref;
switch lower(cfg.truth.criterion)
    case 'combined', M = R;
    case 'energy',   M = Eb;
    case 'water',    M = W;
end
[~, best] = min(M, [], 2);

tr.E = E; tr.Ef = Ef; tr.Eb = Eb; tr.W = W; tr.R = R;
tr.basis    = basis;
tr.best     = best;
tr.bestFreq = accumarray(best, 1, [J 1])' / nSim;
tr.estimateAccuracy = mean(best == est.best);  % P(estimates pick the true best)
end

function m = lognmult(cv, n, J)
if cv <= 0
    m = ones(n, J);
else
    s = sqrt(log(1 + cv^2));
    m = exp(s * randn(n, J) - s^2 / 2);
end
end
