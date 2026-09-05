function varargout = ADAPTERCONSTRAINTS(action, x)
%ADAPTERCONSTRAINTS Test-only upper, two-sided, equality, lower and linear rows.
    H = {[2, 0; 0, 4], [0, 1; 1, 6], [8, 0; 0, 10], ...
        [12, 2; 2, 14], zeros(2)};
    linear = [zeros(4, 2); 1, -2];
    if strcmp(action, 'setup')
        varargout{1} = struct('n', 2, 'm', 5, 'nle', 2, 'neq', 1, ...
            'nge', 2, 'lincons', 5, 'x0', [0.7; -0.4], ...
            'xlower', [-Inf; -Inf], 'xupper', [Inf; Inf], ...
            'clower', [-Inf; -3; 1; 2; -Inf], 'cupper', [4; 5; 1; Inf; 7]);
        return;
    end
    c = zeros(5, 1);
    J = zeros(5, 2);
    for k = 1:5
        c(k) = x' * H{k} * x / 2 + linear(k, :) * x;
        J(k, :) = (H{k} * x)' + linear(k, :);
    end
    switch action
        case 'cx'
            varargout = {c};
        case 'cJx'
            varargout = {c, J};
        case 'cJHx'
            varargout = {c, J, H};
        otherwise
            error('S2MPJ:TestFixture', 'Unexpected action %s.', action);
    end
end
