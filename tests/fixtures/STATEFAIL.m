function varargout = STATEFAIL(action, varargin)
%STATEFAIL Test-only native function with an intentionally non-atomic setup.
    persistent scale
    if strcmp(action, 'setup')
        scale = varargin{1};
        if scale < 0
            error('S2MPJ:FixtureSetupFailure', 'Setup failed after changing native state.');
        end
        varargout{1} = struct('n', 2, 'm', 0, 'x0', ones(2,1), ...
            'xlower', [-Inf;-Inf], 'xupper', [Inf;Inf]);
        return
    end
    x = varargin{1};
    switch action
        case 'fx'
            varargout = {scale * sum(x.^2)};
        case 'fgx'
            varargout = {scale * sum(x.^2), 2*scale*x};
        case 'fgHx'
            varargout = {scale * sum(x.^2), 2*scale*x, 2*scale*eye(numel(x))};
        otherwise
            error('S2MPJ:FixtureAction', 'Unexpected fixture action.');
    end
end
