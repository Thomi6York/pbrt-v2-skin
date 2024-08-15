clear all
close all
%%
brute_image = imread("bruteAlbedoBackground1.png");

pbrt_im = imread('BruteRenderpbrt.png');

figure; subplot(121);imshow(lin2rgb(brute_image));subplot(122);imshow(lin2rgb(pbrt_im));

% print min and max vals
fprintf('Min and Max values for Brute Image: %f, %f\n', min(brute_image(:)), max(brute_image(:)));
fprintf('Min and Max values for PBRT Image: %f, %f\n', min(pbrt_im(:)), max(pbrt_im(:)));

% normalize the images
brute_image = double(brute_image)/65535; % 65535 is the maximum value for 16 bit image
pbrt_im = double(pbrt_im)/65535;

%% 

absDiff = abs( brute_image-pbrt_im);



figure; 
for i =1:3
    subplot(1,3,i); imagesc(absDiff(:,:,i)); colorbar; 
    clim([0,0.1]); % Set the limits for the color scale to the upper and lower 10th percentile
end

sgtitle('Absolute Difference for R, G and B channels respectivley');

