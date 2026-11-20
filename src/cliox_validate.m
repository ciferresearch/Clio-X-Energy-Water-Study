function cliox_validate(cfg)
%CLIOX_VALIDATE  Check inputs; errors explain what to fix.
p = cfg.prov;
J = numel(p.powerKW);
f = {'name', 'durationS', 'share', 'pue', 'pueTrue', 'wue', 'wueTrue', 'cost', 'wueDef'};
for i = 1:numel(f)
    if ~isfield(p, f{i}) || numel(p.(f{i})) ~= J
        error('cliox:input', 'Provider field "%s" must have %d entries.', f{i}, J);
    end
end
chk(J >= 2, 'At least two providers are needed.');
chk(all(isfinite(p.powerKW) & p.powerKW >= 0), 'IT power must be finite and >= 0 kW.');
chk(all(isfinite(p.durationS) & p.durationS > 0), 'Duration must be > 0 s.');
chk(all(isfinite(p.share) & p.share > 0 & p.share <= 1), 'Resource share must be in (0, 1].');
chk(all(isnan(p.pue) | p.pue >= 1), 'PUE must be >= 1 or NaN (not reported).');
chk(all(isfinite(p.pueTrue(isnan(p.pue))) & p.pueTrue(isnan(p.pue)) >= 1), ...
    'Unreported PUE needs a finite "true PUE" (>= 1) for the simulated ground truth.');
chk(all(isnan(p.wue) | p.wue >= 0), 'WUE must be >= 0 or NaN (not reported).');
chk(all(isfinite(p.wueTrue(isnan(p.wue))) & p.wueTrue(isnan(p.wue)) >= 0), ...
    'Unreported WUE needs a finite "true WUE" value for the simulated ground truth.');
chk(any(isfinite(p.wue)), 'At least one provider must report WUE.');
chk(all(isfinite(p.cost) & p.cost >= 0), 'Cost must be finite and >= 0.');
chk(cfg.telemetry.dtS > 0, 'Telemetry interval must be > 0 s.');
chk(any(strcmpi(cfg.index.energyBasis, {'facility', 'IT'})), 'Display electricity basis must be facility or IT.');
chk(any(strcmpi(cfg.truth.energyBasis, {'facility', 'IT'})), 'Truth electricity basis must be facility or IT.');
if strcmpi(cfg.index.energyBasis, 'facility')
    chk(any(isfinite(p.pue)), 'Facility electricity needs at least one reported PUE.');
end
chk(cfg.index.energyWeight >= 0 && cfg.index.energyWeight <= 1, 'Energy weight must be in [0, 1].');
chk(cfg.index.lowThr < cfg.index.highThr, 'Low threshold must be below High threshold.');
if strcmpi(cfg.index.refMode, 'fixed')
    chk(cfg.index.Eref > 0 && cfg.index.ErefIT > 0 && cfg.index.Wref > 0, 'Reference values must be > 0.');
end
c = cfg.cond;
chk(numel(c.include) == numel(c.name) && numel(c.attention) == numel(c.name) ...
    && numel(c.beta) == numel(c.name), 'Condition settings must align with condition names.');
chk(all(c.attention >= 0 & c.attention <= 1), 'Attention must be in [0, 1].');
chk(sum(c.include) >= 1, 'Include at least one condition.');
chk(all(cfg.mc.nGrid >= 2), 'Sample sizes must be >= 2 users per condition.');
chk(cfg.mc.nSim >= 10, 'Use at least 10 simulated studies.');
chk(cfg.mc.alpha > 0 && cfg.mc.alpha < 1, 'alpha must be in (0, 1).');
chk(cfg.mc.targetPower > 0 && cfg.mc.targetPower < 1, 'Target power must be in (0, 1).');
v = [cfg.uncert.powerCV cfg.uncert.durationCV cfg.uncert.wueCV cfg.uncert.pueCV];
chk(all(v >= 0), 'Uncertainty CVs must be >= 0.');
end

function chk(ok, msg)
if ~ok, error('cliox:input', '%s', msg); end
end
