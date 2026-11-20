function [ok, report] = cliox_selftest()
%CLIOX_SELFTEST  Verify the implementation against hand calculations and theory.
report = {};
ok = true;
tol = 1e-12;

% 1. The paper's Granite Cloud example (Figs. 1-2)
g = cliox_default_config('Dominant');
g.prov.powerKW = [0.22 1 1]; g.prov.durationS = [0.8 * 3600 90 90]; g.prov.share = [0.5 1 1];
g.prov.pue = [1.35 1.3 1.5]; g.prov.wue = [1.2 0.45 0.60];
eg = cliox_estimate(g);
add(sprintf('Granite Cloud: E_IT %.4f kWh, facility %.4f kWh, water %.4f L (expect 0.0880, 0.1188, 0.1056)', ...
    eg.E(1), eg.Ef(1), eg.W(1)), ...
    abs(eg.E(1) - 0.088) < tol && abs(eg.Ef(1) - 0.1188) < tol && abs(eg.W(1) - 0.1056) < tol);
add('Water uses IT electricity, not facility electricity (W = E_IT x WUE)', ...
    abs(eg.W(1) - eg.E(1) * 1.2) < tol && abs(eg.W(1) - eg.Ef(1) * 1.2) > 1e-6);

% 2. Dominant scenario: hand calculation on the facility basis
cfg = cliox_default_config('Dominant');
est = cliox_estimate(cfg);
add('Dominant: E_IT 20/40/60 Wh, E_fac 24/52/90 Wh, W 7.2/18/36 mL, R 0.48/1.12/2.10, Low/Medium/High', ...
    max(abs(est.E - [0.020 0.040 0.060])) < tol && max(abs(est.Ef - [0.024 0.052 0.090])) < tol && ...
    max(abs(est.W - [0.0072 0.018 0.036])) < tol && max(abs(est.R - [0.48 1.12 2.10])) < 1e-9 && ...
    isequal(est.labels, {'Low', 'Medium', 'High'}));

% 3. IT basis with Revision 1 references reproduces Revision 1 index values
c3 = cfg; c3.index.energyBasis = 'IT'; c3.index.ErefIT = 0.040; c3.index.Wref = 0.018;
e3 = cliox_estimate(c3);
add('IT basis + Revision 1 references reproduces R = 0.45/1.00/1.75', max(abs(e3.R - [0.45 1.00 1.75])) < 1e-9);

% 4. Resource share and partial telemetry interval
c4 = cfg; c4.prov.share(1) = 0.5; c4.prov.durationS(2) = 95;
e4 = cliox_estimate(c4);
add('Share 0.5 halves E_IT, E_fac and W; 95 s run = 10 intervals, last 5 s', ...
    abs(e4.E(1) - 0.010) < tol && abs(e4.Ef(1) - 0.012) < tol && abs(e4.W(1) - 0.0036) < tol && ...
    numel(e4.intervals{2}.dtS) == 10 && abs(e4.intervals{2}.dtS(end) - 5) < tol);

% 5. Missing inputs stay unavailable, never zero
e5 = cliox_estimate(cliox_default_config('Missing WUE'));
c5 = cfg; c5.prov.pue(2) = NaN; c5.prov.pueTrue(2) = 1.3;
e5b = cliox_estimate(c5);
add('Missing WUE -> water and rating N/A; missing PUE -> facility electricity and rating N/A, water kept', ...
    isnan(e5.W(1)) && strcmp(e5.labels{1}, 'N/A') && isnan(e5b.Ef(2)) && strcmp(e5b.labels{2}, 'N/A') && ...
    isfinite(e5b.W(2)));

% 6. Electricity boundary matters: PUE trap
cp = cliox_default_config('PUE trap');
ef = cliox_estimate(cp);
cp.index.energyBasis = 'IT';
ei = cliox_estimate(cp);
add(sprintf('PUE trap: facility basis rates %s lowest; IT basis rates %s lowest', ef.name{ef.best}, ei.name{ei.best}), ...
    ef.best == 2 && ei.best == 1);

% 7. Null: no attention -> false-positive rate ~ alpha
c7 = cfg; c7.cond.attention(:) = 0; c7.mc.nGrid = 200; c7.mc.nSim = 4000;
c7.mc.correction = 'None';
r7 = cliox_simulate(c7);
fp = r7.power(1, :);
se = sqrt(0.05 * 0.95 / c7.mc.nSim);
add(sprintf('Null scenario rejection rates %s ~ 0.05 (+/- %.3f)', sprintf('%.3f ', fp), 3 * se), ...
    all(abs(fp - 0.05) < 3 * se + 0.005));

% 8. Simulated success matches analytic expectation
c8 = cfg; c8.mc.nGrid = 300; c8.mc.nSim = 3000;
r8 = cliox_simulate(c8);
inc = find(c8.cond.include);
dev = max(abs(r8.succMean(1, inc) - r8.expSucc(inc)));
add(sprintf('Monte Carlo success matches analytic choice model (max dev %.4f)', dev), dev < 0.01);

% 9. Recognition special case: large beta, no position bias, exact estimates,
%    unique lowest displayed score that is also the true best -> q + (1-q)/3
c9 = cfg; c9.cond.include = [true false false true]; c9.cond.attention(4) = 0.15;
c9.cond.beta(4) = 50; c9.choice.positionBias = 0;
c9.uncert.powerCV = 0; c9.uncert.durationCV = 0; c9.uncert.wueCV = 0; c9.uncert.pueCV = 0;
c9.mc.nGrid = 495; c9.mc.nSim = 4000; c9.mc.correction = 'None';
r9 = cliox_simulate(c9);
add(sprintf('Recognition case q = 0.15: success %.3f (expect 0.433), power %.3f (expect ~0.90)', ...
    r9.succMean(1, 4), r9.power(1, 1)), ...
    abs(r9.expSucc(4) - (0.15 + 0.85 / 3)) < 1e-6 && abs(r9.power(1, 1) - 0.90) < 0.03);

% 10. Expected savings in that case: q x (mean - best)
expE = 1000 * 0.15 * (mean(est.Ef) - est.Ef(1));
expW = 1000 * 0.15 * (mean(est.W) - est.W(1));
add(sprintf('Saving %.3f Wh facility / %.3f mL water (expect %.3f / %.3f)', ...
    1000 * r9.dEmean(1, 1), 1000 * r9.dWmean(1, 1), expE, expW), ...
    abs(1000 * r9.dEmean(1, 1) - expE) < 0.05 * expE && abs(1000 * r9.dWmean(1, 1) - expW) < 0.05 * expW);

% 11. Holm correction never rejects more than uncorrected tests
c11 = cliox_default_config(); c11.mc.nGrid = 150; c11.mc.nSim = 2000;
c11.mc.correction = 'None'; ra = cliox_simulate(c11);
c11.mc.correction = 'Holm'; rb = cliox_simulate(c11);
add('Holm-corrected power <= uncorrected power', all(rb.power(:) <= ra.power(:) + 1e-12));

% 12. Parameter paths used by sweeps and the GUI
c12 = cliox_setparam(cliox_default_config(), 'cond.attention(4)', 0.4);
c12 = cliox_setparam(c12, 'uncert.pueCV', 0.2);
c12 = cliox_setparam(c12, 'prov.pue(2)', 1.33);
add('Parameter paths set one element / one scalar (sweep support)', ...
    isequal(c12.cond.attention, [0 0.25 0.25 0.4]) && c12.uncert.pueCV == 0.2 && ...
    c12.prov.pue(2) == 1.33 && numel(c12.prov.pue) == 3 && cliox_getparam(c12, 'cond.attention(4)') == 0.4);

fprintf('%s\n', report{:});

    function add(msg, pass)
        if pass, s = 'PASS'; else, s = 'FAIL'; ok = false; end
        report{end+1} = sprintf('[%s] %s', s, msg);
    end
end
