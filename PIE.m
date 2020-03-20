function out = PIE(im, mask, method, srcImg)
% possion image edit
% -input-
%   "im"        源图像
%   "mask"      框选区域
%   "method"    梯度处理方法
%   "srcImg"    对于tiling方法，需要输入原始读入图像
%
% -method-  目前有的几种处理方法，可自定义修改
%   "none"  平滑内容填充（盲插值） 
%   "flatten"   边缘保持去纹理
%   "color"     颜色调节
%   "flip"   内容翻转（代码控制左右或者上线）
%   "tiling"    拼接
% -output-
%   "out"   double类型
%
if nargin<2
    error('至少输入一副图像和对应mask');
end

if nargin<3
    method = 'none';
end

if nargin == 3 && strcmp(method,'tailing')
    error('请输入待拼接的原始图像。');
end

out = im;
%统计非零点，即需要融合部分
num = nnz(mask);

[m,n] = size(mask);

%标记每一个需要融合点的索引
%0表示已知的边界像素，1为未知待求像素
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
% 拉普拉斯算子在4个方向上的独立表达滤波核
k = {[1 -1 0],[0 -1 1],[1;-1;0],[0;-1;1]};
lap=0;
% ---------此处操作梯度以取得不同效果---------
switch method
    case 'none'
        lap = zeros(size(im));
    case 'flatten'
        for d=1:4
            grad = imfilter(im, k{d});
            grad(abs(grad)<0.02)=0;
            lap = lap+grad;
        end
    case 'contrast'
        for d=1:4
            grad = imfilter(im, k{d});
            lap = lap+grad.^2.^0.24;
        end
    case 'color'
        for d=1:4
            grad = imfilter(im, k{d});
            grad(:,:,1)=grad(:,:,1)*1.5;
            grad(:,:,2)=grad(:,:,2)/2;
            grad(:,:,3)=grad(:,:,3)/2;
            lap = lap+grad;
        end
    case 'flip'
        for d=1:4
            grad = imfilter(im, k{d});
            lap = lap+fliplr(grad);
        end
    case 'tiling'
        for d=1:4
            grad = imfilter(srcImg, k{d});
            lap = lap+grad;
        end
    otherwise
        error('没有内置这样的方法，请自定义');
end


% 构建稀疏的系数矩阵A
coeffNum=5;
A=spalloc(num,num,num*coeffNum);
% 根据通道数构建B
% Ax=B中，A：n*n   x：n*c    B：n*c,  n为像素数,c为通道数
B=zeros(num,size(im,3));

% 填充A
cnt = 0;
for i=2:m-1
    for j=2:n-1
        if mask(i,j)==1
            cnt = cnt+1;
            A(cnt,cnt) = 4;
            
            % 检查左边界
            if mask(i-1,j)==0
                B(cnt,:) = reshape(im(i-1,j,:),[],1);
            else
                A(cnt,map(i-1,j)) = -1;
            end
            
            % 检查右边界
            if mask(i+1,j)==0
                B(cnt,:) = B(cnt,:)+reshape(im(i+1,j,:),[],1)';
            else
                A(cnt,map(i+1,j)) = -1;
            end
              
            % 检查下边界
            if mask(i,j-1)==0
                B(cnt,:) = B(cnt,:)+reshape(im(i,j-1,:),[],1)';
            else
                A(cnt,map(i,j-1)) = -1;
            end
            
            % 检查上边界
            if mask(i,j+1)==0
                B(cnt,:) = B(cnt,:)+reshape(im(i,j+1,:),[],1)';
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
