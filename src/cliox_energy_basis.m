function Eb = cliox_energy_basis(E_IT, E_fac, basis)
%CLIOX_ENERGY_BASIS  Pick IT or facility electricity.
if strcmpi(basis, 'IT')
    Eb = E_IT;
elseif strcmpi(basis, 'facility')
    Eb = E_fac;
else
    error('cliox:basis', 'Unknown electricity basis "%s" (use ''facility'' or ''IT'').', basis);
end
end
