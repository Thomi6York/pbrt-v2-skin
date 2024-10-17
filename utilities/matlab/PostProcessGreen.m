%PostGreen 
%perm 5 is always GT
path = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\experiments\MultipleScalings\groundTruth\perms\S000_PermNo_5_ManipnormTexISONormnormTexISONormFinalMultiplicative2.0.exr"; 
%% load the ground truth image i.e. pigmentation is GT or perm whatever 
im = exrread(path);

%% load its mask 
% this should be in the files for SD painting -- actually just load uv pass
% and thresh it

uv = exrread("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\UVPasses\UVSubj000.exr");
mask = uv; 

mask(uv>0.5) = 1; % should thresh it

%remove other color channels
mask = mask(:,:,1); 
mask = logical(mask);

ImSize = size(im);

%% apply mask, multiply by coeff

% matrices
m1 = [0.3327    0.2720    0.0332;
    0.0739    0.6985    0.2399;
    0.0261    0.2397    0.5592]; 
m2 =   [ 0.3218    0.1676    0.0508;
    0.0391    0.7636    0.2087;
    0.0123    0.1908    0.5066]; 



%mask
vecIm = zeros(size(mask,1)*size(mask,2),3);
vecIm(mask) = im(mask);

%vectorize
for i = 1:3
    tmp = im(:,:,i);
    vecIm(:,i) = tmp(:);
end


outVec = vecIm*m1;


%% reshape

%copy background in 
outIm = reshape(outVec,ImSize);

% make mask 3d
for i =1:3 
    mask3D(:,:,i) = mask;
end

figure; imshow(im);

outIm(~mask3D) = double(im(~mask3D));

figure; imshow(lin2rgb(outIm))

exrwrite(outIm,'PostGreenIm.exr');

