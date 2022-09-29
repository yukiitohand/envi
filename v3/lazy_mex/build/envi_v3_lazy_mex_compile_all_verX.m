function [] = envi_v3_lazy_mex_compile_all_verX(varargin)
% envi_v3_compile_all.m

mexCompileOpt = {};
if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'MEXCOMPILEOPT'
                mexCompileOpt = varargin{i+1};
                if ~iscell(mexCompileOpt)
                    mexCompileOpt = {mexCompileOpt};
                end
            otherwise
                error('Unrecognized option: %s',varargin{i});
        end
    end
end

fpath_self = mfilename('fullpath');
[dirpath_self,filename] = fileparts(fpath_self);

idx_sep = strfind(dirpath_self,fullfile('v3','lazy_mex','build'));
envi_toolbox_path = dirpath_self(1:idx_sep-1);

envi_mex_include_path = fullfile(envi_toolbox_path, 'v3','lazy_mex','include');
envi_mex_source_path  = fullfile(envi_toolbox_path, 'v3','lazy_mex','source');
envi_mex_outdir_path  = fullfile(envi_toolbox_path, 'v3','lazy_mex','build');

% Sorry, these functions are currently not supported for MATLAB 9.3 or
% earlier. These requires another 
if verLessThan('matlab','9.4')
    error('You need MATLAB version 9.4 or newer');
end

%%
source_filenames = { ...
    ...'lazyenvireadRect_multBandRasterInt8_mex.c'     ,   ...
    ...'lazyenvireadRect_singleLayerRasterInt8_mex.c'  ,   ...
    ...'lazyenvireadRect_multBandRasterInt16_mex.c'    ,   ...
    'lazyenvireadRectx_multBandRasterSingle_mex.c'   ,   ...
    ...'lazyenvireadRect_multBandRasterUint16_mex.c'   ,   ...
    ...'lazyenvireadRect_multBandRasterUint8_mex.c'    ,   ...
    ...'lazyenvireadRect_singleLayerRasterInt16_mex.c' ,   ...
    ...'lazyenvireadRect_singleLayerRasterSingle_mex.c',   ...
    ...'lazyenvireadRect_singleLayerRasterUint16_mex.c',   ...
    ...'lazyenvireadRect_singleLayerRasterUint8_mex.c'     ...
};

switch computer
    case 'MACI64'
        out_dir = fullfile(envi_mex_outdir_path,'maci64');
    case 'GLNXA64'
        out_dir = fullfile(envi_mex_outdir_path,'glnxa64');
    case 'PCWIN64'
        out_dir = fullfile(envi_mex_outdir_path,'win64');
    otherwise
        error('Undefined computer type %s.\n',computer);
end

if ~exist(out_dir,'dir')
    mkdir(out_dir);
end

%%
for i=1:length(source_filenames)
    filename = source_filenames{i};
    fprintf('Compiling %s ...\n',filename);
    filepath = joinPath(envi_mex_source_path,filename);
    mex(filepath,'-v', 'GCC=''/software/gcc-6.3.0/bin/gcc''', ...
        '-R2018a','CFLAGS="$CFLAGS -O3 -fPIC -ffast-math -fno-strict-aliasing -Wno-unused-result"', ...
        ['-I' envi_mex_include_path], ...
        '-outdir',out_dir, mexCompileOpt{:});
end

fprintf('End of compiling.\n');

end
