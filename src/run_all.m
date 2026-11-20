%RUN_ALL  Batch run for the paper: all scenarios, figures, CSV tables, sweeps.
%   Run from this folder:  >> run_all
%   Output goes to ./results/<timestamp>/ . For interactive use: >> cliox_gui
%
%   Tip: set QUICK = true for a fast check (fewer simulated studies).

QUICK = false;

here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
addpath(here);
outDir = fullfile(here, 'results', datestr(now, 'yyyymmdd_HHMMSS'));
mkdir(outDir);
diary(fullfile(outDir, 'run_log.txt'));

fprintf('== Self-test ==\n');
ok = cliox_selftest();
if ~ok, warning('Self-test reported failures; check run_log.txt'); end

scen = cliox_scenarios();
allRes = cell(size(scen));
for i = 1:numel(scen)
    cfg = cliox_default_config(scen{i});
    if QUICK, cfg.mc.nSim = 500; end
    fprintf('\n== Scenario: %s ==\n%s\n', scen{i}, cfg.description);
    tic;
    res = cliox_simulate(cfg);
    fprintf('(%.1f s)\n', toc);
    L = cliox_summary(res);
    fprintf('%s\n', L{:});
    allRes{i} = res;

    tag = regexprep(lower(scen{i}), '[^a-z0-9]+', '_');
    fig = figure('Visible', 'off', 'Position', [100 100 1400 900], 'Color', 'w');
    cliox_plots('resources', subplot(2, 3, 1), subplot(2, 3, 2), res.est);
    cliox_plots('choices',   subplot(2, 3, 3), res);
    cliox_plots('success',   subplot(2, 3, 4), res);
    cliox_plots('power',     subplot(2, 3, [5 6]), res);
    if exist('sgtitle', 'file'), sgtitle(fig, sprintf('Scenario: %s', scen{i})); end
    print(fig, fullfile(outDir, sprintf('fig_%s_overview.png', tag)), '-dpng', '-r150');
    close(fig);

    fig = figure('Visible', 'off', 'Position', [100 100 1100 420], 'Color', 'w');
    cliox_plots('outcomes', subplot(1, 2, 1), subplot(1, 2, 2), res, numel(res.n));
    print(fig, fullfile(outDir, sprintf('fig_%s_outcomes.png', tag)), '-dpng', '-r150');
    close(fig);

    cliox_export(res, outDir);
end

% --- Sensitivity sweeps on the main scenario ---------------------------
cfg = cliox_default_config('WUE trap');
if QUICK, cfg.mc.nSim = 300; else, cfg.mc.nSim = 2000; end
sweeps = {
    'cond.attention(4)',  linspace(0, 0.5, 11), 300, 'Share of users acting on ratings (attention)'
    'uncert.powerCV',     linspace(0, 0.6, 13), 300, 'Coefficient of variation of IT-power estimates'
    'index.energyWeight', linspace(0, 1, 11),   300, 'Energy weight w in the combined index'
    };
for i = 1:size(sweeps, 1)
    fprintf('\n== Sweep: %s ==\n', sweeps{i, 1});
    sw = cliox_sweep(cfg, sweeps{i, 1}, sweeps{i, 2}, sweeps{i, 3});
    sw.label = sweeps{i, 4};
    for v = 1:numel(sw.values)
        fprintf('  %s = %6.3f  labels %-18s  est.acc %.2f  power %s\n', sw.path, sw.values(v), ...
            sw.labels{v}, sw.estimateAccuracy(v), sprintf('%.2f ', sw.power(v, :)));
    end
    tag = regexprep(sweeps{i, 1}, '[^A-Za-z0-9]+', '_');
    fig = figure('Visible', 'off', 'Position', [100 100 1200 450], 'Color', 'w');
    cliox_plots('sweep', subplot(1, 2, 1), subplot(1, 2, 2), sw);
    print(fig, fullfile(outDir, sprintf('fig_sweep_%s.png', tag)), '-dpng', '-r150');
    close(fig);
    res = cliox_simulate(cliox_setparam(cfg, 'mc.nGrid', sweeps{i, 3}));
    res.cfg.scenario = sprintf('WUE trap sweep %s', tag);
    cliox_export(res, outDir, sw);
end

% --- Electricity boundary: what if the display showed IT electricity only? ----
% Ground truth is always facility electricity + water (what the interface
% shows). Each scenario is run twice: display on the facility basis (as in
% the interface) and on the IT basis (as in Revision 1 of the simulation).
fprintf('\n== Electricity boundary (truth: facility electricity) ==\n');
fid = fopen(fullfile(outDir, 'cliox_boundary.csv'), 'w');
fprintf(fid, ['Scenario,DisplayBasis,RatingsDisplayed,EstimatesCorrect,Success_Control,Success_WUE,', ...
              'Success_Numeric,Success_Rating,Power300_NumericVsControl,Power300_RatingVsControl\n']);
bases = {'facility', 'IT'};
for i = 1:numel(scen)
    for b = 1:2
        cfg = cliox_default_config(scen{i});
        cfg.index.energyBasis = bases{b};
        cfg.truth.energyBasis = 'facility';
        cfg.mc.nGrid = 300;
        if QUICK, cfg.mc.nSim = 500; end
        r = cliox_simulate(cfg);
        k1 = find(strcmp(r.cmp.name, 'Numeric E & W vs Control'));
        k2 = find(strcmp(r.cmp.name, 'Rating L/M/H vs Control'));
        fprintf('  %-12s display %-8s ratings %-20s est.correct %5.1f%%  success C/W/N/R %4.1f/%4.1f/%4.1f/%4.1f%%  power(300) N %.2f R %.2f\n', ...
            scen{i}, bases{b}, strjoin(r.est.labels, '/'), 100 * r.truth.estimateAccuracy, 100 * r.expSucc, ...
            r.power(1, k1), r.power(1, k2));
        fprintf(fid, '"%s",%s,%s,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n', scen{i}, bases{b}, strjoin(r.est.labels, '/'), ...
            r.truth.estimateAccuracy, r.expSucc, r.power(1, k1), r.power(1, k2));
    end
end
fclose(fid);

% --- Example transaction receipts ---------------------------------------
cfg = cliox_default_config('Shared GPU');
fid = fopen(fullfile(outDir, 'receipts.txt'), 'w');
fcsv = fopen(fullfile(outDir, 'receipts.csv'), 'w');
fprintf(fcsv, ['Provider,Share,PUE,WUE,DurPre_s,DurPost_s,EIT_pre_Wh,EIT_post_Wh,Efac_pre_Wh,Efac_post_Wh,', ...
               'W_pre_mL,W_post_mL,Efac_sim_Wh,W_sim_mL,PUE_mult,WUE_mult\n']);
for j = 1:numel(cfg.prov.powerKW)
    rc = cliox_receipt(cfg, j, 100 + j);
    fprintf(fid, '%s\n', rc.text{:}); fprintf(fid, '\n');
    fprintf(fcsv, '"%s",%g,%g,%g,%.2f,%.2f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n', rc.provider, rc.share, ...
        rc.pue, rc.wue, rc.durPre, rc.durPost, 1000 * [rc.Epre rc.Epost rc.Efpre rc.Efpost rc.Wpre rc.Wpost rc.Efsim rc.Wsim], rc.pueMult, rc.wueMult);
    fig = figure('Visible', 'off', 'Position', [100 100 1100 400], 'Color', 'w');
    cliox_plots('receipt', subplot(1, 2, 1), subplot(1, 2, 2), rc);
    print(fig, fullfile(outDir, sprintf('fig_receipt_%d.png', j)), '-dpng', '-r150');
    close(fig);
end
fclose(fid); fclose(fcsv);

% Each receipt above is one random draw. Summarise the accounting gap over many draws.
gap = cliox_receipt_gap(cfg);
fid = fopen(fullfile(outDir, 'receipt_gap.csv'), 'w');
fprintf(fid, 'Quantity,CV,Draws,Mean_pct,Median_pct,P95_pct,P99_pct\n');
for g = gap
    fprintf(fid, '%s,%g,%d,%.2f,%.2f,%.2f,%.2f\n', g.name, g.cv, g.n, 100 * [g.mean g.median g.p95 g.p99]);
    fprintf('Receipt gap (%s, CV %.2f): median %.1f%%, 95th percentile %.1f%%\n', g.name, g.cv, 100 * g.median, 100 * g.p95);
end
fclose(fid);

save(fullfile(outDir, 'all_results.mat'), 'allRes', 'scen');
diary off;
fprintf('\nDone. Results in %s\n', outDir);
