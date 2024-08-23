%PostGreen 
path = "E:\Skin_code\data\ICT_3DRFE_mod\S000\shader\"; 
%% load the ground truth image i.e. pigmentation is GT or perm whatever 
im = exrread(path);

%% load its mask 
% this should be in the files for SD painting -- actually just load uv pass
% and thresh it

uv = exrread("E:\pbrt-v2-skinPat\UVPasses\UVSubj000.exr");
mask = uv; 

mask(uv>0.5) = 1; % should thresh it

%remove other color channels
mask = mask(:,:,1); 


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
vecIm = zeros(size(mask));
vecIm(mask) = im(mask);

%vectorize
for i = 1:3
    tmp = im(:,:,i);
    vecIm(:,i) = tmp(:);
end


outVec = ImvecIm*m1;


%% reshape

outIm = reshape(outVec,ImSize);

%copy background in 
outIm(~mask) = im(~mask);


exrwrite(outIm,'PostGreenIm.exr');

