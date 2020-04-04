function [spc,wv,band_idxes] = get_spectrum_HSI(hsi,s,l,varargin)
% AVERAGE_WINDOW: [y_size,x_size]

ave_window = [1 1];
do_average = true;
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
            case 'DO_AVERAGE'
                do_average = varargin{i+1};
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

% load spectrum
wdw_strt = -floor((ave_window-1)/2)+[l,s];
wdw_end = floor(ave_window/2)+[l,s];

% load wavelength
if ~isempty(hsi.wa)
    if do_average
        wv = hsi.wa(:,s);
    else
        wv = hsi.wa(:,wdw_strt(2):wdw_end(2));
    end
    if is_wa_band_inverse
        wv = flip(wv,1);
    end
elseif isfield(hsi.hdr,'wavelength')
    wv = hsi.hdr.wavelength;
else
    wv = 1:hsi.hdr.bands; % band is returned when no information for wavelength
end

if isempty(hsi.img)
    spc = nan(ave_window(1),ave_window(2),hsi.hdr.bands);
    lidx = 1;
    for ll = wdw_strt(1):wdw_end(1)
        sidx = 1;
        for ss = wdw_strt(2):wdw_end(2)
            spc_ll_ss = hsi.lazyEnviRead(ss,ll);
            spc(lidx,sidx,:) = spc_ll_ss;
            sidx = sidx + 1;
        end
        lidx = lidx + 1;
    end
else
    spc = hsi.img(wdw_strt(1):wdw_end(1),wdw_strt(2):wdw_end(2),:);
    if is_img_band_inverse
        spc = flip(spc,3);
    end
end

if do_average
    spc = nanmean(spc,[1,2]);
end

if l_coeff==l_bands
    % perform bands option if given
    if isvector(wv)
        wv = wv(bands);
    elseif ismatrix(wv)
        wv = wv(bands,:);
    end
    spc = spc(:,:,bands);
    spc = spc .* permute(coeff,[3,2,1]);
elseif l_coeff==hsi.hdr.bands
    spc = spc .* permute(coeff,[3,2,1]);
    % perform bands option if given
    if isvector(wv)
        wv = wv(bands);
    elseif ismatrix(wv)
        wv = wv(bands,:);
    end
    spc = spc(:,:,bands);
else
    error('length of coeff %d is not right.',l_coeff);
end
spc = squeeze(spc);

band_idxes = find(bands);

end