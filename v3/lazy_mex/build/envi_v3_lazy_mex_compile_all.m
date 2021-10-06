function [] = envi_v3_lazy_mex_compile_all()
% envi_v3_compile_all.m
fpath_self = mfilename('fullpath');
[dirpath_self,filename] = fileparts(fpath_self);

idx_sep = strfind(dirpath_self,'envi/v3/lazy_mex/build');
dirpath_toolbox = dirpath_self(1:idx_sep-1);

envi_toolbox_path = joinPath(dirpath_toolbox, 'envi/');

envi_mex_include_path = joinPath(envi_toolbox_path, 'v3/lazy_mex/include/');
envi_mex_source_path  = joinPath(envi_toolbox_path, 'v3/lazy_mex/source/');
envi_mex_outdir_path  = joinPath(envi_toolbox_path, 'v3/lazy_mex/build/');

% Sorry, these functions are currently not supported for MATLAB 9.3 or
% earlier. These requires another 
if verLessThan('matlab','9.4')
    error('You need MATLAB version 9.4 or newer');
end

%%
source_filenames = { ...
    'lazyenvireadRect_multBandRasterInt8_mex.c'     ,   ...
    'lazyenvireadRect_singleLayerRasterInt8_mex.c'  ,   ...
    'lazyenvireadRect_multBandRasterInt16_mex.c'    ,   ...
    'lazyenvireadRect_multBandRasterSingle_mex.c'   ,   ...
    'lazyenvireadRect_multBandRasterUint16_mex.c'   ,   ...
    'lazyenvireadRect_multBandRasterUint8_mex.c'    ,   ...
    'lazyenvireadRect_singleLayerRasterInt16_mex.c' ,   ...
    'lazyenvireadRect_singleLayerRasterSingle_mex.c',   ...
    'lazyenvireadRect_singleLayerRasterUint16_mex.c',   ...
    'lazyenvireadRect_singleLayerRasterUint8_mex.c'     ...
};

switch computer
    case 'MACI64'
        out_dir = joinPath(envi_mex_outdir_path,'maci64/');
    case 'GLNXA64'
        out_dir = joinPath(envi_mex_outdir_path,'glnxa64/');
    case 'PCWIN64'
        out_dir = joinPath(envi_mex_outdir_path,'win64/');
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
    mex(filepath, '-R2018a', 'CFLAGS="$CFLAGS -Wno-unused-result"', ...
        ['-I' envi_mex_include_path], ...
        '-outdir',out_dir);
end

fprintf('End of compiling.\n');

end
