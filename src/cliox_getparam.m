function v = cliox_getparam(cfg, path)
%CLIOX_GETPARAM  Read a parameter by path (see cliox_setparam).
[fields, idx] = cliox_parsepath(path);
v = getfield(cfg, fields{:}); %#ok<GFLD>
if ~isempty(idx), v = v(idx); end
end
