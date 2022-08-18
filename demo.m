% demo

dpath = 'C:/headwall/VNIR data/captured/';
dpath = 'E:\MicroHyperspec\iceland\SWIR data\captured\';
dpath = 'E:\MicroHyperspec\iceland\VNIR data\captured\';

d = '2016_08_06_13_10_05\';
d = '2016_08_04_12_43_42\';
d = '2016_07_27_13_46_33\';


[hdr] = envihdrread_yuki([dpath d 'raw.hdr']);
tic
img = lazyEnviReadbMex([dpath d 'raw'],hdr,100);
toc

% figure; imagesc(img');
tic
img1 = lazyEnviReadb([dpath d 'raw'],hdr,100);
toc
% figure; imagesc(img);