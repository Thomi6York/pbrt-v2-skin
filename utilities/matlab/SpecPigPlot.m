%% SpecPlotterPig
% This is to plot pigments against specular textures to investigate a
% potential relationship for scaling

close all
clear all

%% load images
imagePath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\experiments\reRunWNormsandCorrectSpec\pigmentMaps\", "S000", "normTexISONorm.mat");
load(imagePath);
dims = size(Out_Img);

subjs = [0:22];

allArr = zeros(length(subjs),dims(1),dims(2),4);

sampl = 100;
interval = ((959-422)/sampl);
interval = round(interval); 

lineSamp = 422:interval:959; 
y = 418;

figure;imshow(Out_Img); hold on; plot(lineSamp,y,'-x')

debug = 1;
%% 
meanArray = zeros(length(subjs),length(lineSamp));
count = 1;
masks = zeros(dims(1),dims(2),length(subjs));
isoValues = readtable("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\\csv\\CaptureISO_perSubject.csv");

%% apply accross all
count =1;
meanSpecs = zeros(length(subjs),4); % per channel
meanArray = zeros(length(subjs),4);

for subj = subjs
    

    subj_id_string = ['S' num2str(subj, '%03d')];
    dataSetPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\PilotDataSet\", subj_id_string,  "\shader\");
    imagePath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\PilotDataSet\",  subj_id_string, "\shader\diff_texture.bmp"); %load from pigment maps bc image is normalised
    specPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\PilotDataSet\", subj_id_string ,"\shader\spec_textureISONormFlipped.exr");
    normalPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\PilotDataSet\", subj_id_string ,"\shader\spec_normalFlipped.exr");
    pigmentMaps = strcat('C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\matlab\PigmentMapsFull\',subj_id_string,'newMaps.mat'); 
    face_mask = imread(strcat(dataSetPath, subj_id_string, '_E00_Mask.bmp')); 
    face_mask = face_mask(:,:,2)>0;
    
    
    Out_Img = imread(imagePath);
    Out_Img = rgb2lin(Out_Img);
    Out_Img = double(Out_Img)./255;
    Out_Img = iso_norm(Out_Img,subj,isoValues); 


   load(pigmentMaps);

if debug
    figure; imshow(lin2rgb(Out_Img));
    figure; subplot(221);
    imagesc(Out_Hem);
    title(sprintf('hem map for %d', subj));
    subplot(222); imagesc(Out_Mel); title(sprintf('mel map for %d', subj));
    subplot(223); imagesc(Out_Epth); title(sprintf('Ep map for %d', subj));
    subplot(224); imagesc(Out_Beta); title(sprintf('Beta map for %d', subj));
end
    %spec text
    spec = exrread(specPath);
    spec = flipud(spec); % flip due to saving

      %normal
    SpecNormal = exrread(normalPath);
    SpecNormal = flipud(SpecNormal);

           % apply base mask 
    for i = 1:3
        tmp = spec(:,:,i);
        tmp(~face_mask) = NaN;  
        spec(:,:,i) = tmp; 
    end

    viewDir = [0,0,1]; % z axis
    dotNormSpec = SpecNormal(:,:,1)*viewDir(1)+SpecNormal(:,:,2)*viewDir(2)+SpecNormal(:,:,3)*viewDir(3);
    SpecDeg = acosd(dotNormSpec); 

    mask = (45>SpecDeg); 
    mask = reshape(mask,size(SpecDeg)); 

        figure;
    for i = 1:3
        temp = spec(:,:,i);
        temp = reshape(temp,size(SpecNormal,1,2));
        temp(SpecDeg>=45) = 0; 
        subplot(1,3,i);imshow(temp); title('attempt to remove fresenel') %check this removes the frensnel
        spec(:,:,i) = temp; 
    end

    maskSpec = spec; 
    maskSpec(repmat(~mask, [1, 1, 3])) = NaN;

    for i=1:3
        meanSpec = mean(maskSpec(:,:,i), 'all','omitnan'); 
        meanSpecs(count,i) = meanSpec;
    end 

    %% apply mask to pigments 

    Mask_Hem = maskIm(mask,Out_Hem);
    Mask_Mel = maskIm(mask,Out_Mel);
    Mask_Ep = maskIm(mask,Out_Epth);
    Mask_Beta = maskIm(mask,Out_Beta);

    %% check one
    %figure; imagesc(Mask_Hem); 
    maskImamge = spec; 
    %% Apply the mask to the image
    maskImage(repmat(~mask, [1, 1, 3])) = NaN;
    
    % Create a mask for NaN values
    nanMask = isnan(maskImage);

    % plot if you want
%     figure;imagesc(nanMask)
    
 %% now do means for pigmaps
    meanH = mean(Mask_Hem,'all','omitnan');
    meanM = mean(Mask_Mel,'all','omitnan');
    meanE = mean(Mask_Ep,'all','omitnan');
    meanB = mean(Mask_Beta,'all','omitnan');

     % add means to array
    meanArray(count,1) = meanH;
    meanArray(count,2) = meanM;
    meanArray(count,3) = meanE;
    meanArray(count,4) = meanB; % mean of all channels
    % count    
    count = count+1; 
end 


%% plot the aggregate means
% labels
subj_IDs = cell(length(0:22),1); 

for i = 0:22

    subj_id_string = ['S' num2str(i, '%03d')]; 
    subj_IDs{i+1,1} = subj_id_string; 

end 
means = mean(meanSpecs,2);
figure; sgtitle('Mean Channel Specular Per Subj');
subplot(221);scatter(meanArray(:,1),means);title('H vs Specular'); xlabel('Hem'); ylabel('specular');
% Annotate each data point with a string
for i = 1:length(subj_IDs)
    text(meanArray(i,1), means(i), subj_IDs{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end
subplot(222);scatter(meanArray(:,2),means);title('M vs Specular');xlabel('Mel'); ylabel('specular');
for i = 1:length(subj_IDs)
    text(meanArray(i,2), means(i), subj_IDs{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end
subplot(223);scatter(meanArray(:,3),means);title('E vs Specular');xlabel('Ep Thick'); ylabel('specular');
for i = 1:length(subj_IDs)
    text(meanArray(i,3), means(i), subj_IDs{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end
subplot(224);scatter(meanArray(:,4),means);title('Beta vs Specular');xlabel('Beta'); ylabel('specular');
for i = 1:length(subj_IDs)
    text(meanArray(i,4), means(i), subj_IDs{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end

%% line plot pigments against each other
figure; scatter(meanArray(:,1),meanArray(:,2)); title('Hem vs Mel'); xlabel('hem');ylabel('mel')

%% run a distance corr to try and plot -- the hem and mel graphs look the best choice
x = meanArray(:,1);
x = x(:);
y = means;
dcor2 = distcorr(x,y); 

x = meanArray(:,2);
x=x(:);
y = means;
dcor1 = distcorr(x,y); 

% Number of permutations
numPermutations = 1000;

% Calculate original distance correlations
x1 = meanArray(:,1);
y = means;
originalDcor1 = distcorr(x1, y);

x2 = meanArray(:,2);
originalDcor2 = distcorr(x2, y);

% Initialize arrays to store permuted correlations
permutedDcor1 = zeros(numPermutations, 1);
permutedDcor2 = zeros(numPermutations, 1);

% Perform permutation test
for i = 1:numPermutations
    permutedY = y(randperm(length(y)));
    permutedDcor1(i) = distcorr(x1, permutedY);
    permutedDcor2(i) = distcorr(x2, permutedY);
end 

% Calculate p-values
pValue1 = mean(permutedDcor1 >= originalDcor1);
pValue2 = mean(permutedDcor2 >= originalDcor2);

% Display results
fprintf('Original Distance Correlation (Hem vs Specular): %.4f\n', originalDcor1);
fprintf('p-value: %.4f\n', pValue1);
fprintf('Original Distance Correlation (Mel vs Specular): %.4f\n', originalDcor2);
fprintf('p-value: %.4f\n', pValue2);

% Plot histograms of permuted correlations
figure;
subplot(1, 2, 1);
histogram(permutedDcor1, 'Normalization', 'probability');
hold on;
xline(originalDcor1, 'r', 'LineWidth', 2);
text(originalDcor1, 0.9, sprintf('p-value: %.4f', pValue1), 'Color', 'r');
title('Permutation Test for Hem vs Specular');
xlabel('Distance Correlation');
ylabel('Probability');
legend('Permuted', 'Original');

subplot(1, 2, 2);
histogram(permutedDcor2, 'Normalization', 'probability');
hold on;
xline(originalDcor2, 'r', 'LineWidth', 2);
text(originalDcor2, 0.9, sprintf('p-value: %.4f', pValue2), 'Color', 'r');
title('Permutation Test for Mel vs Specular');
xlabel('Distance Correlation');
ylabel('Probability');
legend('Permuted', 'Original');

%% 

%%

function out_im = iso_norm(in_im,subj,isoValues)

    % ISO normalise
    ISO = isoValues(subj +1,2);
    ISO = table2array(ISO);
    ISOref = 250; %min ISO from table

    %Input_Img_spec = imread([rendering.shaderPath '\spec_texture.bmp']);

    %normalise 
    out_im = (in_im.*ISOref)/ISO;

end
function out =maskIm(mask,image)
    
    out = nan(size(image));
    n = ndims(out);
    dims = size(out);
    if n ==3
        for i = 1:dims(3)
            tmp = image(:,:,i);
            tmp2 = zeros(size(tmp));

            tmp2(mask) = tmp(mask);
            out(:,:,i) = tmp2;
        end
    elseif n==2
        tmp = image; 
        out(mask) = tmp(mask);
    end 

end