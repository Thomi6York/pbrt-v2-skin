load S000normTexISONorm.mat
figure;imshow(lin2rgb(Out_Img));

% get mask

maskPath= "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\S000\shader\S000_E00_Mask.bmp";

mask = imread(maskPath);

mask(:,:,:) = mask(:,:,1) >0;

figure; imshow(mask);


maskedIm= zeros(size(Out_Img)); 

for channel = 1:3
    maskedIm(:,:,channel) = Out_Img(:,:,channel).*mask;  %apply the mask
end

figure; imshow(maskedIm)

subfacemask = mask; 
%% Modularisation
% get 3rd percentile w/mask for homogenous skin layer settings
chromPath = "C:\Users\tw1700\Downloads\Code_chromophores_estimation\";

load(strcat(chromPath, "\data\LUTs_luxeon_CIEcmfwithbeta.mat"));

load('inverse_rendering_data.mat')

faceMel = Out_Mel(subfacemask);

melPerc = prctile(Out_Mel(subfacemask),3, 'all');

disp(['3rd perc mel is: ' num2str(melPerc)])

% get 3rd percentile w/mask for homogenous skin layer settings
hemPerc = prctile(Out_Hem(subfacemask),3,'all');
disp(['3rd perc hem is: ' num2str(hemPerc)])

melInd = find(melPerc == Mel_sampling);
hemInd = find(hemPerc == Hem_sampling);
[~,betaInd] = min(abs(mean(Out_Beta,'all')-Beta_sampling)); %set this to the mean 
[~,epthInd] = min(abs(mean(Out_Epth,'all')-Epth_sampling)); %set this to the mean

refl = LUTs(betaInd,epthInd,melInd,hemInd,:); 
refl = reshape(refl,1,3);

% here use the original Out_Img as we have obtained percentile values from
% the masked image

vecIm = reshape(Out_Img,[],3);

normIm = vecIm./refl;
normIm = reshape(normIm, size(Out_Img));


disp('Displaying normalized texture');
figure; imshow(normIm);title('Normalized texture');


% Flip the image vertically
normIm = flipud(normIm);


figure; imshow(normIm);title('transformed for rendering');

%% save

fileName = "MaskedEyebrows.exr";
exrwrite(normIm,fileName); %write to the rendering directory 

disp(strcat('Saving texture to ', fileName,  '.exr as at current dir'));


%% print values
% these actually remain the same when eyebrows are masked, -- as is
% expected 
disp( strcat('Melanin 3rd percentile:', num2str(melPerc)));
disp( strcat('Hemoglobin 3rd percentile:', num2str(hemPerc)));
disp( strcat('melInd:', num2str(melInd)));
disp( strcat('hemInd:', num2str(hemInd)));
disp( strcat('betaInd:', num2str(betaInd)));
disp( strcat('mean beta val:', num2str(Beta_sampling(betaInd))));
disp( strcat('epthInd:', num2str(epthInd)));
disp( strcat('mean epth val:', num2str(Epth_sampling(epthInd))));

