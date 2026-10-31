function varargout = NATIVEMETADATA(action, varargin)
%NATIVEMETADATA Test-only model: one linear row, then one nonlinear equality.
%   The setup argument names a scenario that overrides part of the metadata.
    persistent scenario
    if strcmp(action, 'setup')
        scenario = varargin{1};
        pb = struct('name', 'NATIVEMETADATA', 'n', 2, 'm', 2, 'x0', [1;2], ...
            'xlower', [-1e20;-1e20], 'xupper', [1e20;1e20], ...
            'clower', [-1e20;0], 'cupper', [3;0], 'lincons', 1, ...
            'nle', 1, 'neq', 1, 'nge', 0);
        switch scenario
            case 'nan-cupper', pb.cupper = [NaN;0];
            case 'nan-clower', pb.clower = [NaN;0];
            case 'nan-xlower', pb.xlower = [NaN;-1e20];
            case 'nan-xupper', pb.xupper = [1e20;NaN];
            case 'nan-x0', pb.x0 = [NaN;2];
            case 'short-cupper', pb.cupper = 3;
            case 'matrix-cupper', pb.cupper = zeros(2);
            case 'text-cupper', pb.cupper = 'ab';
            case 'missing-cupper', pb = rmfield(pb, 'cupper');
            case 'impossible-xlower', pb.xlower = [Inf;-1e20];
            case 'impossible-xupper', pb.xupper = [-Inf;1e20];
            case 'impossible-clower', pb.clower = [Inf;0];
            case 'impossible-cupper', pb.cupper = [-Inf;0];
            case 'sentinel-xlower', pb.xlower = [1e20;-1e20];
            case 'sentinel-cupper', pb.cupper = [-1e20;0];
            case 'crossed-variable-bounds', pb.xlower = [2;-1e20]; pb.xupper = [1;1e20];
            case 'crossed-constraint-bounds', pb.clower = [4;0];
            case 'unequal-equality', pb.cupper = [3;1];
            case 'free-equality', pb.clower = [-1e20;-1e20];
            case 'equality-out-of-range', pb.nle = 2;
            case 'row-bounds', pb.clower = [-1e20,0]; pb.cupper = [3,0]; pb.x0 = [1,2];
            case 'no-linear-rows', pb.lincons = [];
            case 'free-row', pb.cupper = [1e20;0];
        end
        varargout = {pb};
    elseif strcmp(action, 'fx')
        varargout = {sum(varargin{1}.^2)};
    elseif strcmp(action, 'cx')
        varargout = {values(varargin{1})};
    elseif strcmp(action, 'cJx')
        x = varargin{1};
        jacobian = [1, 2; 2 * x(1), -1];
        switch scenario
            case {'jacobian-error', 'no-linear-rows', 'free-row'}
                error('NATIVEMETADATA:Jacobian', 'Native Jacobian failed.');
            case 'jacobian-nan', jacobian(1, 1) = NaN;
            case 'jacobian-shape', jacobian = [1, 2];
            case 'value-nan', varargout = {[NaN; 0], jacobian}; return
            case 'nonlinear-row-nan'
                c = values(x);
                c(2) = NaN;
                jacobian(2, :) = NaN;
                varargout = {c, jacobian};
                return
        end
        varargout = {values(x), jacobian};
    else
        error('NATIVEMETADATA:UnexpectedAction', 'Action %s is not needed.', action);
    end
end

function c = values(x)
    c = [x(1) + 2 * x(2) - 1; x(1) ^ 2 - x(2)];
end
