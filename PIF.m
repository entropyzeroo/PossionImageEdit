function out = PIF(dstImg, srcImg, mask, mix)
% Fuction: Possion Image Fusion
% 泊松融合：将源图像与目标图像无缝融合
%  -使用方法-
%	im_out = PIE(destinationImg,sourceImg,mask,0); %泊松无缝融合
%   im_out = PIE(destinationImg,sourceImage,mask,1); %混合梯度泊松无缝融合
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   论文:
%   Pérez, Patrick, Michel Gangnet, and Andrew Blake.
%   "Poisson image editing." ACM Transactions on Graphics (TOG). Vol. 22.
%   No. 3. ACM, 2003.
%  -输入-
%	 dstImg: 目标图像（背景图像）,归一化double格式
%    srcImg: 源图像（待插入图像）,归一化double格式
%    mask: 掩膜（融合区域）,0-1
%    mix: 0为泊松无缝融合, 1为混合梯度泊松无缝融合（默认）
%  -输出-
%    out: 等于mask大小的融合图像，归一化double格式

if nargin<3
    error('最少输入3个数据，PIE(dstImg, srcImg, mask)')
end

if nargin<4
    mix = 1;
end

%初始化输出
out = dstImg;
%统计非零点，即需要融合部分
num = nnz(mask);

[m,n] = size(mask);

%标记每一个需要融合点的索引
%0表示已知的周边像素，1为未知待求像素
map = zeros(m,n);
cnt = 0;
for i=1:m
    for j=1:n
        if mask(i,j)==1
            cnt=cnt+1;
            map(i,j)=cnt;
        end
    end
end

% 根据论文，解Ax=B，分别构建A和B

% 拉普拉斯模板，用于seamless clone直接求取laplacian图
laplacian_mask = [0 1 0;1 -4 1;0 1 0];
% 4个方向的滤波模板，对标拉普拉斯算子，必须分开求，不然在边界可能会有问题
k = {[1 -1 0],[0 -1 1],[1;-1;0],[0;-1;1]};

if mix==1
    % 求最大梯度泊松融合时的lap图
    lap=0;
    for d=1:4
        d_grad = imfilter(dstImg, k{d});
        s_grad = imfilter(srcImg, k{d});
        tempmask = abs(s_grad)>abs(d_grad);
        % 取较大梯度
        mix_grad = s_grad.*tempmask+d_grad.*(tempmask==0);
        lap = lap+mix_grad;
    end
else
    % 直接泊松融合时的lap图
    lap = imfilter(srcImg, laplacian_mask);
end

% 构建稀疏的系数矩阵A
coeffNum=5;
A=spalloc(num,num,num*coeffNum);
% 根据通道数构建B
% Ax=B中，A：n*n   x：n*c    B：n*c,  n为像素数,c为通道数
B=zeros(num,size(dstImg,3));

% 填充A
cnt = 0;
for i=2:m-1
    for j=2:n-1
        if mask(i,j)==1
            cnt = cnt+1;
            A(cnt,cnt) = 4;
            
            % 检查左边界
            if mask(i-1,j)==0
                B(cnt,:) = reshape(dstImg(i-1,j,:),[],1);
            else
                A(cnt,map(i-1,j)) = -1;
            end
            
            % 检查右边界
            if mask(i+1,j)==0
                B(cnt,:) = B(cnt,:)+reshape(dstImg(i+1,j,:),[],1)';
            else
                A(cnt,map(i+1,j)) = -1;
            end
              
            % 检查下边界
            if mask(i,j-1)==0
                B(cnt,:) = B(cnt,:)+reshape(dstImg(i,j-1,:),[],1)';
            else
                A(cnt,map(i,j-1)) = -1;
            end
            
            % 检查上边界
            if mask(i,j+1)==0
                B(cnt,:) = B(cnt,:)+reshape(dstImg(i,j+1,:),[],1)';
            else
                A(cnt,map(i,j+1)) = -1;
            end
            
            % 填充B
            B(cnt,:)=B(cnt,:)-reshape(lap(i,j,:),[],1)';
        end
    end
end

% 求解
X=A\B;

% 在二维图像中赋值
for cnt=1:size(X,1)
    [idx_x,idx_y]=find(map==cnt);
    out(idx_x,idx_y,:)=reshape(X(cnt,:),1,1,3);
end
