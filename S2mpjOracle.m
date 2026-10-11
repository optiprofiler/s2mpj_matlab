classdef S2mpjOracle < handle
%S2MPJORACLE Internal serializable owner of one S2MPJ setup configuration.
% Native functions have shared persistent state. The adapter serializes the
% original arguments and source identity, and reinitializes on instance
% switches and restoration. External raw setup or selective clear is not
% observable: callers must reload their Problem after such operations.
    properties (SetAccess = private)
        Name
    end
    properties (Access = private)
        Arguments
        RelativeFiles
        Digests
        Shape = []
    end
    properties (Access = private, Transient)
        Files
        Identity
        Native
        BoundPath = ''
        BoundDirectory = ''
    end
    methods
        function oracle = S2mpjOracle(name, setup_args, saved)
            root = fileparts(mfilename('fullpath'));
            oracle.Name = name;
            oracle.Arguments = setup_args;
            if nargin < 3
                native = fullfile(root, 'src', 'matlab_problems', [name,'.m']);
                if ~isfile(native), native = which(name); end
                if ~startsWith(native, [root,filesep])
                    error('S2MPJ:UntrustedSource', 'Problem source must belong to this S2MPJ installation.');
                end
                oracle.RelativeFiles = {native(numel(root)+2:end), fullfile('src','s2mpjlib.m')};
            else
                oracle.RelativeFiles = saved.relative_files;
                oracle.Shape = saved.shape;
            end
            if numel(oracle.RelativeFiles) ~= 2
                error('S2MPJ:SourceIdentity', 'Invalid saved S2MPJ source identity.');
            end
            for k = 1:2
                parts = regexp(oracle.RelativeFiles{k}, '[\\/]', 'split');
                if any(ismember(parts, {'','..','.'})) || contains(oracle.RelativeFiles{k}, ':')
                    error('S2MPJ:SourceIdentity', 'Saved source must be relative to the trusted installation.');
                end
                oracle.RelativeFiles{k} = fullfile(parts{:});
            end
            oracle.Files = cellfun(@(p) fullfile(root,p), oracle.RelativeFiles, 'UniformOutput',false);
            oracle.Digests = cellfun(@fingerprint, oracle.Files, 'UniformOutput',false);
            if nargin >= 3 && ~isequal(oracle.Digests, saved.digests)
                error('S2MPJ:SourceChanged', 'S2MPJ native/helper source differs from the saved Problem. Reload it explicitly.');
            end
            oracle.Identity = struct('files',{oracle.Files},'digests',{oracle.Digests}, ...
                'arguments',{oracle.Arguments});
            oracle.bind();
        end

        function pb = setup(oracle)
            % Setup may mutate native state before throwing. Never retain an
            % old active entry while setup or metadata validation is running.
            active_state('invalidate', oracle.Files{1}, []);
            oracle.bind();
            pb = oracle.Native('setup', oracle.Arguments{:});
            if ~isstruct(pb) || ~all(isfield(pb, {'n','m','x0','xlower','xupper'})) ...
                    || ~isscalar(pb.n) || ~isscalar(pb.m) ...
                    || ~all(isfinite([pb.n,pb.m])) || pb.n < 1 || pb.m < 0 ...
                    || any([pb.n,pb.m] ~= fix([pb.n,pb.m])) || numel(pb.x0) ~= pb.n
                error('S2MPJ:SetupMetadata', 'Invalid setup metadata for %s.', oracle.Name);
            end
            % Native S2MPJ omits xtype for real-only models. An explicit
            % declaration must not be lost when constructing a Problem.
            if isfield(pb, 'xtype')
                types = pb.xtype;
                if isstring(types) && isscalar(types), types = char(types); end
                if ~ischar(types) || ~isvector(types) || numel(types) ~= pb.n ...
                        || any(~ismember(types(:), 'rib'))
                    error('S2MPJ:SetupMetadata', 'Invalid xtype metadata for %s.', oracle.Name);
                end
                if any(types(:) ~= 'r')
                    error('S2MPJ:NoncontinuousVariables', ...
                        ['%s declares integer or binary variables (xtype=%s). ' ...
                         'This adapter supports continuous problems only; ' ...
                         'no fixing, rounding or relaxation is applied.'], oracle.Name, types(:)');
                end
            end
            if ~isempty(oracle.Shape) && ~isequal([pb.n,pb.m],oracle.Shape)
                error('S2MPJ:SetupMetadata', 'Dimensions changed when restoring %s.',oracle.Name);
            end
            oracle.Shape = [pb.n,pb.m];
            active_state('commit', oracle.Files{1}, oracle.Identity);
        end

        function varargout = call(oracle, action, varargin)
            oracle.bind();
            if ~active_state('matches', oracle.Files{1}, oracle.Identity)
                oracle.setup();
            end
            [varargout{1:nargout}] = oracle.Native(action, varargin{:});
        end

        function value = objective(oracle, x, order, feasibility)
            if feasibility && (order > 0 || ~strcmp(oracle.Name,'HS8'))
                if order == 0, value = 0;
                elseif order == 1, value = zeros(size(x));
                else, value = zeros(numel(x)); end
                return
            end
            switch order
                case 0, evalc('value = oracle.call(''fx'',x);');
                case 1, evalc('[~,value] = oracle.call(''fgx'',x);');
                case 2, evalc('[~,~,value] = oracle.call(''fgHx'',x);');
            end
            value = full(value);
        end

        function value = constraints(oracle, x, indices, signs, offsets, order)
            if isempty(indices)
                if order == 0, value = zeros(0,1);
                elseif order == 1, value = zeros(0,numel(x));
                else, value = cell(0,1); end
                return
            end
            switch order
                case 0
                    evalc('c = oracle.call(''cx'',x);');
                    c = full(c(:));
                    value = signs(:).*c(indices(:)) + offsets(:);
                case 1
                    evalc('[~,J] = oracle.call(''cJx'',x);');
                    value = signs(:).*full(J(indices,:));
                case 2
                    evalc('[~,~,H] = oracle.call(''cJHx'',x);');
                    value = cell(1,numel(indices));
                    for k = 1:numel(indices), value{k} = signs(k)*full(H{indices(k)}); end
            end
        end

        function saved = saveobj(oracle)
            saved = struct('schema',1,'name',oracle.Name,'arguments',{oracle.Arguments}, ...
                'relative_files',{oracle.RelativeFiles},'digests',{oracle.Digests}, ...
                'shape',oracle.Shape,'source_paths',{oracle.Files});
        end
    end
    methods (Access = private)
        function bind(oracle)
            current_path = path;
            current_directory = pwd;
            if ~isempty(oracle.Native) && strcmp(current_path,oracle.BoundPath) ...
                    && strcmp(current_directory,oracle.BoundDirectory)
                return
            end
            active_state('invalidate',oracle.Files{1},[]);
            names = {oracle.Name,'s2mpjlib'};
            for k = 1:2
                if ~strcmp(which(names{k}),oracle.Files{k})
                    addpath(fileparts(oracle.Files{k}));
                    if ~strcmp(which(names{k}),oracle.Files{k})
                        error('S2MPJ:SourceShadowed', ...
                            'Current directory shadows the bound source %s. Change directory and reload the Problem.',oracle.Files{k});
                    end
                end
            end
            if ~isequal(cellfun(@fingerprint,oracle.Files,'UniformOutput',false),oracle.Digests)
                error('S2MPJ:SourceChanged','Bound S2MPJ source changed. Reload the Problem explicitly.');
            end
            oracle.Native = str2func(oracle.Name);
            oracle.BoundPath = path;
            oracle.BoundDirectory = pwd;
        end
    end
    methods (Static)
        function oracle = loadobj(saved)
            if ~isstruct(saved) || ~isfield(saved,'schema') || saved.schema ~= 1
                error('S2MPJ:SavedOracle','Unsupported saved S2MPJ oracle. Reload using the original setup arguments.');
            end
            oracle = S2mpjOracle(saved.name,saved.arguments,saved);
            oracle.setup();
        end
    end
end

function digest = fingerprint(file)
    fid = fopen(file,'rb');
    if fid < 0, error('S2MPJ:SourceMissing','Missing trusted source %s.',file); end
    cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
    digest = s2mpj_digest(fread(fid,Inf,'*uint8'));
end

function result = active_state(action, file, identity)
    persistent files identities
    if isempty(files), files = {}; identities = {}; end
    i = find(strcmp(files,file),1);
    result = false;
    switch action
        case 'matches'
            result = ~isempty(i) && isequaln(identities{i},identity);
        case 'invalidate'
            if ~isempty(i), files(i) = []; identities(i) = []; end
        case 'commit'
            if isempty(i), i = numel(files)+1; end
            files{i} = file; identities{i} = identity;
    end
end
