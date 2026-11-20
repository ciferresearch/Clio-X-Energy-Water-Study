function cfg = cliox_migrate_config(cfg)
%CLIOX_MIGRATE_CONFIG  Bring settings saved by version 1.x (IT electricity only) up to 2.0.
%   Version 1.x had no PUE, so a loaded 1.x file is migrated with PUE = 1
%   and the IT electricity basis, which reproduces its original results.
d = cliox_default_config(cfg.scenario);
J = numel(cfg.prov.powerKW);
if ~isfield(cfg.prov, 'pue'),     cfg.prov.pue = ones(1, J);     end
if ~isfield(cfg.prov, 'pueTrue'), cfg.prov.pueTrue = cfg.prov.pue; cfg.prov.pueTrue(isnan(cfg.prov.pue)) = 1; end
if ~isfield(cfg.uncert, 'pueCV'), cfg.uncert.pueCV = 0; end
if ~isfield(cfg.index, 'energyBasis')
    cfg.index.energyBasis = 'IT';
    cfg.index.ErefIT = cfg.index.Eref;
    cfg.truth.energyBasis = 'IT';
end
if ~isfield(cfg.index, 'ErefIT'), cfg.index.ErefIT = d.index.ErefIT; end
if ~isfield(cfg.truth, 'energyBasis'), cfg.truth.energyBasis = cfg.index.energyBasis; end
cfg.version = d.version;
end
