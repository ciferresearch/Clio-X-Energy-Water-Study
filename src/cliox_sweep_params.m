function list = cliox_sweep_params(cfg)
%CLIOX_SWEEP_PARAMS  Parameters available for one-at-a-time sensitivity sweeps.
%   list: N x 3 cell {label, path, [suggested min max]}
list = {};
for k = 1:numel(cfg.cond.name)
    if strcmpi(cfg.cond.type{k}, 'none'), continue; end
    list(end+1, :) = {sprintf('Attention: %s', cfg.cond.name{k}), sprintf('cond.attention(%d)', k), [0 0.6]}; %#ok<AGROW>
    list(end+1, :) = {sprintf('Sensitivity beta: %s', cfg.cond.name{k}), sprintf('cond.beta(%d)', k), [0 12]}; %#ok<AGROW>
end
list = [list; {
    'Estimate error: power CV',      'uncert.powerCV',        [0 0.5];
    'Estimate error: duration CV',   'uncert.durationCV',     [0 0.5];
    'Estimate error: WUE CV',        'uncert.wueCV',          [0 0.5];
    'Estimate error: PUE CV',        'uncert.pueCV',          [0 0.3];
    'Index energy weight',           'index.energyWeight',    [0 1];
    'Low-rating threshold',           'index.lowThr',          [0.5 1.0];
    'High-rating threshold',          'index.highThr',         [1.0 2.0];
    'Position bias',                 'choice.positionBias',   [0 1.5];
    'Cost sensitivity',              'choice.costSensitivity',[0 3];
    'N/A rating score',               'choice.missingLabel',   [1 3];
    'Missing numeric factor',        'choice.missingFactor',  [0.5 2]}];
for j = 1:numel(cfg.prov.powerKW)
    nm = cfg.prov.name{j};
    list(end+1, :) = {sprintf('WUE: %s', nm),        sprintf('prov.wue(%d)', j),       [0.1 1.0]}; %#ok<AGROW>
    list(end+1, :) = {sprintf('PUE: %s', nm),        sprintf('prov.pue(%d)', j),       [1.05 2.0]}; %#ok<AGROW>
    list(end+1, :) = {sprintf('IT power: %s', nm),   sprintf('prov.powerKW(%d)', j),   [0.2 4]}; %#ok<AGROW>
    list(end+1, :) = {sprintf('Duration: %s', nm),   sprintf('prov.durationS(%d)', j), [20 200]}; %#ok<AGROW>
    list(end+1, :) = {sprintf('Share: %s', nm),      sprintf('prov.share(%d)', j),     [0.1 1]}; %#ok<AGROW>
    list(end+1, :) = {sprintf('Cost: %s', nm),       sprintf('prov.cost(%d)', j),      [0.05 0.2]}; %#ok<AGROW>
end
end
