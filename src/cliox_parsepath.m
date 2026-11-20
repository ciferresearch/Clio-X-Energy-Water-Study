function [fields, idx] = cliox_parsepath(path)
%CLIOX_PARSEPATH  Split 'cond.attention(4)' into {'cond','attention'} and 4.
%   No regular expressions, so MATLAB and Octave behave identically.
path = strtrim(char(path));
idx = [];
p = find(path == '(', 1);
if ~isempty(p)
    q = find(path == ')', 1, 'last');
    if isempty(q) || q < p
        error('cliox:path', 'Bad parameter path "%s".', path);
    end
    idx = str2double(path(p+1:q-1));
    if ~isfinite(idx) || idx < 1 || idx ~= round(idx)
        error('cliox:path', 'Bad index in parameter path "%s".', path);
    end
    path = path(1:p-1);
end
fields = strsplit(path, '.');
if isempty(path) || any(cellfun(@isempty, fields))
    error('cliox:path', 'Bad parameter path "%s".', path);
end
end
