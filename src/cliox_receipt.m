function rc = cliox_receipt(cfg, j, seed)
%CLIOX_RECEIPT  Simulated transaction receipt for provider j (paper Sec. III-B).
%   Before execution: estimate from assumed duration, power and share.
%   After execution: per-interval telemetry (with jitter and true run time)
%   is allocated with E_IT = sum P_k*dt_k*s_k, then
%     facility electricity = E_IT x annual-average PUE,
%     water                = E_IT x annual-average WUE.
%   The "simulated actual" values use effective (not annual) PUE and WUE;
%   they are unobservable in practice and shown to illustrate accounting error.

if nargin < 3, seed = cfg.mc.seed; end
rng(seed, 'twister');
p  = cfg.prov;
dt = cfg.telemetry.dtS;
u  = cfg.uncert;
lm = @(cv) exp(sqrt(log(1 + cv^2)) * randn - log(1 + cv^2) / 2);

est = cliox_estimate(cfg);
Ptrue = p.powerKW(j) * lm(u.powerCV);
Dtrue = p.durationS(j) * lm(u.durationCV);
wueRep = p.wue(j);  pueRep = p.pue(j);
wueBase = wueRep;   if ~isfinite(wueBase), wueBase = p.wueTrue(j); end
pueBase = pueRep;   if ~isfinite(pueBase), pueBase = p.pueTrue(j); end
wueEff = wueBase * lm(u.wueCV);
pueEff = pueBase * lm(u.pueCV);

nK  = max(1, ceil(Dtrue / dt - 1e-9));
dts = dt * ones(1, nK); dts(end) = Dtrue - dt * (nK - 1);
Pk  = max(0, Ptrue * (1 + cfg.telemetry.jitterCV * randn(1, nK)));
Ek  = Pk .* (dts / 3600) * p.share(j);

rc.provider = p.name{j};
rc.tEnd = cumsum(dts);
rc.tStart = rc.tEnd - dts;
rc.Pk = Pk;
rc.share = p.share(j);
rc.cumE = cumsum(Ek);
rc.Epre   = est.E(j);           rc.Epost  = sum(Ek);              % IT electricity
rc.Efpre  = est.Ef(j);          rc.Efpost = rc.Epost * pueRep;    % facility (NaN if PUE missing)
rc.Wpre   = est.W(j);           rc.Wpost  = rc.Epost * wueRep;    % water (NaN if WUE missing)
rc.Efsim  = rc.Epost * pueEff;  rc.Wsim   = rc.Epost * wueEff;    % simulated actual (unobservable)
rc.pueMult = pueEff / pueBase; rc.wueMult = wueEff / wueBase;   % effective / annual-average
rc.pue = pueRep; rc.wue = wueRep; rc.wueDef = p.wueDef{j};
rc.durPre = p.durationS(j); rc.durPost = Dtrue;
rc.text = receiptText(rc);
end

function t = receiptText(rc)
na = 'not available (input not reported; cannot be established)';
fmt = @(x, scale, unit) ternary(isfinite(x), sprintf('%.2f %s', scale * x, unit), na);
if isfinite(rc.wue)
    w = sprintf('%.2f L/kWh of IT electricity (annual average; definition: %s)', rc.wue, rc.wueDef);
else
    w = 'not available';
end
if isfinite(rc.pue), pu = sprintf('%.2f (annual average)', rc.pue); else, pu = 'not available'; end
t = {
    sprintf('Transaction receipt: %s', rc.provider)
    sprintf('Resource share s: %.3f', rc.share)
    sprintf('Duration           pre: %.0f s   post: %.1f s (%d telemetry intervals)', rc.durPre, rc.durPost, numel(rc.Pk))
    sprintf('IT electricity     pre: %.2f Wh  post: %.2f Wh', 1000 * rc.Epre, 1000 * rc.Epost)
    sprintf('Facility elec.     pre: %s  post: %s', fmt(rc.Efpre, 1000, 'Wh'), fmt(rc.Efpost, 1000, 'Wh'))
    sprintf('Water              pre: %s  post: %s', fmt(rc.Wpre, 1000, 'mL'), fmt(rc.Wpost, 1000, 'mL'))
    sprintf('PUE used: %s', pu)
    sprintf('WUE used: %s', w)
    sprintf('Simulated actual (effective PUE/WUE, unobservable): facility %.2f Wh, water %.2f mL', ...
        1000 * rc.Efsim, 1000 * rc.Wsim)
    sprintf('Effective / annual-average multipliers (single draw): PUE %.3f, WUE %.3f', rc.pueMult, rc.wueMult)
    'Facility electricity = IT electricity x PUE; water = IT electricity x WUE (on-site only;'
    'excludes recirculating coolant and upstream electricity-generation water).'};
end

function o = ternary(c, a, b)
if c, o = a; else, o = b; end
end
