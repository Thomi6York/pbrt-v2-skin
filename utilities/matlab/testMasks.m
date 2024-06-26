[test,alpha] = exrread("S000ISONormnormTexISONormGammaCorrectedNormalsMasked.exr");

figure;imshow(test)

figure;histogram(test); 

%% 

input = imread("input.png");
output = imread("output.png");
mask = imread("mask.png");

figure; imshow(input)
figure; imshow(output)
figure; imshow(mask); 

%% Invert the mask

inverted_mask = ~mask(:,:,1);
figure;imshow(inverted_mask);

inverted_mask3D = zeros(720,1280,3);

for i = 1:3 
    inverted_mask3D(:,:,i) =  inverted_mask; 
end 

inverted_mask3D = logical(inverted_mask3D);
masked_region = zeros(size(output)); 


masked_region(inverted_mask3D) = output(inverted_mask3D);

masked_region = masked_region/255;
figure;imshow(masked_region);title('masked region')

%%
new_im = output;

new_im(inverted_mask3D) = input(inverted_mask3D); % write over with face

figure;imshow(new_im)


