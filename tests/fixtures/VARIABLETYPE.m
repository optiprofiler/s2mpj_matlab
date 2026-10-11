function varargout = VARIABLETYPE(action, varargin)
%VARIABLETYPE Test-only model for the continuous variable-domain contract.
    if strcmp(action, 'setup')
        pb = struct('n', 2, 'm', 0, 'x0', [0;1], ...
            'xlower', [-Inf;-Inf], 'xupper', [Inf;Inf]);
        if ~strcmp(varargin{1}, 'absent')
            pb.xtype = varargin{1};
        end
        varargout = {pb};
    elseif strcmp(action, 'fx')
        varargout = {sum(varargin{1}.^2)};
    else
        error('S2MPJ:UnexpectedEvaluation', 'No derivative/constraint probe is needed.');
    end
end
