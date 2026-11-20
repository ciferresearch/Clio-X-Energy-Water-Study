function lines = cliox_summary(res)
%CLIOX_SUMMARY  Plain-text summary of a simulation result (cell array of lines).
cfg = res.cfg; est = res.est;
L = {};
L{end+1} = sprintf('Clio-X simulation | scenario: %s | %s', cfg.scenario, res.timestamp);
L{end+1} = sprintf('Criterion: %s (truth basis: %s electricity) | %d studies per n | alpha %.3g (%s, %s) | target power %.2f', ...
    cfg.truth.criterion, cfg.truth.energyBasis, cfg.mc.nSim, cfg.mc.alpha, cfg.mc.sides, cfg.mc.correction, cfg.mc.targetPower);
L{end+1} = '';
L{end+1} = sprintf(['Pre-execution estimates (E_IT = sum P*dt*s, E_fac = E_IT x PUE, W = E_IT x WUE); ', ...
    'rating basis: %s electricity, Eref = %.1f Wh, Wref = %.1f mL'], est.basis, 1000 * est.Eref, 1000 * est.Wref);
for j = 1:numel(est.E)
    if isfinite(est.Ef(j)), ef = sprintf('%6.2f Wh', 1000 * est.Ef(j)); else, ef = '   N/A   '; end
    if isfinite(est.W(j)), w = sprintf('%6.2f mL', 1000 * est.W(j)); else, w = '   N/A   '; end
    L{end+1} = sprintf('  %-16s PUE %4.2f WUE %4.2f | E_IT %6.2f Wh  E_fac %s  W %s  R %5.2f  %-6s  true-best %.2f', ...
        est.name{j}, est.pue(j), est.wue(j), 1000 * est.E(j), ef, w, est.R(j), est.labels{j}, ...
        res.truth.bestFreq(j)); %#ok<AGROW>
end
L{end+1} = sprintf('  Estimates identify the true best provider in %.1f%% of studies.', 100 * res.truth.estimateAccuracy);
L{end+1} = '';
L{end+1} = sprintf('Expected success (chooses true lowest-resource provider), chance = %.1f%%', 100 / numel(est.E));
for c = find(cfg.cond.include)
    L{end+1} = sprintf('  %-16s %5.1f%%   choice probs: %s', cfg.cond.name{c}, 100 * res.expSucc(c), ...
        sprintf('%.2f ', res.pChoice(c, :))); %#ok<AGROW>
end
L{end+1} = '';
g = numel(res.n);
L{end+1} = sprintf('Comparisons (power at n = %d; required n for %.0f%% power)', res.n(g), 100 * cfg.mc.targetPower);
for k = 1:numel(res.cmp.a)
    if isnan(res.nRequired(k)), nr = sprintf('> %d', res.n(end)); else, nr = sprintf('%d', res.nRequired(k)); end
    L{end+1} = sprintf('  %-34s diff %+5.1f pp  power %.3f (benefit %.3f, harm %.3f)  n_req: %s (analytic %s)', ...
        res.cmp.name{k}, 100 * res.diffMean(g, k), res.power(g, k), res.powerBenefit(g, k), ...
        res.powerHarm(g, k), nr, num2str(res.nAnalytic(k))); %#ok<AGROW>
    L{end+1} = sprintf('  %-34s electricity saved %+.3f Wh, water saved %+.3f mL per transaction', '', ...
        1000 * res.dEmean(g, k), 1000 * res.dWmean(g, k)); %#ok<AGROW>
end
L{end+1} = '';
L{end+1} = 'Behavioural parameters (attention, beta) are ASSUMPTIONS; outputs show their consequences';
L{end+1} = 'and detectability, not observed human behaviour. All provider values are synthetic.';
lines = L(:);
end
