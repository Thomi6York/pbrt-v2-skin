%% spec mapping
close all
clear all

% load images


imagePath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\matlab\S000normTexISONorm.mat"; %load from pigment maps bc image is normalised
specPath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\S000\shader\spec_textureISONormFlipped.exr";

%spec text
spec = exrread(specPath);
spec = flipud(spec); % flip due to saving

%inverse rendered map
load(imagePath);
im = Out_Img; 

%view them

figure;imshow(spec);title("spec text iso norm");
figure;imshow(im);title("immap")


% hists for heads

figure;
subplot(121);histogram(im(:));title("map vals");
subplot(122);histogram(spec(:));title("vals")

%% plot a scanline along the head
% i chose a line between 422,418 and 959,418 -- lets do 10 samps
sampl = 100;
interval = ((959-422)/sampl);
interval = round(interval); 


lineIm = im(422:interval:959,418,1); 
lineSpec = spec(422:interval:959,418,1); 

%% plot the function
figure; scatter(lineIm,lineSpec); title("spec vs map, scanline across forehead");
xlabel("Albedo vals, linRGB");
ylabel("Specular vals,linRGB");