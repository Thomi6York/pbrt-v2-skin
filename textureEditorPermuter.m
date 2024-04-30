%% Edit this so that it now edits the pigment maps for the skin model

close all 
clear all

%%

format longG;

currentDir = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\";
%set colorimetry path
chromPath = "C:\Users\tw1700\Downloads\Code_chromophores_estimation\";
cd(chromPath);

%add path to data
addpath(genpath('.\data\'));

%% get reflection of third percentiles using LUT
load(".\data\LUTs_luxeon_CIEcmfwithbeta.mat");
load LUTs_Lab; % get the lab version to avoid computing on the fly

%set pigpath and make it if it doesn't exist
pigPath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\pigmentMaps\";
if ~exist(pigPath, 'dir')
    mkdir(pigPath);
end
addpath(pigPath);


%set texpath and make it if it doesn't exist
texPath = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\textures\normTex\";
if ~exist(texPath, 'dir')
    mkdir(texPath);
end
addpath(texPath);

% create a subdirectory for the permuted textures
permPath = strcat(texPath, 'permutations\');
if ~exist(permPath, 'dir')
    mkdir(permPath);
end
addpath(permPath);

subsampling_factor_img = 1; % subsampling factor for the image for debugging purposes

debug = 1; % Set debug to 1 to enable debug statements

% normalise the textures
%load the csv with ISO values
isoValues = readmatrix(strcat(currentDir,'CaptureISO_perSubject.csv'));


subjects = readmatrix(strcat(currentDir,'subjects.csv'));
subjects = subjects'; 


%load repeat options txt file
%load repeat options txt file
options = fileread(strcat(currentDir,'options.txt'));

repeat = all('True' == options(1:4));
fixBandK = all('True' == options(7:10)); 

fileNameHandleIn = 'ISONorm';

for subj = 5 %subjects
    subj_id_string = ['S' num2str(subj, '%03d')];

    load('.\data\inverse_rendering_data.mat')
    load('.\data\LED_spectrum_luxeon.mat');
    light_spectrum = light_spectrum(21:10:321,2);
    % check whether maps are precalculated
   
    % load the mask for the face
    path = strcat('C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\', subj_id_string, '\shader\');
    addpath(path);
    face_mask = imread(strcat(path, subj_id_string,'_E00_Mask.bmp')); 
    face_mask = face_mask(:,:,2)>0;
    


    %check for pig maps
    if ~exist(strcat(pigPath, subj_id_string, '_newMaps', fileNameHandleIn,'.mat'), 'file')  || repeat == 'y'
        
        disp(['No maps found for ' subj_id_string])

    else 

        disp('Loading pre-existing maps');

        load(strcat(pigPath, subj_id_string, '_newMaps.mat'));
        disp('Old Maps loaded');
        if debug
            Input_Img = imread([path '\diff_texture.bmp']); 
            disp('Input diff texture loaded ')
            figure;imshow(Input_Img);title('Original Diffuse texture')


            % display heat maps
            
        end
        
    end

    %% reload face mask
    face_mask = imread(strcat(path, subj_id_string, '_E00_Mask.bmp')); 
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

    save(strcat(pigPath, subj_id_string, 'perms.mat'), 'perms','std_IDs' ,'mel_std','hem_std'); %save perms for ref

    %loop through the permutations
    count = 0;
    for i = 4 %1:length(perms)
        count = count + 1;
        
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

        % create a new filename handle for permutation ID
        fileNameHandleOut = strcat('PermID', num2str(count), '_',fileNameHandleIn);

        %save the new maps
        save(strcat(pigPath, subj_id_string, fileNameHandleOut,'_.mat'),"Out_Epth", "Out_Beta","Out_Hem2","Out_Img2","Out_Mel2");

        %modulate the texture
        disp('Modulating texture via normalization with the 3rd percentile of the chromophores');
        
        

        %this handles saving the texture and cache file
        normTex= texNormalize(count, Out_Img2,Out_Beta,Out_Epth,Out_Mel2,Out_Hem2, fileNameHandleOut, subj_id_string, permPath, texPath, pigPath, Mel_sampling, Hem_sampling, Beta_sampling, Epth_sampling, LUTs, face_mask, debug);

        disp('Texture normalized and saved');

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

function [Out_Mel,Out_Hem,Out_Beta,Out_Epth,Out_Img] = inverse_render(subj, subj_id_string, path, pigPath, isoValues, LUTs, LUTs_Lab, light_spectrum, CMFs, Mel_sampling, Hem_sampling, Epth_sampling, Beta_sampling, subsampling_factor_img, face_mask, debug)

            %load image 
            Input_Img = imread([path '\diff_texture.bmp']); 
            Input_Img = (double(Input_Img(1:subsampling_factor_img:end,1:subsampling_factor_img:end,:))./255).^2.2; % subsample the image and convert to linear space
    
            %normalise ISOs
            ISO = isoValues(subj +1,2);
            ISO = table2array(ISO);
    
            Input_Img = (Input_Img.*100)/ISO;
          
            face_mask = face_mask(1:subsampling_factor_img:end,1:subsampling_factor_img:end); %subsample mask
    
            if debug
                disp('Displaying unedited input image');
                figure; imshow(lin2rgb(Input_Img)); title('unedited input im (iso normalised)');
            end
            %% standard image loading 
            LUTs_Dims = size(LUTs);
            
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
            Out_Img = zeros(length(vecIm),3); % output 3D equivalent of the rendered image
            Out_Beta = Out_Epth; 
    
            
            face_mask = reshape(face_mask,[],1);
    
            delta_lambda=10;
            Light_XYZ = Spec_To_XYZ(light_spectrum, CMFs, delta_lambda); % converting the light spactrum to its XYZ values
            Img_Lab = rgb2lab(vecIm,'WhitePoint', Light_XYZ, 'ColorSpace', 'linear-rgb');
    
            disp(strcat('Inverse rendering in progress... for subject: ' ,subj_id_string));
            progressBar = waitbar(0, strcat('Inverse rendering ', subj_id_string,  'in progress...'));
            maskIm = vecIm(face_mask,:);
            maskImLab = Img_Lab(face_mask,:);
            maskCorrespondence =  1:length(vecIm);
            maskCorrespondence = maskCorrespondence(face_mask); %tells us correspondence between mask and image
    
            LUT_vec = reshape(LUTs, [], 3); % convert 5D LUT to a vector
            LUTs_Lab_vec = reshape(LUTs_Lab, [], 3); % convert 5D LUT to a vector
    
            for i = 1 : length(maskIm)
                    Pix_Lab_tmp=[maskImLab(i, :)];
    
                        % Perform the entire search without a loop
                        %reshape pixels to 3D for lookup
                        distances = DeltaE_94_pix_to_Matrix1D(Pix_Lab_tmp, LUTs_Lab_vec); % distances between pixel in the image and current lookup table
                        [tmp_min, linear_index] = min(distances(:)); % find the minimum distance and its linear index
                        [beta_eum, Best_K, Best_M, Best_N] = ind2sub(size(LUTs), linear_index); % convert linear index to subscripts
    
                        Out_Img(maskCorrespondence(i),:) = LUT_vec(linear_index, :); % retrieve the corresponding value from the vectorized LUT
                        Out_Mel(maskCorrespondence(i)) = Mel_sampling(Best_M); % storing the best Mel_sampling into Output Mel
                        Out_Hem(maskCorrespondence(i)) = Hem_sampling(Best_N);
                        Out_Epth(maskCorrespondence(i)) = Epth_sampling(Best_K);
                        Out_Beta(maskCorrespondence(i)) =  Beta_sampling(beta_eum);
    
                    progress = i / length(vecIm) * 100;
                    waitbar(progress / 100, progressBar, sprintf('Inverse rendering for %s: %.2f%%', subj_id_string, progress));
            end
            
            close(progressBar);
            disp(strcat('Inverse rendering for subject ', subj_id_string , ' completed'));
    
            Out_Mel = reshape(Out_Mel, R, C);
            Out_Hem = reshape(Out_Hem, R, C);
            Out_Epth = reshape(Out_Epth, R, C);
            Out_Beta = reshape(Out_Beta, R, C);
            Out_Img = reshape(Out_Img, R, C, 3);
    
            if debug
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
    
            save(strcat(pigPath, subj_id_string, '_newMaps.mat'),"Out_Epth", "Out_Beta","Out_Hem","Out_Img","Out_Mel");
            disp('Maps saved');
end

function normIm= texNormalize(count, Out_Img, Out_Beta,Out_Epth,Out_Mel2,Out_Hem2, fileNameHandle, subj_id_string, permPath, texPath, pigPath, Mel_sampling, Hem_sampling, Beta_sampling, Epth_sampling, LUTs, face_mask, debug)

    % get 3rd percentile w/mask for homogenous skin layer settings
    faceMel = Out_Mel2(face_mask);

    melPerc = prctile(Out_Mel2(face_mask),3, 'all');

    disp(['3rd perc mel is: ' num2str(melPerc)])

    % get 3rd percentile w/mask for homogenous skin layer settings
    hemPerc = prctile(Out_Hem2(face_mask),3,'all');
    disp(['3rd perc hem is: ' num2str(hemPerc)])

    melInd = find(melPerc == Mel_sampling);
    hemInd = find(hemPerc == Hem_sampling);
    [~,betaInd] = min(abs(mean(Out_Beta,'all')-Beta_sampling)); %set this to the mean 
    [~,epthInd] = min(abs(mean(Out_Epth,'all')-Epth_sampling)); %set this to the mean

    % fix values if we want this to be fixed
    if fixBandK = 1
        betaInd(:,:) = 3;
        if epthInd < 8
            epthInd(:,:) = 8;
        elseif epthInd > 18
            epthInd(:,:) = 18;
        end

    end

    refl = LUTs(betaInd,epthInd,melInd,hemInd,:); 
    refl = reshape(refl,1,3);

    vecIm = reshape(Out_Img,[],3);

    normIm = vecIm./refl;
    normIm = reshape(normIm, size(Out_Img));

    if debug
        disp('Displaying normalized texture');
        figure; imshow(normIm);title('Normalized texture');
    end
    
    % Flip the image vertically due to matlabs coordinate system
    normIm = flipud(normIm);

    if debug
        figure; imshow(normIm);title('transformed for rendering');
    end
    
    exrwrite(normIm,strcat(permPath, fileNameHandle, subj_id_string, '.exr')); %write to the rendering directory 
    
    % Write cache file
    cacheFile = fullfile(permPath, ['cache_' fileNameHandle subj_id_string  '.txt']);
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

end 