clc
clear

addpath img

%% Possion Image Fusion Demo ͼ���ں�
% source image
srcImg = im2double(imread('lsf.png'));
% background image
dstImg = im2double(imread('b.jpg'));

[mask,pos,subSrcImg] = PIE_GUI(srcImg,dstImg);

subDstImg = imcrop(dstImg,pos);
out = PIF(subDstImg, subSrcImg, mask, 1);

dstImg(pos(2):pos(2)+pos(4),pos(1):pos(1)+pos(3),:)=out;
figure;imshow(dstImg);

%% Select Edit Demo ͼ��༭
% Laplacian interpolation           method: none
% Texture flattening                method: flatten
% Local illumination changes        method: contrast
% Local color changes               method: color
% Concealment                       method: flip
img = im2double(imread('018.png'));
out = img;
[mask,pos,subImg] = PIE_GUI_single(img);

pieOut = PIE(subImg, mask,'color');

out(pos(2):pos(2)+pos(4),pos(1):pos(1)+pos(3),:)=pieOut;
figure;imshow([img out]);

%% Seamless tiling Demo �޷�ƴ��
srcImg = im2double(imread('022.png'));
Img = srcImg;
%�ؽ��߽�����
Img(1,:,:)=0.5*(Img(1,:,:)+Img(end,:,:));
Img(end,:,:)=Img(1,:,:);
Img(:,1,:)=0.5*(Img(:,1,:)+Img(:,end,:));
Img(:,end,:)=Img(:,1,:);

%maskΪ�߽�������м�����
mask = zeros(size(Img,1),size(Img,2));
mask(2:end-1,2:end-1)=1;

out = PIE(Img, mask,'tiling',srcImg);
figure;imshow([srcImg srcImg;srcImg srcImg])
figure;imshow([out out;out out])

