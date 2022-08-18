function envi_save_raster(img,hdr,imgpath,hdrpath)
    if exist(imgpath,'file'),delete(imgpath); end
    fprintf('Saving %s ...',imgpath);
    envidatawrite(img,imgpath,hdr);
    fprintf('\nDone.\n');
    if exist(hdrpath,'file'),delete(hdrpath); end
    fprintf('Saving %s ...',hdrpath);
    envihdrwritex(hdr,hdrpath);
    fprintf('\nDone.\n');
end