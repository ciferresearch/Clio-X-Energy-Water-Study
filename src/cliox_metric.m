function m = cliox_metric(E, W, R, criterion)
%CLIOX_METRIC  Quantity that defines the "lowest-resource" provider.
switch lower(criterion)
    case 'combined', m = R;
    case 'energy',   m = E;
    case 'water',    m = W;
    otherwise, error('cliox:criterion', 'Unknown criterion "%s".', criterion);
end
end
