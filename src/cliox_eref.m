function Eref = cliox_eref(idx, basis)
%CLIOX_EREF  Fixed electricity reference for the given basis ('facility' or 'IT').
if strcmpi(basis, 'IT')
    Eref = idx.ErefIT;
else
    Eref = idx.Eref;
end
end
