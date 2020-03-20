function out = PIE(im, mask, method, srcImg)
% possion image edit
% -input-
%   "im"        Դͼ��
%   "mask"      ��ѡ����
%   "method"    �ݶȴ�����
%   "srcImg"    ����tiling��������Ҫ����ԭʼ����ͼ��
%
% -method-  Ŀǰ�еļ��ִ����������Զ����޸�
%   "none"  ƽ��������䣨ä��ֵ�� 
%   "flatten"   ��Ե����ȥ����
%   "color"     ��ɫ����
%   "flip"   ���ݷ�ת������������һ������ߣ�
%   "tiling"    ƴ��
% -output-
%   "out"   double����
%
if nargin<2
    error('��������һ��ͼ��Ͷ�Ӧmask');
end

if nargin<3
    method = 'none';
end

if nargin == 3 && strcmp(method,'tailing')
    error('�������ƴ�ӵ�ԭʼͼ��');
end

out = im;
%ͳ�Ʒ���㣬����Ҫ�ںϲ���
num = nnz(mask);

[m,n] = size(mask);

%���ÿһ����Ҫ�ںϵ������
%0��ʾ��֪�ı߽����أ�1Ϊδ֪��������
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

% �������ģ���Ax=B���ֱ𹹽�A��B
% ������˹������4�������ϵĶ�������˲���
k = {[1 -1 0],[0 -1 1],[1;-1;0],[0;-1;1]};
lap=0;
% ---------�˴������ݶ���ȡ�ò�ͬЧ��---------
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
        error('û�����������ķ��������Զ���');
end


% ����ϡ���ϵ������A
coeffNum=5;
A=spalloc(num,num,num*coeffNum);
% ����ͨ��������B
% Ax=B�У�A��n*n   x��n*c    B��n*c,  nΪ������,cΪͨ����
B=zeros(num,size(im,3));

% ���A
cnt = 0;
for i=2:m-1
    for j=2:n-1
        if mask(i,j)==1
            cnt = cnt+1;
            A(cnt,cnt) = 4;
            
            % �����߽�
            if mask(i-1,j)==0
                B(cnt,:) = reshape(im(i-1,j,:),[],1);
            else
                A(cnt,map(i-1,j)) = -1;
            end
            
            % ����ұ߽�
            if mask(i+1,j)==0
                B(cnt,:) = B(cnt,:)+reshape(im(i+1,j,:),[],1)';
            else
                A(cnt,map(i+1,j)) = -1;
            end
              
            % ����±߽�
            if mask(i,j-1)==0
                B(cnt,:) = B(cnt,:)+reshape(im(i,j-1,:),[],1)';
            else
                A(cnt,map(i,j-1)) = -1;
            end
            
            % ����ϱ߽�
            if mask(i,j+1)==0
                B(cnt,:) = B(cnt,:)+reshape(im(i,j+1,:),[],1)';
            else
                A(cnt,map(i,j+1)) = -1;
            end
            
            % ���B
            B(cnt,:)=B(cnt,:)-reshape(lap(i,j,:),[],1)';
        end
    end
end

% ���
X=A\B;

% �ڶ�άͼ���и�ֵ
for cnt=1:size(X,1)
    [idx_x,idx_y]=find(map==cnt);
    out(idx_x,idx_y,:)=reshape(X(cnt,:),1,1,3);
end
