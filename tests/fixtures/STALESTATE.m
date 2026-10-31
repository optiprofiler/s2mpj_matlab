function varargout = STALESTATE(action, varargin)
%STALESTATE Test-only model: setup fills persistent data by index, as native files do.
    persistent pbm
    if strcmp(action, 'setup')
        n = varargin{1};
        pbm.weights(1:n) = 1:n;
        varargout = {struct('n', n, 'm', 0, 'x0', ones(n, 1), ...
            'xlower', -Inf(n, 1), 'xupper', Inf(n, 1))};
    elseif strcmp(action, 'fx')
        varargout = {sum(pbm.weights)};
    else
        error('S2MPJ:FixtureAction', 'Unexpected fixture action.');
    end
end
