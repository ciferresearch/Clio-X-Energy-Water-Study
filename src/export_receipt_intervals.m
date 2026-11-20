function export_receipt_intervals(outDir)
%EXPORT_RECEIPT_INTERVALS  Write the telemetry intervals of the paper's receipt
%   (Shared GPU pool, seed 101, as in run_all) to <outDir>/receipt_1_intervals.csv,
%   for paper_figures/make_word_figures.py (Fig. 6).
%   Example: export_receipt_intervals('results\20261105_152335')
cfg = cliox_default_config('Shared GPU');
rc = cliox_receipt(cfg, 1, 101);
f = fopen(fullfile(outDir, 'receipt_1_intervals.csv'), 'w');
fprintf(f, 'Provider,Share,PUE,Epre_Wh,Efpre_Wh,k,tStart_s,tEnd_s,Pk_kW,cumE_Wh\n');
for k = 1:numel(rc.Pk)
    fprintf(f, '"%s",%g,%g,%.6f,%.6f,%d,%.6f,%.6f,%.6f,%.6f\n', rc.provider, rc.share, rc.pue, ...
        1000 * rc.Epre, 1000 * rc.Efpre, k, rc.tStart(k), rc.tEnd(k), rc.Pk(k), 1000 * rc.cumE(k));
end
fclose(f);
fprintf('Wrote %s (IT %.4f Wh post; check: receipts.csv EIT_post_Wh)\n', ...
    fullfile(outDir, 'receipt_1_intervals.csv'), 1000 * rc.Epost);
end
