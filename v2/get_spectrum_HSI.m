function[spc,wv] = get_spectrum_HSI(hsi,s,l,varargin)

ave_window = [1 1];
bands = true(hsi.hdr.bands,1);
coeff = ones(hsi.hdr.bands,1);
is_wa_band_inverse = false;
is_img_band_inverse = false;
is_bands_inverse = false;
is_coeff_inverse = false;

if (rem(length(varargin),2)==1)
    error('Optional parameters should always go by pairs');
else
    for i=1:2:(length(varargin)-1)
        switch upper(varargin{i})
            case 'BANDS'
                bands = varargin{i+1};
            case 'AVERAGE_WINDOW'
                ave_window = varargin{i+1};
            case 'COEFF'
                coeff = varargin{i+1};
            case 'WA_BAND_INVERSE'
                is_wa_band_inverse = varargin{i+1};
            case 'IMG_BAND_INVERSE'
                is_img_band_inverse = varargin{i+1};
            case 'COEFF_INVERSE'
                is_coeff_inverse = varargin{i+1};
            case 'BANDS_INVERSE'
                is_bands_inverse = varargin{i+1};
            otherwise
                % Hmmm, something wrong with the parameter string
                error('Unrecognized option: %s', varargin{i});
        end
    end
end

if isempty(bands)
    bands = true(hsi.hdr.bands,1);
end

if ~islogical(bands)
   bands_bool = false(hsi.hdr.bands,1);
   bands_bool(bands) = true;
   if is_bands_inverse
       bands = flip(bands_bool);
   else
       bands = bands_bool;
   end
end

l_bands = sum(bands);
l_coeff = length(coeff);
if is_coeff_inverse
    coeff = flip(coeff);
end

% load wavelength
if ~isempty(hsi.wa)
    wv = hsi.wa(:,s);
    if is_wa_band_inverse
        wv = flip(wv);
    end
elseif isfield('wavelength',hsi.hdr)
    wv = hsi.hdr.wavelength;
else
    wv = 1:hsi.hdr.bands; % band is returned when no information for wavelength
end

% load spectrum
ave_strt = -floor((ave_window-1)/2)+[l,s];
ave_end = floor(ave_window/2)+[l,s];
if isempty(hsi.img)
    spcs = [];
    for ll = ave_strt(1):ave_end(1)
        for ss = ave_strt(2):ave_end(2)
            spc_ll_ss = hsi.lazyEnviRead(ss,ll);
            spcs = [spcs spc_ll_ss];
        end
    end
    spc = nanmean(spcs,2);
else
    spc = squeeze(nanmean(nanmean(hsi.img(ave_strt(1):ave_end(1),ave_strt(2):ave_end(2),:),2),1));
    if is_img_band_inverse
        spc = flip(spc);
    end
end

if l_coeff==l_bands
    % perform bands option if given
    wv = wv(bands);
    spc = spc(bands);
    spc = spc .* coeff;
elseif l_coeff==hsi.hdr.bands
    spc = spc .* coeff;
    % perform bands option if given
    wv = wv(bands);
    spc = spc(bands);
else
    error('length of coeff %d is not right.',l_coeff);
end

end