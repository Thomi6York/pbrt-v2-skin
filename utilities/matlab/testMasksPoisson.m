%% close all
close all
% [test,alpha] = exrread("S000ISONormnormTexISONormGammaCorrectedNormalsMasked.exr");
% 
% figure;imshow(test)
% 
% figure;histogram(test); 
pbrtPath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\"; 
out_imPath = "results/experiments/InterpLUTCheck/groundTruth/perms/";
subsample = 1; % subsample factor for debugging
subj_id = 0;
subj_id_string = ['S' num2str(subj_id, '%03d')];
permNo = 1; 

% inImName = strcat(subj_id_string,"_PermNo_",num2str(permNo),"_ManipnormTexISONormnormTexISONormLinearTexturesDoubleHalfScalingMultiplicative.png"); 
inImName = "results\experiments\InterpLUTCheck\groundTruth\perms\S000_PermNo_1_ManipnormTexISONormnormTexISONormFixedinterpolationMultiplicative.png"; 

dir = "utilities/matlab/outpaintedImages/S000/";

dir = strcat(pbrtPath,dir);

%% 

% note! doesn't work with normalised images for some reason -- lets check
% the documentation 
%input = exrread(strcat(pbrtPath,out_imPath,inImName));
input = imread(strcat(pbrtPath,inImName));
output = imread(strcat(dir,"PermNo_1_outpainting.png"));
mask = exrread(strcat(dir,"outMask.exr"));



figure; imshow(lin2rgb(input))
input = lin2rgb(input);
figure; imshow(output)
figure; imshow(mask); 

figure; histogram(output);
%% normalise input image
figure; imshow(output);
% output = double(output)./255;
%  input = double(input)./255;

figure; subplot(121);imshow(output);title('output');
subplot(122);imshow(input);title('input');
% figure; histogram(output);
%% Invert the mask
 mask(0.5<mask) = 1;
 mask(0.5>=mask) = 0; 


% inverted_mask = ~mask(:,:,1);
% 
% inverted_mask(0.5<inverted_mask) = 1;
% inverted_mask(0.5>=inverted_mask) = 0; 
% 
% figure;imshow(inverted_mask);
% 
% inverted_mask3D = zeros(720,1280,3);
% 
% for i = 1:3 
%     inverted_mask3D(:,:,i) =  inverted_mask; 
% end 
% 
% inverted_mask3D = logical(inverted_mask3D);
 masked_region = zeros(size(output)); 

mask3d = zeros(720,1280,3);
for i = 1:3
    mask3d(:,:,i) = mask(:,:,1);
end

mask3d = logical(mask3d);
%optional invert
%mask3d =~mask3d; 

mask =double(~mask); 
masked_region(mask3d) = output(mask3d);
figure;imshow(masked_region);title('masked region')

%% subsample images for debugging
input = input(1:subsample:end,1:subsample:end,:);
output = output(1:subsample:end,1:subsample:end,:);
mask = mask(1:subsample:end,1:subsample:end,:);
mask3d = mask3d(1:subsample:end,1:subsample:end,:);
%%
new_im = output;
figure; subplot(131);imshow(output);title('output');subplot(132);imshow(input); title('input'); subplot(133);imagesc(mask); title('mask');

new_im(mask3d) = input(mask3d); % write over with face

figure;imshow(new_im);title('composited image')

%% poisson step
% https://uk.mathworks.com/matlabcentral/fileexchange/62287-poisson-image-editing?status=SUCCESS

%^pie from here -- make sure to reference as per read me
im_out = PIE(input,output,mask,0,0);
%new Im 
figure;imshow(new_im)
figure;imshow(masked_region);title('masked region');

% blended im
figure;imshow(im_out); title('blended image')
%% move plots to bottom for time

% first files
figure; subplot(131); imshow(input)
subplot(132); imshow(output)
subplot(133); imshow(mask); 




%% look at signed difference 

sig_im = input; 
figure
for i =1:3
    sig_im(:,:,i) = abs(new_im(:,:,1) - im_out(:,:,1));
    subplot(1,3,i)
    imagesc(sig_im(:,:,i));
end



figure; subplot(121);imshow(new_im);title('Composited image without blending')
subplot(122);imshow(im_out);title('Poisson blended composit im')


