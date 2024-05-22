%% Edit this so that it now edits the pigment maps for the skin model

close all 
clear all

%% basic path

format longG;

currentDir = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\";
%set colorimetry path
chromPath = "C:\Users\tw1700\Downloads\Code_chromophores_estimation\";
cd(chromPath);

%add path to data
addpath(genpath('.\data\'));

%% debug options 
subsampling_factor_img = 1; % subsampling factor for the image for debugging purposes

debug = 0; % Set debug to 1 to enable debug statements

% normalise the textures
%load the csv with ISO values
isoValues = readmatrix(strcat(currentDir,'utilities\\csv\\CaptureISO_perSubject.csv'));


subjects = readmatrix(strcat(currentDir,'utilities\\csv\\subjects.csv'));
subjects = subjects'; 



%% Load chrom path stuff
load(".\data\LUTs_luxeon_CIEcmfwithbeta.mat");
load LUTs_Lab; % get the lab version to avoid computing on the fly

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

%% load path info 
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

permPathPig = strcat(pigPath, 'permutedTextures\');
permPathCache = strcat(cachePath, 'permutedTextures\');
permPathTex = strcat(TexPath, 'permutedTextures\');

% save perm paths to a .csv file
permPaths = {permPathPig, permPathCache, permPathTex};
permPaths = cell2table(permPaths);
writetable(permPaths, strcat(currentDir, 'permPaths.csv'));

% create the perms paths if they don't exist
if ~exist(permPathPig, 'dir')
    mkdir(permPathPig);
end

if ~exist(permPathCache, 'dir')
    mkdir(permPathCache);
end

if ~exist(permPathTex, 'dir')
    mkdir(permPathTex);
end



addpath(renderingPath);
addpath(scenePath);
addpath(dataSetPath);
addpath(meshPath);
addpath(pigPath);


%% load repeat options txt file
options = fileread(strcat(currentDir,'utilities\\text\\options.txt'));

repeat = options(1) =='1';
fixBandK = options(2)=='1'; 

fileNameHandleIn = fileHandle;
%fileNameHandleIn =''; % jsut to get rid of it for now

%% append all inputs into a struct
rendering = struct('subsampling_factor_img',subsampling_factor_img,'debug',debug, ... 
            'isoValues',isoValues,'subjects',subjects,'repeat',repeat,'fixBandK',fixBandK,... 
            'fileNameHandleIn',fileNameHandleIn, 'pathHandle',pathHandle, ...
            'permPathPig',permPathPig, 'permPathCache',permPathCache, 'permPathTex',permPathTex, 'pigPath',pigPath);

load('.\\utilities\\matlab\\inverse_rendering_data.mat')
rendering.Mel_sampling = Mel_sampling;
rendering.Hem_sampling = Hem_sampling;
rendering.Beta_sampling = Beta_sampling;
rendering.Epth_sampling = Epth_sampling;

rendering.LUTs = LUTs;
%% subj loop 
for subj = subjects %subjects
    %% load subj data
    rendering.subj_id_string = ['S' num2str(subj, '%03d')];

    % check whether maps are precalculated
   
    % load the mask for the face
    path = strcat('C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\', rendering.subj_id_string, '\shader\');
    addpath(path);
    face_mask = imread(strcat(path, rendering.subj_id_string,'_E00_Mask.bmp')); 
    rendering.face_mask = face_mask(:,:,2)>0;
    


    %% check for pig maps
    if ~exist(strcat(rendering.pigPath, rendering.subj_id_string, fileName,'.mat'), 'file')  || repeat == 'y'
        
        disp(['No maps found for ' rendering.subj_id_string])
        break

    else 

        disp('Loading pre-existing maps');

        load(strcat(rendering.pigPath, rendering.subj_id_string, fileName,'.mat'));
        disp('Old Maps loaded');
        if debug
            Input_Img = imread([path '\diff_texture.bmp']); 
            disp('Input diff texture loaded ')
            figure;imshow(Input_Img);title('Original Diffuse texture')

            % display heat maps
            
        end
        
    end

    %% calculate permutations for subj
    face_mask = imread(strcat(path, rendering.subj_id_string, '_E00_Mask.bmp')); 
    face_mask = face_mask(:,:,2)>0;
    face_mask = face_mask(1:subsampling_factor_img:end,1:subsampling_factor_img:end); %subsample mask
    face_mask1D = reshape(face_mask,[],1); 

    
    if debug
        disp('Displaying input texture, linear');
        figure; imshow(lin2rgb(Out_Img)); title('Inverse texture, linear');

        %display pigment heatmaps
        disp('Displaying melanin map');
        figure; imagesc(Out_Mel); axis 'image'; title('Melanin map');
        disp('Displaying hemoglobin map');
        figure; imagesc(Out_Hem); axis 'image'; title('Hemoglobin map');
        disp('Displaying epidermal thickness map');
        figure; imagesc(Out_Epth); axis 'image'; title('Epidermal thickness map');
        disp('Displaying beta ratio mix map');
        figure; imagesc(Out_Beta); axis 'image'; title('Beta ratio mix map');
    end

    mel_std = std(Out_Mel(face_mask), 'omitnan');
    hem_std = std(Out_Hem(face_mask), 'includenan');
    
    % we want to permute conditions - add and subtract 1 std deviation from the pigment maps
    values = [0,mel_std, - mel_std;0, hem_std, - hem_std;];
    std_ID = [0,1,-1;0,1,-1;];
    %1st col is mel values, 2nd col is hem 
    
    perms = double(zeros(size(values,1)*size(values,2),2));
    std_IDs = double(zeros(size(values,1)*size(values,2),2));
    
    count = 0;
    % permute all values
    for i = 1:size(values,2)
        for j = 1:size(values,2)
            %don't add a perm if its just the GT 
            if values(1,i) == 0 && values(2,j) == 0
                continue
            else
                count = count + 1;
                perms(count,1) = values(1,i);
                perms(count,2) = values(2,j);

                %store the std ID
                std_IDs(count,1) = std_ID(1,i);
                std_IDs(count,2) = std_ID(2,j);
            end 
        end
    end

    %remove non-uniquye combs
    perms = unique(perms, 'rows');

    save(strcat(rendering.permPathPig, rendering.subj_id_string, 'perms.mat'), 'perms','std_IDs' ,'mel_std','hem_std'); %save perms for ref

    %% loop through the permutations
    count = 0;
    for i =  1:length(perms)
        count = count + 1;
        rendering.count =count;
        
        dims = size(Out_Hem);
        Out_Mel2 = Out_Mel;
        Out_Hem2 = Out_Hem;

        Out_Mel2(face_mask) = Out_Mel(face_mask) + perms(i,1);
        Out_Hem2(face_mask) = Out_Hem(face_mask) + perms(i,2);
        %ignore beta and epth because we aren't changing them

        if debug
            disp(strcat('showing edited pigment maps for perm: ', num2str(count)))
            figure; subplot(121); imagesc(Out_Mel2); title('melanin map'); subplot(122); imagesc(Out_Hem2);title('hem map ')
        end

         %reshape to vectors
        Out_Mel2 = reshape(Out_Mel2,[],1)';
        Out_Hem2 = reshape(Out_Hem2,[],1)';
        Out_Epth = reshape(Out_Epth,[],1);
        Out_Beta = reshape(Out_Beta,[],1);

        %get the index of the nearest value in the sampling array
        [~,melInd] = min(abs(Out_Mel2 - Mel_sampling));
        [~,hemInd] = min(abs(Out_Hem2 - Hem_sampling));
        [~,betaInd] = min(abs(Out_Beta-Beta_sampling),[],2); %should be the same if we've reclamped the previous values 
        [~,epthInd] = min(abs(Out_Epth-Epth_sampling),[],2);

        % calibrate the maps to the sampling values 
        Out_Mel2(face_mask1D) = Mel_sampling(melInd(face_mask1D));
        Out_Hem2(face_mask1D) = Hem_sampling(hemInd(face_mask1D));
        %out epth and beta are the same 

       LUTSDims = size(LUTs);
    
        LUTs1D= reshape(LUTs, [], 3); 
        
        melInd = melInd' ;
        hemInd = hemInd';

        % Convert indices to linear indices
        linInds = sub2ind([LUTSDims(1), LUTSDims(2), LUTSDims(3), LUTSDims(4)], betaInd(face_mask1D), epthInd(face_mask1D), melInd(face_mask1D), hemInd(face_mask1D));

        % Extract images using linear indices
        extracted_images = zeros(length(Out_Mel2),3);
        extracted_images(face_mask1D,:) = LUTs1D(linInds, :);

        Out_Img2 = reshape(extracted_images,dims(1),dims(2),3);
        if debug
            figure;
            subplot(121); 
            imshow(lin2rgb(Out_Img)); 
            title('Input Texture'); 
            subplot(122); 
            imshow(lin2rgb(Out_Img2)); 
            title(strcat('Permuted Texture with values mel:', num2str(perms(i,1)), ' and hem ', num2str(perms(i,2)))); 
        end
        %% save outputs 
        % create a new filename handle for permutation ID
        rendering.fileNameHandleOut = strcat('PermID', num2str(count), '_',fileName);

        %save the new maps
        save(strcat(permPathPig, rendering.subj_id_string, rendering.fileNameHandleOut,'_.mat'),"Out_Epth", "Out_Beta","Out_Hem2","Out_Img2","Out_Mel2");

        %modulate the texture
        disp('Modulating texture via normalization with the 3rd percentile of the chromophores');
        
        
        % add new pigment maps to the rendering struct
        rendering.Out_Mel2 = Out_Mel2;
        rendering.Out_Hem2 = Out_Hem2;
        rendering.Out_Epth = Out_Epth;
        rendering.Out_Beta = Out_Beta;
        rendering.Out_Img = Out_Img2;

        %this handles saving the texture and cache file
        normTex= texNormalize(rendering);

        disp(['Texture normalized and saved to ' permPathTex]);

    end 
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

function normIm= texNormalize(rendering)
%%
    % get 3rd percentile w/mask for homogenous skin layer settings
    faceMel = rendering.Out_Mel2(rendering.face_mask);

    melPerc = prctile(rendering.Out_Mel2(rendering.face_mask),3, 'all');

    disp(['3rd perc mel is: ' num2str(melPerc)])

    % get 3rd percentile w/mask for homogenous skin layer settings
    hemPerc = prctile(rendering.Out_Hem2(rendering.face_mask),3,'all');
    disp(['3rd perc hem is: ' num2str(hemPerc)])

    melInd = find(melPerc == rendering.Mel_sampling);
    hemInd = find(hemPerc == rendering.Hem_sampling);
    [~,betaInd] = min(abs(mean(rendering.Out_Beta,'all')-rendering.Beta_sampling)); %set this to the mean 
    [~,epthInd] = min(abs(mean(rendering.Out_Epth,'all')-rendering.Epth_sampling)); %set this to the mean

    refl = rendering.LUTs(betaInd,epthInd,melInd,hemInd,:); 
    refl = reshape(refl,1,3);

    vecIm = reshape(rendering.Out_Img,[],3);

    normIm = vecIm./refl;
    normIm = reshape(normIm, size(rendering.Out_Img));

    if rendering.debug
        disp('Displaying normalized texture');
        figure; imshow(normIm);title('Normalized texture');
    end
    
    % Flip the image vertically due to matlabs coordinate system
    normIm = flipud(normIm);

    if rendering.debug
        figure; imshow(normIm);title('transformed for rendering');
    end
    
    exrwrite(normIm,strcat(rendering.permPathTex, rendering.subj_id_string, rendering.fileNameHandleOut,  '.exr')); %write to the rendering directory 
    
    % Write cache file
    cacheFile = fullfile(rendering.permPathCache, ['cache_' rendering.subj_id_string rendering.fileNameHandleOut   '.txt']);
    fid = fopen(cacheFile, 'w');
    fprintf(fid, 'Subject: %s\n', rendering.subj_id_string);
    fprintf(fid, 'Melanin 3rd percentile: %f\n', melPerc);
    fprintf(fid, 'Hemoglobin 3rd percentile: %f\n', hemPerc);
    fprintf(fid, 'melInd: %d\n', melInd);
    fprintf(fid, 'hemInd: %d\n', hemInd);
    fprintf(fid, 'betaInd: %d\n', betaInd);
    fprintf(fid, 'mean beta val: %d \n', rendering.Beta_sampling(betaInd));
    fprintf(fid, 'epthInd: %d\n', epthInd);
    fprintf(fid, 'mean epth val: %d \n', rendering.Epth_sampling(epthInd));
    fprintf(fid, 'permID: %d \n', rendering.count);
    fclose(fid);
    disp(['Wrote cache file to ' cacheFile]);

end 