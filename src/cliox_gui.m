function app = cliox_gui()
%CLIOX_GUI  Interactive control panel for the Clio-X transparency simulation.
%   >> cliox_gui
%   Left: every model parameter (providers, estimation, labels, users,
%   Monte Carlo). Right: results tabs. Requires MATLAB R2020b or newer
%   (App Designer components: uifigure, uigridlayout, uiaxes). No toolboxes.

here = fileparts(mfilename('fullpath'));
addpath(here);

S.cfg = cliox_default_config('WUE trap');
S.res = [];
S.sw  = [];
S.rc  = [];

fig = uifigure('Name', 'Clio-X Resource Transparency Simulator', ...
    'Position', [40 40 1500 900]);
main = uigridlayout(fig, [1 2]);
main.ColumnWidth = {480, '1x'};

% =======================================================================
% LEFT: parameters
% =======================================================================
left = uigridlayout(main, [3 1]);
left.RowHeight = {'1x', 34, 34};
left.Padding = [0 0 0 0];
ltabs = uitabgroup(left);

% --- Tab: scenario & providers -----------------------------------------
tP = uitab(ltabs, 'Title', 'Providers');
gP = uigridlayout(tP, [6 3]);
gP.RowHeight = {24, 60, '1x', 28, 70, 24};
gP.ColumnWidth = {'1x', '1x', '1x'};
uilabel(gP, 'Text', 'Scenario:', 'FontWeight', 'bold');
ddScen = uidropdown(gP, 'Items', cliox_scenarios(), 'Value', S.cfg.scenario);
uibutton(gP, 'Text', 'Load scenario', 'ButtonPushedFcn', @(~, ~) onLoadScenario());
lblDesc = uilabel(gP, 'Text', S.cfg.description, 'WordWrap', 'on');
lblDesc.Layout.Row = 2; lblDesc.Layout.Column = [1 3];
tblProv = uitable(gP, 'ColumnEditable', true, 'CellEditCallback', @(~, ~) refreshEstimates(), ...
    'ColumnName', {'Name', 'IT power kW', 'Duration s', 'Share', 'PUE', 'True PUE if N/A', ...
                   'WUE L/kWh', 'True WUE if N/A', 'Cost $', 'WUE definition'}, ...
    'ColumnFormat', {'char', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', ...
                     'numeric', {'consumption', 'withdrawal', 'unspecified'}}, ...
    'ColumnWidth', {90, 55, 55, 45, 45, 60, 55, 60, 45, 85}, 'RowName', {});
tblProv.Layout.Row = 3; tblProv.Layout.Column = [1 3];
uibutton(gP, 'Text', 'Add provider', 'ButtonPushedFcn', @(~, ~) onAddProvider());
uibutton(gP, 'Text', 'Remove last', 'ButtonPushedFcn', @(~, ~) onRemoveProvider());
uibutton(gP, 'Text', 'Reset to scenario', 'ButtonPushedFcn', @(~, ~) onLoadScenario());
h = uilabel(gP, 'WordWrap', 'on', 'FontSize', 11, 'Text', ...
    ['Facility electricity = IT electricity x PUE; water = IT electricity x WUE. ', ...
     'Enter PUE or WUE as NaN when a provider does not report it: the value is then shown as ', ...
     '"not available", never zero. "True ... if N/A" is used only for the simulated ', ...
     'ground truth. Share = fraction of the measured resource assigned to the transaction ', ...
     '(1 = whole machine). All values are synthetic.']);
h.Layout.Row = 5; h.Layout.Column = [1 3];
lblCheck = uilabel(gP, 'Text', '', 'FontColor', [0.7 0 0]);
lblCheck.Layout.Row = 6; lblCheck.Layout.Column = [1 3];

% --- Tab: estimation, uncertainty and labels ---------------------------
tE = uitab(ltabs, 'Title', 'Estimation & ratings');
gE = uigridlayout(tE, [20 2]);
gE.RowHeight = repmat({22}, 1, 20);
try, gE.Scrollable = 'on'; catch, end
gE.ColumnWidth = {'1.4x', '1x'};
hdr(gE, 'Telemetry (paper Sec. III-A)');
fDt     = numField(gE, 'Telemetry interval (s)', 10, [0.1 3600]);
fJit    = numField(gE, 'Interval power jitter CV (receipt)', 0.1, [0 2]);
hdr(gE, 'Pre-execution estimate error (truth vs display)');
fPcv    = numField(gE, 'IT power CV', 0.1, [0 3]);
fDcv    = numField(gE, 'Duration CV', 0.1, [0 3]);
fWcv    = numField(gE, 'Effective WUE CV', 0.1, [0 3]);
fUcv    = numField(gE, 'Effective PUE CV', 0.05, [0 3]);
hdr(gE, 'Rating index R = w E/Eref + (1-w) W/Wref (design choice)');
ddBasis = ddField(gE, 'Electricity shown to users', {'facility', 'IT'}, 'facility');
fW      = numField(gE, 'Energy weight w', 0.5, [0 1]);
ddRef   = ddField(gE, 'Reference values', {'fixed', 'mean'}, 'fixed');
fEref   = numField(gE, 'Eref, facility (kWh)', 0.05, [1e-9 Inf]);
fErefIT = numField(gE, 'Eref, IT (kWh)', 0.04, [1e-9 Inf]);
fWref   = numField(gE, 'Wref (L)', 0.015, [1e-9 Inf]);
fLow    = numField(gE, 'Low if R <', 0.75, [0 Inf]);
fHigh   = numField(gE, 'High if R >=', 1.25, [0 Inf]);
hdr(gE, 'Correct choice');
ddCrit  = ddField(gE, 'Lowest-resource criterion', {'combined', 'energy', 'water'}, 'combined');
ddTBasis = ddField(gE, 'Electricity defining the truth', {'facility', 'IT'}, 'facility');

% --- Tab: users & conditions --------------------------------------------
tU = uitab(ltabs, 'Title', 'Users & conditions');
gU = uigridlayout(tU, [9 2]);
gU.RowHeight = {24, 150, 24, 24, 24, 24, 24, 24, '1x'};
gU.ColumnWidth = {'1.4x', '1x'};
h = uilabel(gU, 'Text', 'Between-subjects conditions (edit Include / Attention / Beta)', 'FontWeight', 'bold');
h.Layout.Column = [1 2];
tblCond = uitable(gU, 'ColumnName', {'Condition', 'Shows', 'Include', 'Attention', 'Beta'}, ...
    'ColumnEditable', [false false true true true], 'RowName', {}, ...
    'ColumnWidth', {110, 70, 55, 70, 50}, 'CellEditCallback', @(~, ~) refreshChoices());
tblCond.Layout.Row = 2; tblCond.Layout.Column = [1 2];
hdr(gU, 'Choice model (multinomial logit + attention mixture)');
fCost   = numField(gU, 'Cost sensitivity', 0, [0 Inf]);
fPos    = numField(gU, 'Position bias (top slot)', 0.3, [0 Inf]);
fMissF  = numField(gU, 'Missing numeric -> factor x worst', 1, [0 Inf]);
fMissL  = numField(gU, 'N/A rating score (Low=1..High=3)', 2.5, [0 5]);
h = uilabel(gU, 'WordWrap', 'on', 'FontSize', 11, 'VerticalAlignment', 'top', 'Text', ...
    ['Attention = share of users who use the displayed information; the rest choose ', ...
     'as in Control. Beta = how strongly attending users prefer lower displayed values ', ...
     '(large beta: they almost always pick the lowest). Attention 0.15 with large beta ', ...
     'and no position bias reproduces the simple "recognition q" model. These ', ...
     'behavioural values are assumptions to be varied, not results.']);
h.Layout.Row = 9; h.Layout.Column = [1 2];

% --- Tab: Monte Carlo ---------------------------------------------------
tM = uitab(ltabs, 'Title', 'Monte Carlo');
gM = uigridlayout(tM, [12 2]);
gM.RowHeight = repmat({24}, 1, 12);
gM.ColumnWidth = {'1.4x', '1x'};
uilabel(gM, 'Text', 'Users per condition (list)');
fGrid = uieditfield(gM, 'text', 'Value', num2str(S.cfg.mc.nGrid));
fNsim   = numField(gM, 'Simulated studies per n', 4000, [10 1e6]);
fAlpha  = numField(gM, 'Significance alpha', 0.05, [1e-6 0.5]);
fTarget = numField(gM, 'Target power', 0.9, [0.01 0.999]);
fSeed   = numField(gM, 'Random seed', 20261030, [0 2^32 - 1]);
ddSides = ddField(gM, 'Test', {'two-sided', 'one-sided'}, 'two-sided');
ddCorr  = ddField(gM, 'Multiple-comparison correction', {'Holm', 'Bonferroni', 'None'}, 'Holm');
ddCmp   = ddField(gM, 'Comparisons', {'vs Control', 'vs Control + vs WUE', 'All pairs'}, 'vs Control + vs WUE');
fChunk  = numField(gM, 'Block size (memory)', 1000, [10 1e5]);
h = uilabel(gM, 'WordWrap', 'on', 'FontSize', 11, 'Text', ...
    'Each simulated study draws new true resource values and new user choices; power = share of studies that reject H0.');
h.Layout.Row = [11 12]; h.Layout.Column = [1 2];

% --- Buttons ------------------------------------------------------------
gB = uigridlayout(left, [1 3]); gB.Padding = [0 0 0 0];
uibutton(gB, 'Text', 'RUN SIMULATION', 'FontWeight', 'bold', 'BackgroundColor', [0.20 0.62 0.30], ...
    'FontColor', 'w', 'ButtonPushedFcn', @(~, ~) onRun());
uibutton(gB, 'Text', 'Self-test', 'ButtonPushedFcn', @(~, ~) onSelfTest());
uibutton(gB, 'Text', 'Export results...', 'ButtonPushedFcn', @(~, ~) onExport());
gB2 = uigridlayout(left, [1 3]); gB2.Padding = [0 0 0 0];
uibutton(gB2, 'Text', 'Save settings...', 'ButtonPushedFcn', @(~, ~) onSaveCfg());
uibutton(gB2, 'Text', 'Load settings...', 'ButtonPushedFcn', @(~, ~) onLoadCfg());
uibutton(gB2, 'Text', 'Copy summary', 'ButtonPushedFcn', @(~, ~) onCopySummary());

% =======================================================================
% RIGHT: results
% =======================================================================
rtabs = uitabgroup(main);

% Resources
tR = uitab(rtabs, 'Title', '1 Resource estimates');
gR = uigridlayout(tR, [2 2]); gR.RowHeight = {170, '1x'};
tblEst = uitable(gR, 'RowName', {}, 'ColumnName', {'Provider', 'IT E (Wh)', 'Facility E (Wh)', 'W (mL)', ...
    'PUE', 'WUE', 'Index R', 'Rating', 'Water definition'});
tblEst.Layout.Column = [1 2];
axRE = uiaxes(gR); axRW = uiaxes(gR);

% Receipt
tRc = uitab(rtabs, 'Title', '2 Transaction receipt');
gRc = uigridlayout(tRc, [3 4]); gRc.RowHeight = {28, '1x', 190};
uilabel(gRc, 'Text', 'Provider:', 'HorizontalAlignment', 'right');
ddRcProv = uidropdown(gRc, 'Items', {'-'});
fRcSeed = uieditfield(gRc, 'numeric', 'Value', 1, 'Tooltip', 'Seed for this receipt');
uibutton(gRc, 'Text', 'Simulate execution', 'ButtonPushedFcn', @(~, ~) onReceipt());
axRcP = uiaxes(gRc); axRcP.Layout.Row = 2; axRcP.Layout.Column = [1 2];
axRcC = uiaxes(gRc); axRcC.Layout.Row = 2; axRcC.Layout.Column = [3 4];
taRc = uitextarea(gRc, 'Editable', 'off', 'FontName', 'Courier New');
taRc.Layout.Row = 3; taRc.Layout.Column = [1 4];

% Choices
tC = uitab(rtabs, 'Title', '3 Choice model');
gC = uigridlayout(tC, [2 1]); gC.RowHeight = {'1x', 170};
axCh = uiaxes(gC);
taCh = uitextarea(gC, 'Editable', 'off', 'FontName', 'Courier New');

% Power
tW = uitab(rtabs, 'Title', '4 Power & sample size');
gW = uigridlayout(tW, [2 1]); gW.RowHeight = {'1x', 190};
axPow = uiaxes(gW);
tblPow = uitable(gW, 'RowName', {}, 'ColumnName', {'Comparison', 'Mean diff (pp)', ...
    'Power @ max n', 'Benefit', 'Harm', 'n for target (sim)', 'n (analytic)', 'Energy saved (Wh)', 'Water saved (mL)'});

% Outcomes
tO = uitab(rtabs, 'Title', '5 Selection & savings');
gO = uigridlayout(tO, [3 3]); gO.RowHeight = {28, '1x', '1x'};
uilabel(gO, 'Text', 'Users per condition for bar charts:', 'HorizontalAlignment', 'right');
ddOutN = uidropdown(gO, 'Items', {'-'}, 'ValueChangedFcn', @(~, ~) plotOutcomes());
uilabel(gO, 'Text', '');
axSucc = uiaxes(gO); axSucc.Layout.Row = 2; axSucc.Layout.Column = [1 3];
axOE = uiaxes(gO); axOE.Layout.Row = 3; axOE.Layout.Column = 1;
axOW = uiaxes(gO); axOW.Layout.Row = 3; axOW.Layout.Column = [2 3];

% Sensitivity
tS = uitab(rtabs, 'Title', '6 Sensitivity');
gS = uigridlayout(tS, [3 7]); gS.RowHeight = {28, '1x', 120};
gS.ColumnWidth = {'2x', 60, 60, 60, 60, 70, 90};
ddSwParam = uidropdown(gS, 'Items', {'-'}, 'ValueChangedFcn', @(~, ~) onSweepParamChanged());
fSwFrom = uieditfield(gS, 'numeric', 'Value', 0, 'Tooltip', 'From');
fSwTo   = uieditfield(gS, 'numeric', 'Value', 0.5, 'Tooltip', 'To');
fSwN    = uieditfield(gS, 'numeric', 'Value', 11, 'Limits', [2 200], 'RoundFractionalValues', 'on', 'Tooltip', 'Steps');
fSwUsers = uieditfield(gS, 'numeric', 'Value', 300, 'Limits', [2 1e6], 'RoundFractionalValues', 'on', 'Tooltip', 'Users per condition');
fSwSim  = uieditfield(gS, 'numeric', 'Value', 2000, 'Limits', [10 1e6], 'RoundFractionalValues', 'on', 'Tooltip', 'Studies per value');
uibutton(gS, 'Text', 'Run sweep', 'ButtonPushedFcn', @(~, ~) onSweep());
axSwP = uiaxes(gS); axSwP.Layout.Row = 2; axSwP.Layout.Column = [1 3];
axSwS = uiaxes(gS); axSwS.Layout.Row = 2; axSwS.Layout.Column = [4 7];
taSw = uitextarea(gS, 'Editable', 'off', 'FontName', 'Courier New', 'Value', ...
    {'Fields: parameter | from | to | steps | users per condition | studies per value.', ...
     'All other settings are taken from the left panel. The same random seed is used for every value.'});
taSw.Layout.Row = 3; taSw.Layout.Column = [1 7];

% Log
tL = uitab(rtabs, 'Title', '7 Summary & log');
gL = uigridlayout(tL, [1 1]);
taLog = uitextarea(gL, 'Editable', 'off', 'FontName', 'Courier New');

% =======================================================================
writeCfg(S.cfg);
refreshEstimates();
logMsg('Ready. Choose a scenario or edit providers, then press RUN SIMULATION.');
app.figure = fig;
app.getConfig = @() readCfg();
app.getResults = @() S.res;

% =======================================================================
% Callbacks
% =======================================================================
    function onLoadScenario()
        S.cfg = cliox_default_config(ddScen.Value);
        writeCfg(S.cfg);
        refreshEstimates();
        logMsg(sprintf('Loaded scenario "%s".', ddScen.Value));
    end

    function onAddProvider()
        D = tblProv.Data;
        j = size(D, 1) + 1;
        if j > 8, uialert(fig, 'At most 8 providers.', 'Providers'); return; end
        D(j, :) = {sprintf('Provider %c', 'A' + j - 1), 1.0, 90, 1, 1.3, 1.3, 0.4, 0.4, 0.10, 'consumption'};
        tblProv.Data = D;
        refreshEstimates();
    end

    function onRemoveProvider()
        D = tblProv.Data;
        if size(D, 1) <= 2, uialert(fig, 'At least two providers are needed.', 'Providers'); return; end
        tblProv.Data = D(1:end-1, :);
        refreshEstimates();
    end

    function onRun()
        try
            cfg = readCfg();
        catch err
            uialert(fig, err.message, 'Invalid input'); return
        end
        d = uiprogressdlg(fig, 'Title', 'Running Monte Carlo', 'Cancelable', 'on', 'Message', 'Starting...');
        cleanup = onCleanup(@() close(d));
        t0 = tic;
        try
            S.res = cliox_simulate(cfg, @(f, m) progress(d, f, m));
        catch err
            if strcmp(err.identifier, 'cliox:cancelled'), logMsg('Simulation cancelled.'); return; end
            uialert(fig, err.message, 'Simulation error'); return
        end
        S.cfg = cfg;
        logMsg(sprintf('Simulation finished in %.1f s.', toc(t0)));
        showResults();
        rtabs.SelectedTab = tW;
    end

    function stop = progress(d, f, m)
        d.Value = min(1, f);
        d.Message = m;
        drawnow limitrate
        stop = d.CancelRequested;
    end

    function onSelfTest()
        d = uiprogressdlg(fig, 'Title', 'Self-test', 'Indeterminate', 'on', 'Message', 'Checking formulas and statistics...');
        [ok, rep] = cliox_selftest();
        close(d);
        logMsg([{'--- Self-test ---'}; rep(:)]);
        rtabs.SelectedTab = tL;
        if ok, uialert(fig, 'All self-tests passed.', 'Self-test', 'Icon', 'success');
        else, uialert(fig, 'Some self-tests failed: see the log.', 'Self-test'); end
    end

    function onExport()
        if isempty(S.res), uialert(fig, 'Run a simulation first.', 'Export'); return; end
        folder = uigetdir(pwd, 'Choose output folder');
        figure(fig);
        if isequal(folder, 0), return; end
        files = cliox_export(S.res, folder, S.sw);
        tag = regexprep(lower(S.res.cfg.scenario), '[^a-z0-9]+', '_');
        axList = {axRE, axRW, axCh, axPow, axSucc, axOE, axOW, axSwP, axSwS, axRcP, axRcC};
        axName = {'energy', 'water', 'choices', 'power', 'success', 'chosen_energy', 'chosen_water', ...
                  'sweep_power', 'sweep_success', 'receipt_power', 'receipt_energy'};
        for i = 1:numel(axList)
            if isempty(axList{i}.Children), continue; end
            f = fullfile(folder, sprintf('cliox_%s_%s.png', tag, axName{i}));
            try
                exportgraphics(axList{i}, f, 'Resolution', 200);
                files{end+1} = f; %#ok<AGROW>
            catch
            end
        end
        logMsg([{sprintf('Exported %d files to %s', numel(files), folder)}; files(:)]);
    end

    function onSaveCfg()
        try, cfg = readCfg(); catch err, uialert(fig, err.message, 'Invalid input'); return; end
        [f, p] = uiputfile('*.mat', 'Save settings', 'cliox_settings.mat');
        figure(fig);
        if isequal(f, 0), return; end
        save(fullfile(p, f), 'cfg');
        logMsg(sprintf('Settings saved to %s', fullfile(p, f)));
    end

    function onLoadCfg()
        [f, p] = uigetfile('*.mat', 'Load settings');
        figure(fig);
        if isequal(f, 0), return; end
        L = load(fullfile(p, f));
        if ~isfield(L, 'cfg'), uialert(fig, 'File has no "cfg" variable.', 'Load'); return; end
        S.cfg = cliox_migrate_config(L.cfg);
        writeCfg(S.cfg);
        refreshEstimates();
        logMsg(sprintf('Settings loaded from %s', fullfile(p, f)));
    end

    function onCopySummary()
        if isempty(S.res), uialert(fig, 'Run a simulation first.', 'Summary'); return; end
        clipboard('copy', strjoin(cliox_summary(S.res)', newline));
        logMsg('Summary copied to clipboard.');
    end

    function onReceipt()
        try, cfg = readCfg(); catch err, uialert(fig, err.message, 'Invalid input'); return; end
        j = find(strcmp(cfg.prov.name, ddRcProv.Value), 1);
        if isempty(j), j = 1; end
        S.rc = cliox_receipt(cfg, j, fRcSeed.Value);
        cliox_plots('receipt', axRcP, axRcC, S.rc);
        taRc.Value = S.rc.text;
        fRcSeed.Value = fRcSeed.Value + 1;
    end

    function onSweepParamChanged()
        lst = cliox_sweep_params(readCfgSafe());
        k = find(strcmp(lst(:, 1), ddSwParam.Value), 1);
        if ~isempty(k)
            r = lst{k, 3}; fSwFrom.Value = r(1); fSwTo.Value = r(2);
        end
    end

    function onSweep()
        try, cfg = readCfg(); catch err, uialert(fig, err.message, 'Invalid input'); return; end
        lst = cliox_sweep_params(cfg);
        k = find(strcmp(lst(:, 1), ddSwParam.Value), 1);
        if isempty(k), uialert(fig, 'Choose a parameter to sweep.', 'Sweep'); return; end
        cfg.mc.nSim = fSwSim.Value;
        vals = linspace(fSwFrom.Value, fSwTo.Value, fSwN.Value);
        d = uiprogressdlg(fig, 'Title', 'Sensitivity sweep', 'Cancelable', 'on');
        cleanup = onCleanup(@() close(d));
        try
            S.sw = cliox_sweep(cfg, lst{k, 2}, vals, fSwUsers.Value, @(f, m) progress(d, f, m));
        catch err
            if strcmp(err.identifier, 'cliox:cancelled'), logMsg('Sweep cancelled.'); return; end
            uialert(fig, err.message, 'Sweep error'); return
        end
        S.sw.label = lst{k, 1};
        cliox_plots('sweep', axSwP, axSwS, S.sw);
        xlabel(axSwP, lst{k, 1}); xlabel(axSwS, lst{k, 1});
        txt = {sprintf('%s (%s), n = %d per condition, %d studies per value', lst{k, 1}, lst{k, 2}, ...
            S.sw.n, cfg.mc.nSim)};
        for i = 1:numel(vals)
            txt{end+1} = sprintf('%8.3f  labels %-22s est.acc %.2f  power %s', vals(i), S.sw.labels{i}, ...
                S.sw.estimateAccuracy(i), sprintf('%.2f ', S.sw.power(i, :))); %#ok<AGROW>
        end
        taSw.Value = txt;
        logMsg(sprintf('Sweep of %s finished.', lst{k, 1}));
    end

% =======================================================================
% Display helpers
% =======================================================================
    function refreshEstimates()
        try
            cfg = readCfg();
        catch err
            lblCheck.Text = ['Check inputs: ' err.message];
            return
        end
        lblCheck.Text = '';
        est = cliox_estimate(cfg);
        J = numel(est.E);
        D = cell(J, 9);
        na = @(x, v, txt) ternary(isfinite(x), v, txt);
        for j = 1:J
            D{j, 1} = est.name{j};
            D{j, 2} = round(1000 * est.E(j), 3);
            D{j, 3} = na(est.Ef(j), round(1000 * est.Ef(j), 3), 'not available');
            D{j, 4} = na(est.W(j), round(1000 * est.W(j), 3), 'not available');
            D{j, 5} = na(est.pue(j), est.pue(j), 'not reported');
            D{j, 6} = na(est.wue(j), est.wue(j), 'not reported');
            D{j, 7} = na(est.R(j), round(est.R(j), 3), 'cannot be established');
            D{j, 8} = est.labels{j};
            D{j, 9} = na(est.wue(j), cfg.prov.wueDef{j}, '-');
        end
        tblEst.Data = D;
        cliox_plots('resources', axRE, axRW, est);
        ddRcProv.Items = cfg.prov.name;
        lst = cliox_sweep_params(cfg);
        old = ddSwParam.Value;
        ddSwParam.Items = lst(:, 1)';
        if any(strcmp(lst(:, 1), old))
            ddSwParam.Value = old;
        else
            onSweepParamChanged();
        end
        refreshChoices();
    end

    function refreshChoices()
        try, cfg = readCfg(); catch, return; end
        est = cliox_estimate(cfg);
        P = cliox_choice_probs(cfg, est);
        txt = {'Choice probabilities from the current settings (before running):', ...
               sprintf('%-16s %s', 'Condition', sprintf('%-14s', est.name{:}))};
        for c = find(cfg.cond.include)
            txt{end+1} = sprintf('%-16s %s', cfg.cond.name{c}, sprintf('%-14.3f', P(c, :))); %#ok<AGROW>
        end
        txt{end+1} = sprintf('Estimates identify %s as lowest (%s criterion).', est.name{est.best}, cfg.truth.criterion);
        taCh.Value = txt;
    end

    function showResults()
        r = S.res;
        cliox_plots('choices', axCh, r);
        cliox_plots('power', axPow, r);
        cliox_plots('success', axSucc, r);
        txt = taCh.Value;
        if ischar(txt), txt = {txt}; end
        txt = [txt(:); {''; sprintf('Simulated: estimates pick the true best in %.1f%% of studies.', ...
            100 * r.truth.estimateAccuracy)}; {sprintf('Expected success: %s', ...
            strjoin(cellfun(@(n, v) sprintf('%s %.1f%%', n, 100 * v), r.cfg.cond.name(r.cfg.cond.include), ...
            num2cell(r.expSucc(r.cfg.cond.include)), 'UniformOutput', false), ' | '))}];
        taCh.Value = txt;
        g = numel(r.n);
        K = numel(r.cmp.a);
        D = cell(K, 9);
        for k = 1:K
            D{k, 1} = r.cmp.name{k};
            D{k, 2} = round(100 * r.diffMean(g, k), 1);
            D{k, 3} = round(r.power(g, k), 3);
            D{k, 4} = round(r.powerBenefit(g, k), 3);
            D{k, 5} = round(r.powerHarm(g, k), 3);
            if isnan(r.nRequired(k)), D{k, 6} = sprintf('> %d', r.n(end)); else, D{k, 6} = r.nRequired(k); end
            D{k, 7} = r.nAnalytic(k);
            D{k, 8} = round(1000 * r.dEmean(g, k), 3);
            D{k, 9} = round(1000 * r.dWmean(g, k), 3);
        end
        tblPow.Data = D;
        ddOutN.Items = arrayfun(@num2str, r.n, 'UniformOutput', false);
        ddOutN.Value = ddOutN.Items{end};
        plotOutcomes();
        logMsg(cliox_summary(r));
    end

    function plotOutcomes()
        if isempty(S.res), return; end
        g = find(strcmp(ddOutN.Items, ddOutN.Value), 1);
        if isempty(g), g = numel(S.res.n); end
        cliox_plots('outcomes', axOE, axOW, S.res, g);
    end

    function logMsg(m)
        if ischar(m), m = {m}; end
        stamp = datestr(now, 'HH:MM:SS');
        old = taLog.Value;
        if ischar(old), old = {old}; end
        taLog.Value = [old(:); {sprintf('[%s]', stamp)}; m(:)];
        try, scroll(taLog, 'bottom'); catch, end
    end

% =======================================================================
% Config <-> widgets
% =======================================================================
    function writeCfg(cfg)
        ddScen.Value = pick(cliox_scenarios(), cfg.scenario);
        lblDesc.Text = cfg.description;
        p = cfg.prov; J = numel(p.powerKW);
        D = cell(J, 10);
        for j = 1:J
            D(j, :) = {p.name{j}, p.powerKW(j), p.durationS(j), p.share(j), p.pue(j), p.pueTrue(j), ...
                       p.wue(j), p.wueTrue(j), p.cost(j), p.wueDef{j}};
        end
        tblProv.Data = D;
        fDt.Value = cfg.telemetry.dtS;   fJit.Value = cfg.telemetry.jitterCV;
        fPcv.Value = cfg.uncert.powerCV; fDcv.Value = cfg.uncert.durationCV; fWcv.Value = cfg.uncert.wueCV;
        fUcv.Value = cfg.uncert.pueCV; ddBasis.Value = cfg.index.energyBasis; fErefIT.Value = cfg.index.ErefIT;
        ddTBasis.Value = cfg.truth.energyBasis;
        fW.Value = cfg.index.energyWeight; ddRef.Value = cfg.index.refMode;
        fEref.Value = cfg.index.Eref; fWref.Value = cfg.index.Wref;
        fLow.Value = cfg.index.lowThr; fHigh.Value = cfg.index.highThr;
        ddCrit.Value = cfg.truth.criterion;
        C = numel(cfg.cond.name);
        D = cell(C, 5);
        for c = 1:C
            D(c, :) = {cfg.cond.name{c}, cfg.cond.type{c}, logical(cfg.cond.include(c)), ...
                       cfg.cond.attention(c), cfg.cond.beta(c)};
        end
        tblCond.Data = D;
        fCost.Value = cfg.choice.costSensitivity; fPos.Value = cfg.choice.positionBias;
        fMissF.Value = cfg.choice.missingFactor;  fMissL.Value = cfg.choice.missingLabel;
        fGrid.Value = num2str(cfg.mc.nGrid);
        fNsim.Value = cfg.mc.nSim; fAlpha.Value = cfg.mc.alpha; fTarget.Value = cfg.mc.targetPower;
        fSeed.Value = cfg.mc.seed; ddSides.Value = cfg.mc.sides; ddCorr.Value = cfg.mc.correction;
        ddCmp.Value = cfg.mc.comparisons; fChunk.Value = cfg.mc.chunk;
    end

    function cfg = readCfg()
        cfg = S.cfg;
        D = tblProv.Data;
        J = size(D, 1);
        num = @(col) cellfun(@toNum, D(:, col))';
        cfg.prov.name      = cellfun(@(x) char(x), D(:, 1), 'UniformOutput', false)';
        cfg.prov.powerKW   = num(2);
        cfg.prov.durationS = num(3);
        cfg.prov.share     = num(4);
        cfg.prov.pue       = num(5);
        cfg.prov.pueTrue   = num(6);
        cfg.prov.wue       = num(7);
        cfg.prov.wueTrue   = num(8);
        cfg.prov.cost      = num(9);
        cfg.prov.wueDef    = cellfun(@(x) char(x), D(:, 10), 'UniformOutput', false)';
        if numel(unique(cfg.prov.name)) < J, error('cliox:input', 'Provider names must be unique.'); end
        cfg.telemetry.dtS = fDt.Value; cfg.telemetry.jitterCV = fJit.Value;
        cfg.uncert.powerCV = fPcv.Value; cfg.uncert.durationCV = fDcv.Value; cfg.uncert.wueCV = fWcv.Value;
        cfg.uncert.pueCV = fUcv.Value; cfg.index.energyBasis = ddBasis.Value; cfg.index.ErefIT = fErefIT.Value;
        cfg.truth.energyBasis = ddTBasis.Value;
        cfg.index.energyWeight = fW.Value; cfg.index.refMode = ddRef.Value;
        cfg.index.Eref = fEref.Value; cfg.index.Wref = fWref.Value;
        cfg.index.lowThr = fLow.Value; cfg.index.highThr = fHigh.Value;
        cfg.truth.criterion = ddCrit.Value;
        C = tblCond.Data;
        cfg.cond.include   = logical(cellfun(@toNum, C(:, 3)))';
        cfg.cond.attention = cellfun(@toNum, C(:, 4))';
        cfg.cond.beta      = cellfun(@toNum, C(:, 5))';
        cfg.choice.costSensitivity = fCost.Value; cfg.choice.positionBias = fPos.Value;
        cfg.choice.missingFactor = fMissF.Value; cfg.choice.missingLabel = fMissL.Value;
        g = str2num(fGrid.Value); %#ok<ST2NM>
        if isempty(g) || any(~isfinite(g)), error('cliox:input', 'Users-per-condition list is not valid.'); end
        cfg.mc.nGrid = sort(unique(round(g(:)')));
        cfg.mc.nSim = round(fNsim.Value); cfg.mc.alpha = fAlpha.Value; cfg.mc.targetPower = fTarget.Value;
        cfg.mc.seed = round(fSeed.Value); cfg.mc.sides = ddSides.Value; cfg.mc.correction = ddCorr.Value;
        cfg.mc.comparisons = ddCmp.Value; cfg.mc.chunk = round(fChunk.Value);
        cfg.scenario = ddScen.Value;
        cliox_validate(cfg);
    end

    function cfg = readCfgSafe()
        try, cfg = readCfg(); catch, cfg = S.cfg; end
    end

% =======================================================================
% Layout helpers (grid rows are filled in order)
% =======================================================================
    function f = numField(g, label, val, lim)
        uilabel(g, 'Text', label);
        f = uieditfield(g, 'numeric', 'Value', val, 'Limits', lim, ...
            'ValueChangedFcn', @(~, ~) refreshEstimates());
    end

    function d = ddField(g, label, items, val)
        uilabel(g, 'Text', label);
        d = uidropdown(g, 'Items', items, 'Value', val, 'ValueChangedFcn', @(~, ~) refreshEstimates());
    end

    function hdr(g, txt)
        h = uilabel(g, 'Text', txt, 'FontWeight', 'bold');
        h.Layout.Column = [1 2];
    end
end

% -----------------------------------------------------------------------
function v = toNum(x)
if isnumeric(x) || islogical(x)
    v = double(x);
    if isempty(v), v = NaN; end
elseif ischar(x) || isstring(x)
    x = strtrim(char(x));
    if isempty(x) || any(strcmpi(x, {'nan', 'na', 'n/a', '-'})), v = NaN; else, v = str2double(x); end
else
    v = NaN;
end
end

function o = ternary(c, a, b)
if c, o = a; else, o = b; end
end

function v = pick(items, val)
if any(strcmp(items, val)), v = val; else, v = items{1}; end
end
