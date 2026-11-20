function cfg = cliox_default_config(scenario)
%CLIOX_DEFAULT_CONFIG  Default parameters for the Clio-X transparency simulation.
%   cfg = cliox_default_config()            -> 'WUE trap' scenario
%   cfg = cliox_default_config('Dominant')  -> see cliox_scenarios() for names
%
%   All provider values are SYNTHETIC illustrations, not provider claims.
%   Units: power kW, duration s, PUE dimensionless, WUE L/kWh of IT
%   electricity, energy kWh, water L, cost $ per transaction.
%
%   Electricity boundaries (paper Sec. III-A):
%     IT electricity        E_IT  = sum_k P_k * dt_k * s_k
%     facility electricity  E_fac = E_IT * PUE      (shown to users, Fig. 1)
%     water                 W     = E_IT * WUE      (WUE is per kWh of IT electricity)

if nargin < 1 || isempty(scenario), scenario = 'WUE trap'; end

cfg.version  = '2.0';
cfg.scenario = scenario;

nm = {'Provider A', 'Provider B', 'Provider C'};
switch lower(scenario)
    case 'dominant'
        % Provider A is lowest on IT electricity, facility electricity and water.
        p.powerKW = [0.8 1.6 2.4];   p.durationS = [90 90 90];   p.share = [1 1 1];
        p.pue     = [1.20 1.30 1.50]; p.wue      = [0.36 0.45 0.60];
        desc = ['Provider A is lowest on electricity and water. ', ...
                'Baseline check of the estimation-to-rating pipeline.'];
    case 'wue trap'
        % B reports the LOWEST WUE but uses the MOST electricity, so its
        % transaction water is not lowest: a WUE-only display misleads.
        p.powerKW = [0.8 2.4 1.6];   p.durationS = [90 90 90];   p.share = [1 1 1];
        p.pue     = [1.30 1.20 1.25]; p.wue      = [0.50 0.30 0.40];
        desc = ['B reports the lowest WUE but uses the most electricity, so ', ...
                'its transaction water is not lowest. A WUE-only display misleads.'];
    case 'pue trap'
        % A uses the least IT electricity but has a high PUE, so B uses the
        % least FACILITY electricity. A display of IT electricity alone misleads.
        p.powerKW = [1.2 1.44 2.4];  p.durationS = [90 90 90];   p.share = [1 1 1];
        p.pue     = [1.95 1.10 1.40]; p.wue      = [0.30 0.26 0.45];
        desc = ['A uses the least IT electricity but has a high PUE, so B uses ', ...
                'the least facility electricity. An IT-only display misleads.'];
    case 'trade-off'
        % No provider is lowest on both: A lowest electricity, B lowest water.
        p.powerKW = [0.8 1.6 2.4];   p.durationS = [90 90 90];   p.share = [1 1 1];
        p.pue     = [1.20 1.20 1.30]; p.wue      = [0.90 0.20 0.45];
        desc = ['Electricity-water trade-off: A lowest electricity, B lowest water. ', ...
                'The "best" provider depends on the declared criterion and weights.'];
    case 'missing wue'
        % Same as Dominant, but A does not report WUE (shown as N/A, never 0).
        p.powerKW = [0.8 1.6 2.4];   p.durationS = [90 90 90];   p.share = [1 1 1];
        p.pue     = [1.20 1.30 1.50]; p.wue      = [NaN 0.45 0.60];
        desc = ['A is truly lowest but does not report WUE: its water and ', ...
                'rating "cannot be established".'];
    case 'shared gpu'
        % Shared pools and different durations: exercises s_ik and dt_k.
        nm = {'Shared GPU pool', 'Dedicated GPU', 'Fractional GPU'};
        p.powerKW = [6.4 1.2 3.2];    p.durationS = [180 90 60]; p.share = [0.125 1 0.5];
        p.pue     = [1.15 1.60 1.30]; p.wue       = [0.40 0.55 0.20];
        desc = ['Shared and fractional infrastructure with different run ', ...
                'times: allocation by resource share and execution time.'];
    otherwise
        error('cliox:scenario', 'Unknown scenario "%s". See cliox_scenarios().', scenario);
end
p.name    = nm;
% Values used only for the simulated ground truth when an input is not reported.
p.wueTrue = p.wue;  p.wueTrue(isnan(p.wue)) = 0.36;
p.pueTrue = p.pue;  p.pueTrue(isnan(p.pue)) = 1.20;
p.cost    = 0.10 * ones(1, numel(p.powerKW));   % held constant by default
p.wueDef  = repmat({'consumption'}, 1, numel(p.powerKW));
cfg.prov  = p;
cfg.description = desc;

% --- Telemetry (paper: 1-10 s intervals) -------------------------------
cfg.telemetry.dtS      = 10;    % interval length, s
cfg.telemetry.jitterCV = 0.10;  % interval-to-interval power variation (receipt demo)

% --- Pre-execution estimate error (truth vs displayed estimate) --------
% Each simulated study draws "true" values = estimate x lognormal multiplier
% (mean 1). Ratings built from pre-execution estimates may therefore not
% identify the truly lowest provider.
cfg.uncert.powerCV    = 0.10;
cfg.uncert.durationCV = 0.10;
cfg.uncert.wueCV      = 0.10;   % effective vs annual-average WUE
cfg.uncert.pueCV      = 0.05;   % effective vs annual-average PUE

% --- Combined index and ratings (design choice, NOT from the paper) -----
%   R = w * E/Eref + (1-w) * W/Wref, with E on the chosen electricity basis.
%   One set of reference values is used for every scenario.
cfg.index.energyBasis  = 'facility';  % electricity shown to users: 'facility' | 'IT'
cfg.index.energyWeight = 0.5;
cfg.index.refMode      = 'fixed';     % 'fixed' or 'mean' (mean of providers' estimates)
cfg.index.Eref         = 0.050;       % kWh of FACILITY electricity (50 Wh)
cfg.index.ErefIT       = 0.040;       % kWh of IT electricity (40 Wh), used when basis = 'IT'
cfg.index.Wref         = 0.015;       % L (15 mL)
cfg.index.lowThr       = 0.75;        % R <  lowThr  -> Low
cfg.index.highThr      = 1.25;        % R >= highThr -> High

% --- Definition of the "correct" choice --------------------------------
cfg.truth.criterion   = 'combined';   % 'combined' | 'energy' | 'water'
cfg.truth.energyBasis = 'facility';   % electricity that defines the true best provider

% --- Experimental conditions (between-subjects) ------------------------
cfg.cond.name      = {'Control', 'WUE only', 'Numeric E & W', 'Rating L/M/H'};
cfg.cond.type      = {'none',    'wue',      'numeric',       'label'};
cfg.cond.include   = [true true true true];
cfg.cond.attention = [0 0.25 0.25 0.25];  % share of users who use the displayed info
cfg.cond.beta      = [0 6 6 4];           % sensitivity to the displayed info (logit)

% --- Choice model ------------------------------------------------------
cfg.choice.costSensitivity = 0;     % utility weight on normalised cost
cfg.choice.positionBias    = 0.3;   % utility bonus for top display slot (orders randomised)
cfg.choice.missingFactor   = 1.0;   % unavailable numeric value scored as factor x worst shown
cfg.choice.missingLabel    = 2.5;   % score of an "N/A" rating (Low=1, Medium=2, High=3)

% --- Monte Carlo / statistics ------------------------------------------
cfg.mc.nGrid       = [50 100 150 200 300 400 500 650 800];  % users per condition
cfg.mc.nSim        = 4000;          % simulated studies per configuration
cfg.mc.alpha       = 0.05;
cfg.mc.targetPower = 0.90;
cfg.mc.seed        = 20261030;
cfg.mc.sides       = 'two-sided';   % 'two-sided' | 'one-sided'
cfg.mc.correction  = 'Holm';        % 'None' | 'Bonferroni' | 'Holm'
cfg.mc.comparisons = 'vs Control + vs WUE';  % | 'vs Control' | 'All pairs'
cfg.mc.chunk       = 1000;          % studies processed per block (memory)
end
