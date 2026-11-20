function [P, Z] = cliox_choice_probs(cfg, est)
%CLIOX_CHOICE_PROBS  Probability that a user in each condition picks each provider.
%   Random-utility (multinomial logit) model with an attention mixture:
%     V_j  = -gamma*cost_j/mean(cost) + positionBias*(top-slot score) + eps
%     users who attend to the display add  -beta_c * z_cj
%   P(c,:) = attention_c * P_info + (1-attention_c) * P_noinfo.
%   Display order is randomised per user, so probabilities are averaged
%   over all orderings. z depends on what the condition displays:
%     'none'    nothing
%     'wue'     annual-average WUE only (normalised by its mean)
%     'numeric' combined index R from E and W estimates
%     'label'   ordinal label Low=1, Medium=2, High=3
%   Unavailable values: numeric -> missingFactor x worst shown value,
%   label 'N/A' -> cfg.choice.missingLabel.

c  = cfg.choice;
J  = numel(est.E);
C  = numel(cfg.cond.name);
if J > 8, error('cliox:J', 'At most 8 providers are supported.'); end

cost = cfg.prov.cost;
if mean(cost) > 0, cost = cost / mean(cost); end
V0 = -c.costSensitivity * cost;

ord = perms(1:J);                  % each row: provider shown in slot 1..J
nP  = size(ord, 1);
slotScore = (J - (1:J)) / max(J - 1, 1);   % 1 for top slot ... 0 for last
posU = zeros(nP, J);
for r = 1:nP
    posU(r, ord(r, :)) = c.positionBias * slotScore;
end

Pno = avgSoftmax(bsxfun(@plus, posU, V0));
P = zeros(C, J);
Z = nan(C, J);
for k = 1:C
    switch lower(cfg.cond.type{k})
        case 'none'
            P(k, :) = Pno;
            continue
        case 'wue'
            z = est.wue / mean(est.wue(isfinite(est.wue)));
            z(~isfinite(z)) = c.missingFactor * max(z(isfinite(z)));
        case 'numeric'
            z = est.R;
            z(~isfinite(z)) = c.missingFactor * max(z(isfinite(z)));
        case 'label'
            z = est.level;
            z(~isfinite(z)) = c.missingLabel;
        otherwise
            error('cliox:type', 'Unknown condition type "%s".', cfg.cond.type{k});
    end
    if isempty(z) || all(~isfinite(z)), z = zeros(1, J); end
    Z(k, :) = z;
    Pinfo = avgSoftmax(bsxfun(@plus, posU, V0 - cfg.cond.beta(k) * z));
    a = cfg.cond.attention(k);
    P(k, :) = a * Pinfo + (1 - a) * Pno;
end
end

function p = avgSoftmax(U)
U = bsxfun(@minus, U, max(U, [], 2));
e = exp(U);
p = mean(bsxfun(@rdivide, e, sum(e, 2)), 1);
end
