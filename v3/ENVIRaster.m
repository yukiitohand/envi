classdef ENVIRaster < handle
    % ENVIRaster class
    %  Constructor Input
    %    basename: string, basename of the image file
    %    dirpath: string, directory path in which the image file is stored.
    %
    %  #1 note that the header and image are supposed to be in the same
    %    directory.
    %  #2 the hdr file name and image file name are estimated. hdr file
    %     name could be either [basename '.hdr'] or [basename 'img.hdr']. 
    %     The imagefilename could be either [basename '.img'] or just 
    %     "basename". Case insensitive (if you are using a case sensitive 
    %     file system format, this may not be true.)
    %  
    %  Properties
    %   hdr       : struct of the header information
    %   basename  : string, basename
    %   dirpath   : string, directory path to the files
    %   hdrpath   : full file path to the header file
    %   imgpath   : full file path to the image file
    %   img       : (default) []
    %   
    properties
        basename
        dirpath
        hdrpath
        imgpath
        hdr
        img
        fid_img
    end
    
    methods
        function obj = ENVIRaster(basename,dirpath,varargin)
            
            if (rem(length(varargin),2)==1)
                error('Optional parameters should always go by pairs');
            else
                for i=1:2:(length(varargin)-1)
                    switch upper(varargin{i})
                        case 'WARNING_HDR_NOT_FOUND'
                            warning_hdr_not_found = varargin{i+1};
                        case 'WARNING_IMG_NOT_FOUND'
                            warning_img_not_found = varargin{i+1};
                        otherwise
                            error('Unrecognized option: %s',varargin{i});
                    end
                end
            end
            [obj.hdrpath] = guessEnviHDRPATH(basename,dirpath,'warning',warning_hdr_not_found);
            [obj.imgpath] = guessEnviIMGPATH(basename,dirpath,'warning',warning_img_not_found);
            
            obj.basename = basename;
            obj.dirpath = dirpath;
            
            if ~isempty(obj.hdrpath)
                hdr = envihdrreadx2(obj.hdrpath);
                obj.hdr = hdr;
            end
            obj.fid_img = -1;
            
        end
        function [] = fopen_img(obj)
            obj.fid_img = fopen(obj.imgpath,'r');
        end
        function [] = fclose_img(obj)
            fclose(obj.fid_img);
            obj.fid_img = -1;
        end
        function [tf] = isValid_sampleline(obj,smpl,ln)
            if smpl<0.5 || smpl>obj.hdr.samples+0.5 ...
                    || ln<0.5 || ln>obj.hdr.lines+0.5
                tf = false;
            else
                tf = true;
            end
        end
        function delete(obj)
            if obj.fid_img ~= -1
                fclose(obj.fid_img);
            end
        end
        
    end
    
end

