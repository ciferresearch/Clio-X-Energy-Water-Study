function cfg = cliox_setparam(cfg, path, val)
%CLIOX_SETPARAM  Set a parameter by path, e.g. 'uncert.powerCV' or 'cond.attention(4)'.
[fields, idx] = cliox_parsepath(path);
cur = getfield(cfg, fields{:}); %#ok<GFLD>
if isempty(idx)
    cur = val;
else
    if idx > numel(cur)
        error('cliox:path', 'Index %d exceeds the %d elements of "%s".', idx, numel(cur), path);
    end
    cur(idx) = val;
end
cfg = setfield(cfg, fields{:}, cur); %#ok<SFLD>
end
