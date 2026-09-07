function varargout = GROUPEDPRODUCTS(action, value, ~)
%GROUPEDPRODUCTS Nontrivial native group function used only by product tests.
    assert(strcmp(action, 'square'));
    outputs = {value^2, 2*value, 2};
    varargout = outputs(1:nargout);
end
