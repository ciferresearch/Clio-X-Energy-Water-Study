function files = cliox_export(res, folder, sw)
%CLIOX_EXPORT  Save results to folder: .mat, CSV tables and a text summary.
%   files = cliox_export(res, folder)       optional 3rd arg: sweep result
if nargin < 3, sw = []; end
if ~exist(folder, 'dir'), mkdir(folder); end
tag = regexprep(lower(res.cfg.scenario), '[^a-z0-9]+', '_');
files = {};
cfg = res.cfg; %#ok<NASGU>
f = fullfile(folder, sprintf('cliox_%s_results.mat', tag));
save(f, 'res', 'cfg', 'sw'); files{end+1} = f;

% Provider estimates
est = res.est;
f = fullfile(folder, sprintf('cliox_%s_providers.csv', tag));
fid = fopen(f, 'w');
fprintf(fid, 'Provider,IT_power_kW,Duration_s,Share,PUE,WUE_L_per_kWh,E_IT_Wh,E_facility_Wh,W_mL,RatingBasis,CombinedIndex,Rating,TrueBestFreq\n');
for j = 1:numel(est.E)
    fprintf(fid, '"%s",%g,%g,%g,%s,%s,%.4f,%s,%s,%s,%.4f,%s,%.4f\n', est.name{j}, res.cfg.prov.powerKW(j), ...
        res.cfg.prov.durationS(j), res.cfg.prov.share(j), num(est.pue(j)), num(est.wue(j)), 1000 * est.E(j), ...
        num(1000 * est.Ef(j)), num(1000 * est.W(j)), est.basis, est.R(j), est.labels{j}, res.truth.bestFreq(j));
end
fclose(fid); files{end+1} = f;

% Success by condition and n
f = fullfile(folder, sprintf('cliox_%s_success.csv', tag));
fid = fopen(f, 'w');
fprintf(fid, 'UsersPerCondition,Condition,MeanSuccess,Lo95,Hi95,MeanChosenElectricity_Wh,MeanChosenWater_mL\n');
for g = 1:numel(res.n)
    for c = find(res.cfg.cond.include)
        fprintf(fid, '%d,"%s",%.4f,%.4f,%.4f,%.4f,%.4f\n', res.n(g), res.cfg.cond.name{c}, ...
            res.succMean(g, c), res.succLo(g, c), res.succHi(g, c), ...
            1000 * res.Echosen(g, c), 1000 * res.Wchosen(g, c));
    end
end
fclose(fid); files{end+1} = f;

% Power by comparison and n
f = fullfile(folder, sprintf('cliox_%s_power.csv', tag));
fid = fopen(f, 'w');
fprintf(fid, 'UsersPerCondition,Comparison,Power,MC_Lo95,MC_Hi95,PowerBenefit,PowerHarm,MeanDiff_pp,Diff_Lo95_pp,Diff_Hi95_pp,ElectricitySaved_Wh,WaterSaved_mL\n');
for g = 1:numel(res.n)
    for k = 1:numel(res.cmp.a)
        fprintf(fid, '%d,"%s",%.4f,%.4f,%.4f,%.4f,%.4f,%.2f,%.2f,%.2f,%.5f,%.5f\n', res.n(g), res.cmp.name{k}, ...
            res.power(g, k), res.powerLo(g, k), res.powerHi(g, k), res.powerBenefit(g, k), res.powerHarm(g, k), ...
            100 * res.diffMean(g, k), 100 * res.diffLo(g, k), 100 * res.diffHi(g, k), ...
            1000 * res.dEmean(g, k), 1000 * res.dWmean(g, k));
    end
end
fclose(fid); files{end+1} = f;

% Sweep
if ~isempty(sw)
    f = fullfile(folder, sprintf('cliox_%s_sweep.csv', tag));
    fid = fopen(f, 'w');
    hdr = [{'Value', 'EstimateAccuracy'}, strcat('Success: ', sw.condName), strcat('Power: ', sw.cmpName)];
    fprintf(fid, '%s\n', strjoin(strcat('"', hdr, '"'), ','));
    for i = 1:numel(sw.values)
        fprintf(fid, '%g,%.4f%s%s\n', sw.values(i), sw.estimateAccuracy(i), ...
            sprintf(',%.4f', sw.succ(i, :)), sprintf(',%.4f', sw.power(i, :)));
    end
    fclose(fid); files{end+1} = f;
end

% Text summary
f = fullfile(folder, sprintf('cliox_%s_summary.txt', tag));
fid = fopen(f, 'w');
lines = cliox_summary(res);
fprintf(fid, '%s\n', lines{:});
fclose(fid); files{end+1} = f;
end

function s = num(x)
if isfinite(x), s = sprintf('%.4f', x); else, s = 'NA'; end
end
