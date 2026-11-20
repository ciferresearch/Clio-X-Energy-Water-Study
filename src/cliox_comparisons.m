function cmp = cliox_comparisons(cfg)
%CLIOX_COMPARISONS  Hypothesis tests (treatment a vs reference b) for the family.
%   cfg.mc.comparisons: 'vs Control' | 'vs Control + vs WUE' | 'All pairs'

inc  = find(cfg.cond.include);
type = cfg.cond.type;
ctl  = inc(strcmpi(type(inc), 'none'));
wue  = inc(strcmpi(type(inc), 'wue'));
info = inc(~strcmpi(type(inc), 'none'));
a = []; b = [];
mode = lower(cfg.mc.comparisons);
if strcmp(mode, 'all pairs')
    for i = 1:numel(inc)
        for j = i+1:numel(inc)
            a(end+1) = inc(j); b(end+1) = inc(i); %#ok<AGROW>
        end
    end
else
    if ~isempty(ctl)
        for k = info, a(end+1) = k; b(end+1) = ctl(1); end %#ok<AGROW>
    end
    if strcmp(mode, 'vs control + vs wue') && ~isempty(wue)
        for k = info
            if k ~= wue(1), a(end+1) = k; b(end+1) = wue(1); end %#ok<AGROW>
        end
    end
end
cmp.a = a;
cmp.b = b;
cmp.name = cell(1, numel(a));
for k = 1:numel(a)
    cmp.name{k} = sprintf('%s vs %s', cfg.cond.name{a(k)}, cfg.cond.name{b(k)});
end
end
