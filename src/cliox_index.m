function [R, labels, level, Eref, Wref] = cliox_index(E, W, idx, basis)
%CLIOX_INDEX  Dimensionless combined resource index and Low/Medium/High ratings.
%   R = w*E/Eref + (1-w)*W/Wref, where E is IT or facility electricity
%   (basis) and Eref is the reference for that same basis, so each ratio
%   is unit-free (kWh/kWh and L/L). This index and its thresholds are an
%   experimental design choice declared here; they are not part of the
%   paper's estimation method. A missing input gives R = NaN and 'N/A'.

if nargin < 4, basis = idx.energyBasis; end
w = idx.energyWeight;
if strcmpi(idx.refMode, 'mean')
    Eref = mean(E(isfinite(E)));
    Wref = mean(W(isfinite(W)));
else
    Eref = cliox_eref(idx, basis);
    Wref = idx.Wref;
end
if w >= 1
    R = E / Eref;
elseif w <= 0
    R = W / Wref;
else
    R = w * E / Eref + (1 - w) * W / Wref;
end

J = numel(E);
labels = repmat({'Medium'}, 1, J);
level  = 2 * ones(1, J);
labels(R <  idx.lowThr)  = {'Low'};   level(R <  idx.lowThr)  = 1;
labels(R >= idx.highThr) = {'High'};  level(R >= idx.highThr) = 3;
bad = ~isfinite(R);
labels(bad) = {'N/A'};
level(bad)  = NaN;
end
