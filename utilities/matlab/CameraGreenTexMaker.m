%% Load ims 

path = "E:\Skin_code\data\ICT_3DRFE_mod\S000\shader\"; 

im = imread(strcat(path, "diff_texture.bmp"));

%% 

m1 = [0.3327    0.2720    0.0332;
    0.0739    0.6985    0.2399;
    0.0261    0.2397    0.5592]; 
m2 =   [ 0.3218    0.1676    0.0508;
    0.0391    0.7636    0.2087;
    0.0123    0.1908    0.5066]; 


% norm im to double
im = rgb2lin(im);
im = double(im)/255;

for i = 1:3
    tmp = im(:,:,i);
    vecIm(:,i) = tmp(:);
end

figure; imshow(im);

%% perform the conv

im1 = vecIm*m1;
tmp1 = im1;
im2 = vecIm*m2;
tmp2 = im2;

%% disp 

im1 = reshape(im1,size(im));
im2 = reshape(im2,size(im));
figure;
subplot(121)
imshow(lin2rgb(im1)); title('m1');
subplot(122);
imshow(lin2rgb(im2)); title('m2')

%% go back again 


tmp1 = tmp1 *inv(m1);
tmp2 = tmp2 *inv(m2);

tmp1 = reshape(tmp1,size(im));
tmp2 = reshape(tmp2,size(im));

figure; subplot(121); imshow(lin2rgb(tmp1));
subplot(122);imshow(lin2rgb(tmp2)); 

%% exr write

exrwrite(im1,"GreenIm1.exr");
exrwrite(im2,"GreenIm2.exr")
