function [ imsamp ] = lazyEnviReadc( datafile,hdr_info,sample)
% [ imsmap ] = lazyEnviReadc( datafile,info,sample )
% read an image of hyperspectral data for a specific sample.
%   Inputs:
%       datafile: file path to the image file
%       hdr_info: info object returned by envihdrread(hdrfile)
%       band: band to be read
%   Outputs:
%       imsamp: the band image of the hyperspectral data at bth band 
%                [lines x bands]

interleave = hdr_info.interleave;
samples = hdr_info.samples;
lines = hdr_info.lines;
header_offset = hdr_info.header_offset;
bands = hdr_info.bands;
data_type = hdr_info.data_type;
byte_order = hdr_info.byte_order;

if  ( (data_type==4) && strcmp(interleave,'bil') ) && (byte_order==0)
    if ispc
        imsamp = lazyEnviReadcMex04Float(datafile, samples, lines, bands, header_offset, data_type, interleave, byte_order, sample);
    elseif ismac
        imsamp = lazyEnviReadcMex04Float_mac(datafile, samples, lines, bands, header_offset, data_type, interleave, byte_order, sample);
    elseif unix
        error('Please compile the mex file');
    end
    imsamp = imsamp';
elseif (data_type==12) && strcmp(interleave,'bil')
    if ispc
        imsamp = lazyEnviReadcMex12Uint16(datafile, samples, lines, bands, header_offset, data_type, interleave, byte_order, sample);
    elseif ismac
        imsamp = lazyEnviReadcMex12Uint16_mac(datafile, samples, lines, bands, header_offset, data_type, interleave, byte_order, sample);
    elseif unix
        error('Please compile the mex file');
    end
    imsamp = imsamp';
else

    if data_type==12
        % unsigned int16
        s=2;
        typeName = 'uint16';
    elseif data_type==4
        s=4;
        typeName = 'single';
    elseif data_type==5
        s=8;
        typeName = 'double';
    elseif data_type==2
        s=2;
        typeName = 'int16';
    elseif data_type==1
        s=1;
        typeName = 'uint8';
    else
        error('Undefined data_type "%d".',data_type);
    end
    
    switch byte_order
        case {0}
            machine = 'ieee-le';
        case {1}
            machine = 'ieee-be';
        otherwise
            machine = 'n';
    end

    fid = fopen(datafile);

    imsamp = zeros([lines,bands],typeName);
    if strcmp(interleave,'bil') % BIL type: sample -> band -> line
        for line=1:lines
            tmp = fread(fid,samples*bands,typeName,0,machine);
            tmp = reshape(tmp,[samples,bands])';
            if data_type==12
                tmp = uint16(tmp);
            elseif data_type==2
                tmp = int16(tmp);
            end
            imsamp(line,:) = tmp(:,sample);
        end
    elseif strcmp(interleave,'bsq') % sample -> line -> band
        for band = 1:bands
            tmp = fread(fid,samples*lines,typeName,0,machine);
            tmp = reshape(tmp,[samples,lines])';
            if data_type==12
                tmp = uint16(tmp);
            elseif data_type==2
                tmp = int16(tmp);
            end
            imsamp(:,band) = tmp(:,sample);
        end
    end

end

end
    


