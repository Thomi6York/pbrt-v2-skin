clear all
close all
%%
brute_image = imread("bruteAlbedoBackground1.png");

pbrt_im = imread('BruteRenderpbrt.png');


figure; subplot(121);imshow(lin2rgb(brute_image));subplot(122);imshow(lin2rgb(pbrt_im));


%% 

absDiff = abs( brute_image-pbrt_im);



figure; 
for i =1:3
    subplot(1,3,i); imagesc(absDiff(:,:,i)); 
end

sgtitle('Absolute Difference for R, G and B channels respectivley')

