function [] = envi_startup_addpath()
%% Automatically find the path to toolboxes
fpath_self = mfilename('fullpath');
[dirpath_self,filename] = fileparts(fpath_self);
path_ptrn = '(?<parent_dirpath>.*)/(?<toolbox_dirname>[^/]+[/]{0,1})';
mtch = regexpi(dirpath_self,path_ptrn,'names');
toolbox_root_dir = mtch.parent_dirpath;
envi_toolbox_dirname  = mtch.toolbox_dirname;

%% Find dependent toolboxes.
dList = dir(toolbox_root_dir);
error_if_not_unique = true;
pathCell = strsplit(path, pathsep);

% base toolbox
[base_toolbox_dir,base_toolbox_dirname] = get_toolbox_dirname(dList, ...
    'base',error_if_not_unique);
if ~check_path_exist(base_toolbox_dir, pathCell)
    addpath(base_toolbox_dir);
end

%% envi toolbox
envi_toolbox_dir = joinPath(toolbox_root_dir, envi_toolbox_dirname);

if ~check_path_exist(envi_toolbox_dir, pathCell)
    addpath( ...
        envi_toolbox_dir                                        , ...
        joinPath(envi_toolbox_dir,'v2/')                        , ...
        joinPath(envi_toolbox_dir,'v3/')                        , ...
        joinPath(envi_toolbox_dir,'v3/lazy_mex/')               , ...
        joinPath(envi_toolbox_dir,'v3/lazy_mex/wrapper/')         ...
    );

    cmp_arch = computer('arch');
    switch cmp_arch
        case 'maci64'
            % For Mac computers
            envi_mex_build_path = joinPath(envi_toolbox_dir,'v3/lazy_mex/build/maci64/');
        case 'glnxa64'
            % For Linux/Unix computers with x86-64 architechture
            envi_mex_build_path = joinPath(envi_toolbox_dir,'v3/lazy_mex/build/glnxa64/');
        case 'win64'
            envi_mex_build_path = joinPath(envi_toolbox_dir,'v3/lazy_mex/build/win64/');
        otherwise
            error('%s is not supported',cmp_arch);
    end

    if exist(envi_mex_build_path,'dir')
        addpath(envi_mex_build_path);
    else
        addpath(envi_mex_build_path);
        fprintf('Run envi/v3/lazy_mex/build/envi_v3_lazy_mex_compile_all.m to compile C/MEX sources.\n');
    end
end

end

%%
function [onPath] = check_path_exist(dirpath, pathCell)
    % pathCell = strsplit(path, pathsep, 'split');
    if ispc || ismac 
      onPath = any(strcmpi(dirpath, pathCell));
    else
      onPath = any(strcmp(dirpath, pathCell));
    end
end

function [toolbox_dirpath,toolbox_dirname] = get_toolbox_dirname(dList,toolbox_dirname_wover,error_if_not_unique)
    dirname_ptrn = sprintf('(?<toolbox_dirname>%s(-[\\d\\.]+){0,1}[/]{0,1})',toolbox_dirname_wover);
    mtch_toolbox_dirname = regexpi({dList.name},dirname_ptrn,'names');
    mtchidx = find(not(cellfun('isempty',mtch_toolbox_dirname)));
    toolbox_root_dir = dList(1).folder;
    if length(mtchidx)==1
        toolbox_dirname = mtch_toolbox_dirname{mtchidx}.toolbox_dirname;
        toolbox_dirpath = [toolbox_root_dir, '/', toolbox_dirname];
    elseif isempty(mtchidx)
        toolbox_dirname = [];
        toolbox_dirpath = [];
        if error_if_not_unique
            
            error(['Cannot find %s toolbox in\n %s', ...
                   'Download from\n', ...
                   '   https://github.com/yukiitohand/%s/', ...
                  ], ...
                toolbox_dirname_wover,toolbox_root_dir,toolbox_dirname_wover);
        end
    else % length(mtchidx)>1
        toolbox_dirname = {cat(2,mtch_toolbox_dirname{mtchidx}).toolbox_dirname};
        toolbox_dirpath = cellfun(@(x) strjoin({toolbox_root_dir,x},'/'), toolbox_dirname, ...
            'UniformOutput',false);
        if error_if_not_unique
            toolbox_root_dir = dList(1).folder;
            error('Multiple %s toolboxes %s are detected in\n %s', ...
            toolbox_dirname_wover,strjoin(toolbox_dirname,','), toolbox_root_dir);
        end
        
    end
end