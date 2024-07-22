%% One Shot Modulation 

% i made this so i could edit single heads 
%%

close all 
clear all

%%


subj =0; 
format longG;

currentDir = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\";
%set colorimetry shaderPath
chromPath = "C:\Users\tw1700\Downloads\Code_chromophores_estimation\";
cd(chromPath);

%add shaderPath to data
addpath(genpath('.\data\'));

%% load the image and maps
load("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\experiments\reRunWNormsandCorrectSpec\pigmentMaps\S000_newMapsISONorm.mat")

%% get reflection of third percentiles using LUT
load(".\data\LUTs_luxeon_CIEcmfwithbeta.mat");
load LUTs_Lab; % get the lab version to avoid computing on the fly
load('.\data\inverse_rendering_data.mat')
load('.\data\LED_spectrum_luxeon.mat');
light_spectrum = light_spectrum(21:10:321,2);

%read the paths from the txt file
cd(currentDir)
pathpath = "pathInfo.txt";
addpath(pathpath);

if exist(pathpath, 'file')
    disp('shaderPath file found')
else 
    disp('cannot find paths')
end

subsampling_factor_img = 1; % subsampling factor for the image for debugging purposes

debug = 1; % Set debug to 1 to enable debug statements

% normalise the textures
%load the csv with ISO values
isoValues = readtable(strcat(currentDir,'utilities\\csv\\CaptureISO_perSubject.csv'));


subjects = readmatrix(strcat(currentDir,'utilities\\csv\\subjects.csv'));
subjects = subjects'; 

subj_id_string = ['S' num2str(subj, '%03d')];

fileName = strcat(subj_id_string, 'OneShot');

% check whether maps are precalculated

% load the mask for the face
shaderPath = strcat('C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\', subj_id_string, '\shader\');
addpath(shaderPath);
face_mask = imread(strcat(shaderPath, subj_id_string, '_E00_Mask.bmp')); 
face_mask = face_mask(:,:,2)>0;

face_mask = face_mask(1:subsampling_factor_img:end,1:subsampling_factor_img:end); %subsample mask
%% append rendering stuff into a struct for neatness 


disp('Modulating texture via normalization with the 3rd percentile of the chromophores');

% get 3rd percentile w/mask for homogenous skin layer settings
faceMel = Out_Mel(face_mask);

melPerc = prctile(Out_Mel(face_mask),3, 'all');

disp(['3rd perc mel is: ' num2str(melPerc)])

% get 3rd percentile w/mask for homogenous skin layer settings
hemPerc = prctile(Out_Hem(face_mask),3,'all');
disp(['3rd perc hem is: ' num2str(hemPerc)])

melInd = find(melPerc == Mel_sampling);
hemInd = find(hemPerc == Hem_sampling);
[~,betaInd] = min(abs(mean(Out_Beta,'all')-Beta_sampling)); %set this to the mean 
[~,epthInd] = min(abs(mean(Out_Epth,'all')-Epth_sampling)); %set this to the mean


refl = LUTs(betaInd,epthInd,melInd,hemInd,:); 

%refl = LUTs(betaInd,epthInd,melInd,hemInd,:); 
refl = reshape(refl,1,3);

vecIm = reshape(Out_Img,[],3);

normIm = vecIm./refl;
normIm = reshape(normIm, size(Out_Img));

if debug
    disp('Displaying normalized texture');
    figure; imshow(normIm);title('Normalized texture');
end

% Flip the image vertically
normIm = flipud(normIm);

if debug
    figure; imshow(normIm);title('transformed for rendering');
end

exrwrite(normIm,strcat(currentDir, subj_id_string, fileName, '.exr')); %write to the rendering directory 
if debug
    disp(strcat('Saving texture to ', currentDir, subj_id_string, fileName,  '.exr'));
end
%%
% give it a blank permID
count = [];

% Write cache file
cacheFile = fullfile(currentDir, ['cache_OneShot' subj_id_string fileName '.txt']);
fid = fopen(cacheFile, 'w');
fprintf(fid, 'Subject: %s\n', subj_id_string);
fprintf(fid, 'Melanin 3rd percentile: %f\n', melPerc);
fprintf(fid, 'Hemoglobin 3rd percentile: %f\n', hemPerc);
fprintf(fid, 'melInd: %d\n', melInd);
fprintf(fid, 'hemInd: %d\n', hemInd);
fprintf(fid, 'betaInd: %d\n', betaInd);
fprintf(fid, 'mean beta val: %d \n', Beta_sampling(betaInd));
fprintf(fid, 'epthInd: %d\n', epthInd);
fprintf(fid, 'mean epth val: %d \n', Epth_sampling(epthInd));
fprintf(fid, 'permID: %d \n', count);
fclose(fid);
disp(['Wrote cache file to ' cacheFile]);