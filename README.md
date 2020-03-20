# An implementation of Poisson image editing

![result](http://q70i1gfoc.bkt.clouddn.com/possion/example.png)

# Usage

**demo.m** contains three subprograms.

- **Image Fusion**

```matlab
% source image
srcImg = im2double(imread('xxx.png'));
% background image
dstImg = im2double(imread('xxx.jpg'));
...
...
% Where 0 represents gradient guided fusion of source image
% and 1 represents mix gradient guided fusion
out = PIF(subDstImg, subSrcImg, mask, 1);
```

- **Image Edit**

- **Image tailing**



# For more information

- [Blog](https://www.lsflll.top/posts/8ad73f1a.html)
- [CSDN](https://blog.csdn.net/weixin_43194305/article/details/104928378)

