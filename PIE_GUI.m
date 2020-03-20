function [mask,position2,srcImg] = PIE_GUI(srcImg,dstImg)
%% Select area in the background image
f1 = figure;
imshow(srcImg);
h = imfreehand;
api = iptgetapi(h);
fcn = makeConstrainToRectFcn('imfreehand',[1 size(srcImg,2)],[1 size(srcImg,1)]);
api.setPositionConstraintFcn(fcn);
position = wait(h);
mask = double(createMask(h));
close(f1);

%% Crop the background image and set the border of mask as 0
cc = regionprops(mask,'BoundingBox');
mask = imcrop(mask,cc(1).BoundingBox);
mask(1,:) = 0;
mask(end,:) = 0;
mask(:,1) = 0 ;
mask(:,end) = 0;
srcImg = imcrop(srcImg,cc(1).BoundingBox);
% figure,imshow(background_img);
% figure,imshow(mask);

%% Select the area in the target image and resize the background image
f3 = figure;
% subplot(1,2,1);
% imshow(background_img),hold on;
% plot(position(:,1),position(:,2))
% subplot(1,2,2);
imshow(dstImg);
h2 = imrect(gca,[1 1 size(mask,2) size(mask,1)]);
setFixedAspectRatioMode(h2,1);
fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
setPositionConstraintFcn(h2,fcn); 
position2 = wait(h2);
close(f3);

mask = imresize(mask,[position2(4) position2(3)]);
mask = mask > 0;

position2(3:4)=position2(3:4)-1;
position2 = int32(position2);
