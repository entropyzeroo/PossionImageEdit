function [mask,pos,Img] = PIE_GUI_single(Img)
%% Select area in the background image
f1 = figure;
imshow(Img);
h = imfreehand;
api = iptgetapi(h);
fcn = makeConstrainToRectFcn('imfreehand',[1 size(Img,2)],[1 size(Img,1)]);
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

pos(1:2)=int32(min(position,[],1));
pos(3:4)=max(position,[],1)-min(position,[],1);

Img = imcrop(Img,pos);

mask = imresize(mask,[pos(4)+1 pos(3)+1]);
mask = mask>0;
