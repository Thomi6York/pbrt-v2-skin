%%
%% Note to self -- this is for inverse rendering using the shading for eyebrows
% manually reasign options since it'll load whatever is being used from the
% last run 
%% 
close all 
clear all

%%

format longG;

currentDir = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\";
%set colorimetry shaderPath
chromPath = "C:\Users\tw1700\Downloads\Code_chromophores_estimation\";
cd(chromPath);

%add shaderPath to data
addpath(genpath('.\data\'));

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


pathInfo = readcell(pathpath);
% isolate the shaderPath from the brackets
TexPath = char(extractBetween(pathInfo{1}, '"', '"'));
TexPath = TexPath(2,:);
renderingPath = char(extractBetween(pathInfo{2}, '"', '"'));
scenePath = char(extractBetween(pathInfo{3}, '"', '"'));
dataSetPath = char(extractBetween(pathInfo{4}, '"', '"'));
cachePath = char(extractBetween(pathInfo{5}, '"', '"'));
meshPath = char(extractBetween(pathInfo{6}, '"', '"'));
pigPath = char(extractBetween(pathInfo{7}, '"', '"'));
fileHandle = char(extractBetween(pathInfo{8}, '"', '"'));
pathHandle = char(extractBetween(pathInfo{9}, '"', '"'));
fileName = char(extractBetween(pathInfo{10}, '"', '"'));


addpath(renderingPath);
addpath(scenePath);
addpath(dataSetPath);
addpath(meshPath);
addpath(pigPath);


subsampling_factor_img = 1; % subsampling factor for the image for debugging purposes

debug = 0; % Set debug to 1 to enable debug statements

% normalise the textures
%load the csv with ISO values
isoValues = readtable(strcat(currentDir,'utilities\\csv\\CaptureISO_perSubject.csv'));


subjects = readmatrix(strcat(currentDir,'utilities\\csv\\subjects.csv'));
subjects = subjects'; 


%load repeat options txt file
options = fileread(strcat(currentDir,'utilities\\text\\options.txt'));

repeat = options(1) =='1';


fixBandK = options(2)=='1'; 

%% append rendering stuff into a struct for neatness 

rendering = struct('subj', 0, 'subj_id_string',0, ...
    'TexPath', TexPath, 'shaderPath', '', 'renderingPath', renderingPath, 'scenePath', scenePath, 'dataSetPath', dataSetPath, 'cachePath', cachePath, 'meshPath', meshPath, 'pigPath', pigPath, ...
    'isoValues', isoValues, 'LUTs', LUTs, 'LUTs_Lab', LUTs_Lab, 'light_spectrum',light_spectrum, 'CMFs',CMFs,...
    'Mel_sampling', Mel_sampling, 'Hem_sampling', Hem_sampling, 'Epth_sampling', Epth_sampling, 'Beta_sampling', Beta_sampling, ...
    'subsampling_factor_img', subsampling_factor_img, 'face_mask', [], 'debug', debug, 'fixBandK', fixBandK, 'repeat', repeat, 'fileHandle', fileHandle, 'pathHandle', pathHandle, 'fileName', fileName);

%% change stuff here 

rendering.TexPath = 'C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\matlab\'; % just save here for demo
rendering.debug=1; 
rendering.fixBandK =1; 
repeat = 1; 
rendering.pigPath = 'C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\matlab\';
rendering.subsampling_factor_img = 1; 

if exist(rendering.pigPath, 'file')
    disp('pigPath file found')
else 
    disp('cannot find paths')
end

if exist(rendering.TexPath, 'file')
    disp('TexPath file found')
else 
    disp('cannot find paths')
end
%%
for subj = 0
    rendering.subj_id_string = ['S' num2str(subj, '%03d')];

    % check whether maps are precalculated
   
    % load the mask for the face
    rendering.shaderPath = strcat('C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\', rendering.subj_id_string, '\shader\');
    addpath(rendering.shaderPath);
    rendering.face_mask = exrread(strcat(rendering.shaderPath, rendering.subj_id_string, '_E00_MaskEyebrow.exr')); 
    rendering.face_mask = rendering.face_mask(:,:,2)>0;

    rendering.face_mask = rendering.face_mask(1:rendering.subsampling_factor_img:end,1:rendering.subsampling_factor_img:end); %subsample mask
    
%%
    %mapName = strcat(rendering.pigPath, rendering.subj_id_string, '_newMapsISONorm.mat');
    %check for pig maps
    if repeat % only repeat if we want too
        disp('Repeat flag set');
        disp(strcat('Inverse rendering in progress for subject: ', rendering.subj_id_string));
        [Out_Mel,Out_Hem,Out_Beta,Out_Epth,Out_Img, subfacemask] = inverse_rendering(rendering);
    end

    if fixBandK % if we want to fix the beta and K values
        rendering = loadOldMapsandEdit(rendering);
        Out_Mel = rendering.Out_Mel;
        Out_Hem = rendering.Out_Hem;
        Out_Beta = rendering.Out_Beta;
        Out_Epth = rendering.Out_Epth;
        Out_Img = rendering.Out_Img;
        subfacemask = rendering.face_mask;

        save(strcat(rendering.pigPath, rendering.subj_id_string, rendering.fileName, '.mat'),"Out_Epth", "Out_Beta","Out_Hem","Out_Img","Out_Mel");
%%
    else 

        disp('Loading pre-existing maps');

        load(mapName);
        disp('Old Maps loaded');
        if rendering.debug
            Input_Img = imread([rendering.shaderPath '\diff_texture.bmp']); 
            disp('Input diff texture loaded ')
            figure;imshow(Input_Img);title('Original Diffuse texture')
            figure;imshow(Out_Img);title('Inverse renderinged Img');
        end
        
    end
    
    if rendering.debug
        disp('Displaying input texture, linear');
        figure; imshow(lin2rgb(Out_Img)); title('Inverse texture, linear');
    end

    disp('Modulating texture via normalization with the 3rd percentile of the chromophores');

    % get 3rd percentile w/mask for homogenous skin layer settings
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

    refl = rendering.LUTs(betaInd,epthInd,melInd,hemInd,:); 
    refl = reshape(refl,1,3);

    vecIm = reshape(Out_Img,[],3);

    normIm = vecIm./refl;
    normIm = reshape(normIm, size(Out_Img));

    if rendering.debug
        disp('Displaying normalized texture');
        figure; imshow(normIm);title('Normalized texture');
    end
    
    % Flip the image vertically
    normIm = flipud(normIm);

    if rendering.debug
        figure; imshow(normIm);title('transformed for rendering');
    end
    
    exrwrite(normIm,strcat(rendering.TexPath, rendering.subj_id_string, fileName, '.exr')); %write to the rendering directory 
    if rendering.debug
        disp(strcat('Saving texture to ', rendering.TexPath, rendering.subj_id_string, fileName,  '.exr'));
    end

    % give it a blank permID
    count = [];
    
    % Write cache file
    cacheFile = fullfile(cachePath, ['cache_' rendering.subj_id_string fileName '.txt']);
    fid = fopen(cacheFile, 'w');
    fprintf(fid, 'Subject: %s\n', rendering.subj_id_string);
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
end 

disp('All subjects done');


%% make a 1d function to speed it up

function distance_94=DeltaE_94_pix_to_Matrix1D(Lab1, M_Lab2)

    kl = 1;
    kc = 1;
    kh = 1;
    K1 = 0.045;
    K2 = 0.015;
    
    delta_L = Lab1(1) - M_Lab2(:,1);
    C1 = sqrt((Lab1(2)^2 + (Lab1(3)^2)));
    C2 = sqrt((M_Lab2(:,2).^2 + (M_Lab2(:,3).^2)));
    delta_Cab = C1 - C2;
    delta_a = Lab1(2) - M_Lab2(:,2);
    delta_b = Lab1(3) - M_Lab2(:,3);
    delta_Hab = sqrt((delta_a).^2 + (delta_b).^2 - (delta_Cab).^2);
    Sl = 1;
    Sc = 1 + K1*C1;
    Sh = 1 + K2*C1;
    
    
    
    distance_94 = sqrt( ((delta_L)/(kl*Sl)).^2 + ((delta_Cab)/(kc*Sc)).^2 + ((delta_Hab)/(kh*Sh)).^2); 
end
%%
function rendering = loadOldMapsandEdit(rendering) % fix old maps
    %load the old maps

    %originalISONormPath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\pigmentMaps\"; 
    
    %originalISONormPath = rendering.pigPath; %-- specify custom handle here

    load(strcat(rendering.pigPath, rendering.subj_id_string, rendering.fileName,'.mat'));
    
    disp('Old Maps loaded');

    %load("C:\Users\tw1700\Downloads\Code_chromophores_estimation\data\inverse_rendering_data.mat"); 

    if rendering.debug
        Input_Img = imread([rendering.dataSetPath  rendering.subj_id_string  '\shader\diff_texture.bmp']); 
        disp('Input diff texture loaded ')
        figure;imshow(Input_Img);title('Original Diffuse texture')

    end 

    % edit the old maps
    face_mask = rendering.face_mask; 

    dims = size(Out_Img);
    R = dims(1);
    C = dims(2);

    best_Beta = getBeta(rendering); % get the mode sub here

    Out_Beta(face_mask) = rendering.Beta_sampling(best_Beta); % set all the beta values to the mode

    Out_Epth(face_mask & (Out_Epth>110)) = 110; % set all the epidermal thickness values to 11 
    Out_Epth(face_mask & (Out_Epth<30)) = 30; % set all the epidermal thickness values to 3

    %return to the struct 
    rendering.Out_Beta = Out_Beta;
    rendering.Out_Epth = Out_Epth;
    rendering.Out_Hem = Out_Hem;
    rendering.Out_Mel = Out_Mel; 

    % reconstruct the image
    Out_Img = zeros(R,C,3); % output 3D equivalent of the renderinged image

    indHem = zeros(R,C);
    indMel = indHem;
    indBeta = indHem;
    indEpth = indHem;

    [~,indBeta] = min(abs(Out_Beta(face_mask)-rendering.Beta_sampling),[],2); %should be the same if we've reclamped the previous values 
    [~,indEpth] = min(abs(Out_Epth(face_mask)-rendering.Epth_sampling),[],2);
    [~,indMel] = min(abs(Out_Mel(face_mask)-rendering.Mel_sampling'),[],2);
    [~,indHem] = min(abs(Out_Hem(face_mask)-rendering.Hem_sampling'),[],2); %need to transpose these sampled for subtraction 

    %vectorize the in
    indBeta = reshape(indBeta,[],1);
    indEpth = reshape(indEpth,[],1);
    indMel = reshape(indMel,[],1);
    indHem = reshape(indHem,[],1);

    % get length of the indices
    B = length(rendering.Beta_sampling);
    K = length(rendering.Epth_sampling);
    M = length(rendering.Mel_sampling);
    N = length(rendering.Hem_sampling);

    Out_Img = zeros(R*C,3); % output 2D equivalent of the renderinged image
    face_mask = reshape(face_mask,[],1);

    LUT_vec = reshape(rendering.LUTs, [], 3); % convert 5D LUT to a vector
    
    % Convert subscripts to linear indices
    linear_index = sub2ind([B, K, M, N], indBeta, indEpth, indMel, indHem);

    % Retrieve the corresponding value from the vectorized LUT
    Out_Img(face_mask,:) = LUT_vec(linear_index,:);
    

    %Out_Img(face_mask,:) =  LUT_vec(indBeta,indEpth,indMel,indHem,:); % retrieve the corresponding value from the vectorized LUT

    rendering.Out_Img = reshape(Out_Img, R, C, 3); % new image to return

    if rendering.debug
        figure;imshow(rendering.Out_Img); title('edited image'); 
    end 
    

end

function [Out_Mel,Out_Hem,Out_Beta,Out_Epth,Out_Img, subfacemask] = inverse_rendering(rendering)
            tic
            %load image 
            Input_Img = imread([rendering.shaderPath '\diff_texture.bmp']); 
            Input_Img = (double(Input_Img(1:rendering.subsampling_factor_img:end,1:rendering.subsampling_factor_img:end,:))./255).^2.2; % subsample the image and convert to linear space
            true_Input = Input_Img;
            %normalise ISOs
            ISO = rendering.isoValues(rendering.subj +1,2);
            ISO = table2array(ISO);
            ISOref = 250; %min ISO from table

            %Input_Img_spec = imread([rendering.shaderPath '\spec_texture.bmp']);

            %normalise 
            Input_Img = (Input_Img.*ISOref)/ISO;
            
          
            %face_mask = rendering.face_mask(1:rendering.subsampling_factor_img:end,1:rendering.subsampling_factor_img:end); %subsample mask
            subfacemask =rendering.face_mask; % return this
    
            if rendering.debug
                disp('Displaying unedited input image');
                figure; subplot(121); imshow(lin2rgb(Input_Img)); title('unedited input im (iso normalised)'); subplot(122); imshow(lin2rgb(true_Input)); title('true Input');
            end
            %% standard image loading 
            LUTs_Dims = size(rendering.LUTs);
            
            B = LUTs_Dims(1);
            K = LUTs_Dims(2);
            M = LUTs_Dims(3);
            N = LUTs_Dims(4);
    
            dims = size(Input_Img);
            R = dims(1);
            C = dims(2);
            vecIm = reshape(Input_Img,[],3);
    
    
            Out_Mel = zeros(length(vecIm),1); % output 2D melanin map
            Out_Hem = zeros(length(vecIm),1); % output 2D hemoglabin map
            Out_Epth = zeros(length(vecIm),1); % output 2D Epidermal thickness map
            Out_Img = zeros(length(vecIm),3); % output 3D equivalent of the renderinged image
            Out_Beta = Out_Epth; 
    
            
            
    
            delta_lambda=10;
            Light_XYZ = Spec_To_XYZ(rendering.light_spectrum, rendering.CMFs, delta_lambda); % converting the light spactrum to its XYZ values
            Img_Lab = rgb2lab(vecIm,'WhitePoint', Light_XYZ, 'ColorSpace', 'linear-rgb');
    
            disp(strcat('Inverse rendering in progress... for subject: ' ,rendering.subj_id_string));
            progressBar = waitbar(0, strcat('Inverse rendering ', rendering.subj_id_string,  'in progress...'));
            maskIm = vecIm(rendering.face_mask,:);
            maskImLab = Img_Lab(rendering.face_mask,:);
            maskCorrespondence =  1:length(vecIm);
            maskCorrespondence = maskCorrespondence(rendering.face_mask); %tells us correspondence between mask and image
    
            LUT_vec = reshape(rendering.LUTs, [], 3); % convert 5D LUT to a vector
            LUTs_Lab_vec = reshape(rendering.LUTs_Lab, [], 3); % convert 5D LUT to a vector
    
            for i = 1 : size(maskIm,1)
                    Pix_Lab_tmp=[maskImLab(i, :)];
    
                        % Perform the entire search without a loop
                        %reshape pixels to 3D for lookup
                        distances = DeltaE_94_pix_to_Matrix1D(Pix_Lab_tmp, LUTs_Lab_vec); % distances between pixel in the image and current lookup table
                        [tmp_min, linear_index] = min(distances(:)); % find the minimum distance and its linear index
                        [beta_eum, Best_K, Best_M, Best_N] = ind2sub(size(rendering.LUTs), linear_index); % convert linear index to subscripts
    
                        Out_Img(maskCorrespondence(i),:) = LUT_vec(linear_index, :); % retrieve the corresponding value from the vectorized LUT
                        Out_Mel(maskCorrespondence(i)) = rendering.Mel_sampling(Best_M); % storing the best Mel_sampling into Output Mel
                        Out_Hem(maskCorrespondence(i)) = rendering.Hem_sampling(Best_N);
                        Out_Epth(maskCorrespondence(i)) = rendering.Epth_sampling(Best_K);
                        Out_Beta(maskCorrespondence(i)) =  rendering.Beta_sampling(beta_eum);
                        progress = i / length(vecIm) * 100;
                    if mod(round(progress,2),0.1) == 0 %only every whole perc to speed up
                        waitbar(progress / 100, progressBar, sprintf('Inverse rendering for %s: %.2f%%', rendering.subj_id_string, progress));
                    end 
            end
            
            close(progressBar);
            disp(strcat('Inverse rendering for subject ', rendering.subj_id_string , ' completed'));
    
            Out_Mel = reshape(Out_Mel, R, C);
            Out_Hem = reshape(Out_Hem, R, C);
            Out_Epth = reshape(Out_Epth, R, C);
            Out_Beta = reshape(Out_Beta, R, C);
            Out_Img = reshape(Out_Img, R, C, 3);
    
            if rendering.debug
                disp('Displaying output rendered texture');
                figure;    imshow(uint8((Out_Img.^(1/2.2))*255)); title('Output Rendered texture');
                disp('Displaying melanin map');
                figure;    imagesc(Out_Mel); axis 'image'; title('Melanin map');
                disp('Displaying hemoglobin map');
                figure;    imagesc(Out_Hem); axis 'image'; title('Hemoglobin map');
                disp('Displaying epidermal thickness map');
                figure;    imagesc(Out_Epth); axis 'image'; title('Ep thickness map');
                disp('Displaying beta ratio mix map');
                figure;    imagesc(Out_Beta); axis 'image'; title('Beta ratio mix map');
            end
    
            save(strcat(rendering.pigPath, rendering.subj_id_string, rendering.fileName, '.mat'),"Out_Epth", "Out_Beta","Out_Hem","Out_Img","Out_Mel");
            disp('Maps saved');
            toc 

            
end

function sub = getBeta(rendering)
                %get the modal beta value from the permID
                %load the original maps

                load(strcat(rendering.pigPath, rendering.subj_id_string, rendering.fileName,'.mat'));

                % load the mask for the face
                %face_mask = imread(strcat(rendering.shaderPath, rendering.subj_id_string, '_E00_Mask.bmp'));
                %face_mask = face_mask(:,:,2)>0;
                
                face_mask = rendering.face_mask; 
                % get the mode of the beta values
                beta_mode = mode(Out_Beta(face_mask),'all');

                % compare to samples
                sub = find(beta_mode==rendering.Beta_sampling);

                % we encapulate this in a function to avoid having to overwrite the maps
end           