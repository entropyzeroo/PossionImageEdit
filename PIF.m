function out = PIF(dstImg, srcImg, mask, mix)
% Fuction: Possion Image Fusion
% �����ںϣ���Դͼ����Ŀ��ͼ���޷��ں�
%  -ʹ�÷���-
%	im_out = PIE(destinationImg,sourceImg,mask,0); %�����޷��ں�
%   im_out = PIE(destinationImg,sourceImage,mask,1); %����ݶȲ����޷��ں�
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ����:
%   P��rez, Patrick, Michel Gangnet, and Andrew Blake.
%   "Poisson image editing." ACM Transactions on Graphics (TOG). Vol. 22.
%   No. 3. ACM, 2003.
%  -����-
%	 dstImg: Ŀ��ͼ�񣨱���ͼ��,��һ��double��ʽ
%    srcImg: Դͼ�񣨴�����ͼ��,��һ��double��ʽ
%    mask: ��Ĥ���ں�����,0-1
%    mix: 0Ϊ�����޷��ں�, 1Ϊ����ݶȲ����޷��ںϣ�Ĭ�ϣ�
%  -���-
%    out: ����mask��С���ں�ͼ�񣬹�һ��double��ʽ

if nargin<3
    error('��������3�����ݣ�PIE(dstImg, srcImg, mask)')
end

if nargin<4
    mix = 1;
end

%��ʼ�����
out = dstImg;
%ͳ�Ʒ���㣬����Ҫ�ںϲ���
num = nnz(mask);

[m,n] = size(mask);

%���ÿһ����Ҫ�ںϵ������
%0��ʾ��֪���ܱ����أ�1Ϊδ֪��������
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

% ������˹ģ�壬����seamless cloneֱ����ȡlaplacianͼ
laplacian_mask = [0 1 0;1 -4 1;0 1 0];
% 4��������˲�ģ�壬�Ա�������˹���ӣ�����ֿ��󣬲�Ȼ�ڱ߽���ܻ�������
k = {[1 -1 0],[0 -1 1],[1;-1;0],[0;-1;1]};

if mix==1
    % ������ݶȲ����ں�ʱ��lapͼ
    lap=0;
    for d=1:4
        d_grad = imfilter(dstImg, k{d});
        s_grad = imfilter(srcImg, k{d});
        tempmask = abs(s_grad)>abs(d_grad);
        % ȡ�ϴ��ݶ�
        mix_grad = s_grad.*tempmask+d_grad.*(tempmask==0);
        lap = lap+mix_grad;
    end
else
    % ֱ�Ӳ����ں�ʱ��lapͼ
    lap = imfilter(srcImg, laplacian_mask);
end

% ����ϡ���ϵ������A
coeffNum=5;
A=spalloc(num,num,num*coeffNum);
% ����ͨ��������B
% Ax=B�У�A��n*n   x��n*c    B��n*c,  nΪ������,cΪͨ����
B=zeros(num,size(dstImg,3));

% ���A
cnt = 0;
for i=2:m-1
    for j=2:n-1
        if mask(i,j)==1
            cnt = cnt+1;
            A(cnt,cnt) = 4;
            
            % �����߽�
            if mask(i-1,j)==0
                B(cnt,:) = reshape(dstImg(i-1,j,:),[],1);
            else
                A(cnt,map(i-1,j)) = -1;
            end
            
            % ����ұ߽�
            if mask(i+1,j)==0
                B(cnt,:) = B(cnt,:)+reshape(dstImg(i+1,j,:),[],1)';
            else
                A(cnt,map(i+1,j)) = -1;
            end
              
            % ����±߽�
            if mask(i,j-1)==0
                B(cnt,:) = B(cnt,:)+reshape(dstImg(i,j-1,:),[],1)';
            else
                A(cnt,map(i,j-1)) = -1;
            end
            
            % ����ϱ߽�
            if mask(i,j+1)==0
                B(cnt,:) = B(cnt,:)+reshape(dstImg(i,j+1,:),[],1)';
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
