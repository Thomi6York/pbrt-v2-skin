%% spec mapping
close all
clear all

%% load images

dataSetPath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\S000\shader\";
imagePath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\matlab\S000normTexISONorm.mat"; %load from pigment maps bc image is normalised
specPath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\S000\shader\spec_textureISONormFlipped.exr";
normalPath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\S000\shader\spec_normalFlipped.exr";
diffRN = strcat(dataSetPath, "diff_normal_r.bmp");
diffBN = strcat(dataSetPath, 'diff_normal_b.bmp');
diffGN = strcat(dataSetPath, 'diff_normal_g.bmp');

% here we have all the diffuse normals -- load them in 
RNI = imread(diffRN);
GNI = imread(diffGN);
BNI = imread(diffBN);

% convert to linear
RNI = rgb2lin(RNI);
GNI = rgb2lin(GNI);
BNI = rgb2lin(BNI);

% convert to double
RNI = double(RNI)./255;
GNI = double(GNI)./255;
BNI = double(BNI)./255;




%normal
normal = exrread(normalPath);
normal = flipud(normal);

%spec text
spec = exrread(specPath);
spec = flipud(spec); % flip due to saving

%spec

%inverse rendered map
load(imagePath);
im = Out_Img; 

%% correct specular textures accounting for nomals by dividing by the cosine 
% load in normals 

coNorm = cos(normal);

coNormR = cos(RNI);
coNormG = cos(GNI);
coNormB = cos(BNI); 


rDiff = im(:,:,1)./coNormR;
gDiff = im(:,:,2)./coNormG;
bDiff = im(:,:,3)./coNormB; 

adjSpec = spec./coNorm; %-- should just be fine to use the map
adjDiff = im./coNorm; 

%view them

figure;subplot(121);imshow(spec);title("spec text iso norm"); subplot(122);imshow(adjSpec);title('Adjused Spec for normals')
figure;imshow(rDiff);title("R Diff adjusting for cos")
figure;imshow(normal);title("normal");

% hists for heads

figure;
subplot(121);histogram(im(:));title("map vals");
subplot(122);histogram(spec(:));title("vals")

%% plot a scanline along the head
% i chose a line between 422,418 and 959,418 -- lets do 10 samps
sampl = 100;
interval = ((959-422)/sampl);
interval = round(interval); 


lineDiff =adjDiff(422:interval:959,418,1); 
RDiffLine = rDiff(422:interval:959,418,1);
GDiffLine = gDiff(422:interval:959,418,1);
BDiffLine = bDiff(422:interval:959,418,1);

lineSpec = spec(422:interval:959,418,1); 
lineAdjSpec = adjSpec(422:interval:959,418,1);

%% plot the function
figure; plot(lineDiff,lineSpec); title("spec vs map, scanline across forehead");
xlabel("Albedo vals, linRGB");
ylabel("Specular vals,linRGB");

figure;plot(lineDiff,lineAdjSpec);title('adjusted spec for normals');
xlabel("Albedo vals, linRGB");
ylabel("Specular vals,linRGB");

figure;plot((422:interval:959),lineAdjSpec); title('spec vs scanline');
xlabel("scaline")
ylabel("Adjusted Specularity")

figure;plot((422:interval:959),lineSpec); title('standard specularity');
xlabel("scaline")
ylabel("Raw Specularity")

figure;plot((422:interval:959),lineDiff); title('Diffuse against scanline');
xlabel("scaline")
ylabel("Adj Diffuse")

figure; subplot(131);plot((422:interval:959),RDiffLine);title("R Diffuse"); 
subplot(132);plot((422:interval:959),GDiffLine);title("G Diffuse");
subplot(133);plot((422:interval:959),BDiffLine);title("B Diffuse");
