classdef ENVIRasterSingleLayer < ENVIRaster
    % ENVIRasterSingleLayer class
    %  A special case for ENVIRaster, ENVIRasterSingleLayer only supports
    %  Image with one layer.
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
    %  Methods: readimg, lazyEnviRead, lazyEnviReadb, lazyEnviReadRGB
    %
    %  Usage:
    %  >> hsi = ENVIRasterSingleLayer('raw','./');
    %  >> hsi.readimg(); % read the image
    %  >> spc = hsi.lazyEnviRead(100,200); % read the spectrum [200, 100]
    %  >> rgb = hsi.lazyEnviReadl([125 85 49]); % read rgb image
    %  >> imb = hsi.lazyEnviReadb(125); % read one band image
    % 
    % 
    properties
        
    end
    methods
        function obj = ENVIRasterSingleLayer(basename,dirpath,varargin)
            obj@ENVIRaster(basename,dirpath,varargin{:});
        end
        
        function [img] = readimg(obj,varargin)
            if isempty(obj.hdr)
                error('no img is found');
            end
            img = lazyenvireadRectxv2_multBandRaster_mexw(...
                obj.imgpath,obj.hdr,[1 obj.hdr.samples],[1 obj.hdr.lines], ...
                [1, 1],varargin{:});
            if nargout<1
                obj.img = img;
            end
            % [img] = lazyenvireadRect_singleLayerRaster_mexw(...
            %     obj.imgpath,obj.hdr,0,0,obj.hdr.samples,obj.hdr.lines,...
            %     varargin{:});
            % if nargout<1
            %     obj.img = img;
            % end
        end
        
        function [val] = lazyEnviRead(obj,s,l,varargin)
            if isempty(obj.hdr)
                error('no img is found');
            end
            if any(size(s)~=size(l))
                error('Input s and l has different shape');
            end
            val = lazyenvireadRectxv2_multBandRaster_mexw(...
                obj.imgpath, obj.hdr, [s s], [l l], [1, 1], varargin{:});
            % val = lazyenvireadRect_singleLayerRaster_mexw(...
            %     obj.imgpath,obj.hdr,s-1,l-1,1,1,varargin{:});
        end
        
        function [iml] = lazyEnviReadl(obj,l,varargin)
            if isempty(obj.hdr)
                error('no img is found');
            end
            iml = lazyEnviReadl_multBandRaster(obj.imgpath, obj.hdr, l,...
                varargin{:});
            % iml = lazyenvireadRect_singleLayerRaster_mexw(...
            %     obj.imgpath,obj.hdr,0,l-1,obj.hdr.samples,1,varargin{:});
        end
        
        function [imc] = lazyEnviReadc(obj,c,varargin)
            if isempty(obj.hdr)
                error('no img is found');
            end
            imc = lazyEnviReadc_multBandRaster(obj.imgpath, obj.hdr, c,...
                varargin{:});
            % imc = lazyenvireadRect_singleLayerRaster_mexw(...
            %     obj.imgpath,obj.hdr,c-1,0,1,obj.hdr.lines,varargin{:});
        end
        
        function [subimg] = get_subimage_wPixelRange(obj,xrange,yrange,...
                varargin)
            % [subimg] = get_subimage_wPixelRange(obj,xrange,yrange,...
            %   varargin)
            % Get a rectangular region of the image.
            % INPUTS
            %   xrange: [1 x 2] length vector, range of the rectangle
            %           region of the image in the horizontal direction.
            %   yrange: [1 x 2] length vector, range of the rectangle
            %           region of the image in the vertical direction.
            % OUTPUTS
            %   subimage: a rectangle region of the image, data type
            %             depends on "Precision".
            % Optional Parameters
            %  Refer "lazyenvireadRect_singleLayerRaster_mexw.m".
            %   "PRECISION": char, string; data type of the output image.
            %       'double', 'single','int16','uint8','raw'
            %      if 'raw', the data is returned with the original data 
            %      type of the image.
            %      (default) 'double'
            %  "Replace_data_ignore_value": boolean, 
            %      whether or not to replace data_ignore_value with NaNs or
            %      not.
            %      (default) true (for single and double data types)
            %                false (for integer types)
            %  "RepVal_data_ignore_value": 
            %      replaced values for the pixels with data_ignore_value.
            %      (default) nan (for double and single precisions). Need
            %      to specify for integer precisions.
            
            if length(xrange)~=2 || length(yrange)~=2
                error('Either the size of xrange or yrange is invalid');
            end
            
            if xrange(1)>xrange(2) || yrange(1)>yrange(2)
                error('Either of the range is not in the right order');
            end

            if isempty(obj.hdr)
                error('no img is found');
            end
            zrange = [1,1];
            [subimg] = lazyenvireadRectxv2_multBandRaster_mexw(...
                obj.imgpath,obj.hdr,xrange,yrange,zrange,varargin{:});
            
            % sample_offset = xrange(1)-1; line_offset = yrange(1)-1;
            % samplesc = xrange(2)-xrange(1)+1; linesc = yrange(2)-yrange(1)+1;
            % [subimg] = lazyenvireadRect_singleLayerRaster_mexw(...
            %     obj.imgpath,obj.hdr,sample_offset,line_offset,...
            %     samplesc,linesc,varargin{:});
        end
        
    end
end