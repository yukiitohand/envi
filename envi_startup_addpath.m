function [] = envi_startup_addpath()
%-------------------------------------------------------------------------%
% % Automatically find the path to toolboxes
fpath_self = mfilename('fullpath');
[dirpath_self,filename] = fileparts(fpath_self);
mtch = regexpi(dirpath_self,'(?<parent_dirpath>.*)/envi[/]{0,1}','names');
toolbox_root_dir = mtch.parent_dirpath;

%-------------------------------------------------------------------------%
% name of the directory of each toolbox
base_toolbox_dirname          = 'base';
envi_toolbox_dirname          = 'envi';

%-------------------------------------------------------------------------%
pathCell = strsplit(path, pathsep);

%% base toolbox
base_toolbox_dir = [toolbox_root_dir '/' base_toolbox_dirname ];
% joinPath in base toolbox will be used in the following. "base" toolbox
% need to be loaded first. base/joinPath.m automatically determine the
% presence of trailing slash, so you do not need to worry it.
if exist(base_toolbox_dir,'dir')
    if ~check_path_exist(base_toolbox_dir, pathCell)
        addpath(base_toolbox_dir);
    end
else
    warning([ ...
        'base toolbox is not detected. Download from' '\n' ...
        '   https://github.com/yukiitohand/base/'
        ]);
end


%%
% envi toolbox
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