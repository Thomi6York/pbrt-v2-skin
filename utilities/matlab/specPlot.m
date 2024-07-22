%% spec mapping
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
 

%% draw a line along subj000's head 

lineSamp = 422:interval:959; 
y = 418;

figure;imshow(Out_Img); hold on; plot(lineSamp,y,'-x')

debug = 0;
%% 
meanArray = zeros(length(subjs),length(lineSamp));
count = 1;
masks = zeros(dims(1),dims(2),length(subjs));
isoValues = readtable("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\\csv\\CaptureISO_perSubject.csv");
 
for subj = subjs
    

    subj_id_string = ['S' num2str(subj, '%03d')];
    dataSetPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\", subj_id_string,  "\shader\");
    imagePath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\",  subj_id_string, "\shader\diff_texture.bmp"); %load from pigment maps bc image is normalised
    specPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\", subj_id_string ,"\shader\spec_textureISONormFlipped.exr");
    normalPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\", subj_id_string ,"\shader\spec_normalFlipped.exr");
    face_mask = imread(strcat(dataSetPath, subj_id_string, '_E00_Mask.bmp')); 
    face_mask = face_mask(:,:,2)>0;

    % apply base mask 
    
    Out_Img = imread(imagePath);

    if debug ==1 
        figure; subplot(121); imshow(Out_Img); title('premask, pre-ISO')
    end 

    Out_Img = rgb2lin(Out_Img);
    Out_Img = double(Out_Img)./255;
    
    % ISO normalise
    Out_Img = iso_norm(Out_Img,subj,isoValues); 

    for i = 1:3
        tmp = Out_Img(:,:,i);
        tmp(~face_mask) = NaN;  
        Out_Img(:,:,i) = tmp; 
    end
    
    if debug 
        subplot(122); imshow(Out_Img); title('postmask')
    end
    diffRN = strcat(dataSetPath, "diff_normal_r.bmp");
    diffBN = strcat(dataSetPath, 'diff_normal_b.bmp');
    diffGN = strcat(dataSetPath, 'diff_normal_g.bmp');

    % here we have all the diffuse normals -- load them in 
    RNI = imread(diffRN);
    GNI = imread(diffGN);
    BNI = imread(diffBN);
    
    %
    if subj == 0
        figure;imshow(RNI);title('R normals');
        hold on; plot(lineSamp,y,'-xR')
    end

    % convert to linear -- nope bc of assumption
    RNI = rgb2lin(RNI);
    GNI = rgb2lin(GNI);
    BNI = rgb2lin(BNI);

    % convert to double
    RNI = double(RNI)./255;
    GNI = double(GNI)./255;
    BNI = double(BNI)./255;
    
%     RNI = iso_norm(RNI,subj,isoValues);
%     GNI = iso_norm(GNI,subj,isoValues);
%     BNI = iso_norm(BNI,subj,isoValues);
    
    % Normalize each channel
    lengthsDiffuse = sqrt(RNI.^2 + GNI.^2 + BNI.^2);
    RNI = RNI ./ lengthsDiffuse;
    GNI = GNI ./ lengthsDiffuse;
    BNI = BNI ./ lengthsDiffuse; 
    
    %normal
    SpecNormal = exrread(normalPath);
    SpecNormal = flipud(SpecNormal);
%     SpecNormal = iso_norm(SpecNormal,subj,isoValues);
    %SpecNormal = rgb2lin(SpecNormal); 

    % Convert to normals
%     normals = SpecNormal * 2.0 - 1.0;
% 
%     % Normalize the normal vectors
%     lengths = sqrt(sum(normals.^2, 3));
%     normals(:, :, 1) = normals(:, :, 1) ./ lengths;
%     normals(:, :, 2) = normals(:, :, 2) ./ lengths;
%     normals(:, :, 3) = normals(:, :, 3) ./ lengths;
%     SpecNormal = normals; 

    %spec text
    spec = exrread(specPath);
    spec = flipud(spec); % flip due to saving
    
       % apply base mask 
    for i = 1:3
        tmp = spec(:,:,i);
        tmp(~face_mask) = NaN;  
        spec(:,:,i) = tmp; 
    end

    %check
%     if subj == 0 
%         originalspecpath = strcat(dataSetPath,'spec_normal.bmp');
%         uneditedSpec = imread(originalspecpath);
%         figure; subplot(121);imshow(rgb2lin(uneditedSpec)); title('original, unprocessed')
%         subplot(122);imshow(SpecNormal);  title('post-processing'); 
%         uneditedSpec = rgb2lin(rgb2lin(uneditedSpec));
%         uneditedSpec = double(uneditedSpec)./255; 
%         uneditedSpec = flipud(flipud(uneditedSpec));
%          %just apply same preprocessing to check 
%         %SpecNormal = uneditedSpec;
%     
%         for i = 1:3
%             diff= SpecNormal(:,:,i) - uneditedSpec(:,:,i);
%              figure; imagesc(abs(diff)); title('abs difference');
%         end
%     end 

    % eliminate pixels greater than 45 degrees to the viewing angle to
    % remove fresnel

    viewDir = [0,0,1]; % z axis
    dotNormSpec = SpecNormal(:,:,1)*viewDir(1)+SpecNormal(:,:,2)*viewDir(2)+SpecNormal(:,:,3)*viewDir(3);
    SpecDeg = acosd(dotNormSpec); 

    
    figure;
    for i = 1:3
        temp = spec(:,:,i);
        temp = reshape(temp,size(SpecNormal,1,2));
        temp(SpecDeg>=45) = 0; 
        subplot(1,3,i);imshow(temp); title('attempt to remove fresenel') %check this removes the frensnel
        spec(:,:,i) = temp; 
    end

    mask = (45>SpecDeg); 
    maskLine = mask(y,lineSamp);
    mask = reshape(mask,size(SpecDeg)); 
    if subj == 0
        figure;imshow(mask); title('mask')
    end 
    masks(:,:,count) =mask; 

    %spec

    %inverse rendered map
    %load(imagePath);
    im = Out_Img; 

    %% correct diffuse textures accounting for nomals by dividing by the cosine 
    % load in normals 

%    coNorm = cos(normal);

    viewDir = [0,0,1]; % assume z axis viewing 
    dotNormR = RNI(:,:,1)*viewDir(1)+RNI(:,:,2)*viewDir(2)+RNI(:,:,3)*viewDir(3);
    dotNormG = GNI(:,:,1)*viewDir(1)+GNI(:,:,2)*viewDir(2)+GNI(:,:,3)*viewDir(3);
    dotNormB = BNI(:,:,1)*viewDir(1)+BNI(:,:,2)*viewDir(2)+BNI(:,:,3)*viewDir(3);


    rDiff = im(:,:,1);%./dotNormR; %dotNormR is a cosine here
    rDiff(~face_mask) = NaN; % apply mask    
    if subj == 0
        figure; imshow(rDiff); title('Diffuse albedo accounting for viewing angle via dot product')
    end

    
    gDiff = im(:,:,2);%./dotNormG;
    gDiff(~face_mask) = NaN; % apply mask
    bDiff = im(:,:,3);%./dotNormB; 
    bDiff(~face_mask) = NaN; % apply mask
    

    % add to a bigger array
    allArr(count,:,:,1) = rDiff;
    allArr(count,:,:,2) = gDiff;
    allArr(count,:,:,3) = bDiff; 
    allArr(count,:,:,4) = mean(spec,3); 


    % apply original mask to the diffuse image

    %figure; imshow(reshape(allArr(count,:,:,1),dims(1),dims(2))); 

   count = count+1;
    %adjSpec = spec./coNorm; %-- should just be fine to use the map
    %adjDiff = im./coNorm; 
end 
%view them

%don't adjust spec for normals
%figure;subplot(121);imshow(spec);title("spec text iso norm"); subplot(122);imshow(adjSpec);title('Adjused Spec for normals')
%figure;imshow(rDiff);title("R Diff adjusting for cos")
%figure;imshow(normal);title("normal");

% hists for heads

figure;
subplot(121);histogram(im(:));title("map vals");
subplot(122);histogram(spec(:));title("vals")

%% plot a scanline along the head
% i chose a line between 422,y and 959,y -- lets do 10 samps

meanDiff = zeros(length(subjs),length(lineSamp));
meanSpec = mean(allArr(:,:,:,4),1); %mean of all specular maps 

% remember that the image x and ys and inverse to matlabs row,col 2d
% structure for arrays 

for i = 1:length(subjs)
 
    RDiffLine = allArr(i,y,lineSamp,1);
%     tmp = reshape(allArr(1,:,:,1),size(rDiff));
%     figure; imshow(tmp);
    %check we can unpack this
    checkR = rDiff(y,lineSamp);
    %checkR = checkR == RDiffLine'; 
    GDiffLine = allArr(i,y,lineSamp,2);
    BDiffLine = allArr(i,y,lineSamp,3);
    meanDiff(i,:) = mean(allArr(i,y,lineSamp,1:3),4);
    %meanArray(i,:) = meanDiff;  
    
    if debug
        figure; hold on; subplot(141);plot(lineSamp,RDiffLine(:),'-xr');title("R Diffuse"); ylim([0, 0.6]);
        subplot(142);plot((lineSamp),GDiffLine(:),'-xg');title("G Diffuse"); ylim([0, 0.6]);
        subplot(143);plot((lineSamp),BDiffLine(:),'-xb');title("B Diffuse"); ylim([0, 0.6]);
        subplot(144); plot((lineSamp),meanDiff(i,:));title("Mean Diffuse"); ylim([0, 0.6]);
        sgtitle(strcat('Plots for subj ' ,num2str(subjs(i))));
        hold off
    end 

end 

lineSpec =  meanSpec(1,y,lineSamp);
lineSpec = lineSpec(:);
lineSpec = lineSpec(maskLine);
lineSpec= lineSpec(lineSpec>0); % eliminate fresnel pixels
lineSpec = lineSpec(:); 

allMeanDiff = mean(meanDiff,1);
%figure; scatter(allMeanDiff,lineSpec); xlabel('Diffuse');ylabel('Specular')
title('Specular vs diffuse')


%lineDiff =adjDiff(lineSamp,y,1);
% line diff actually needs to be the mean of the three diffuse channels


%lineSpec = spec(lineSamp,y,1); 
%lineAdjSpec = adjSpec(lineSamp,y,1);

%% means for all

meanR = mean(allArr(i,y,lineSamp,1),1);
meanR = meanR(:);
meanG = mean(allArr(i,y,lineSamp,2),1);
meanG = meanG(:);
meanB = mean(allArr(i,y,lineSamp,3),1);
meanB = meanB(:);


if debug 
    figure; hold on; subplot(141);plot((lineSamp),meanR,'r');title("R Diffuse"); ylim([0, 0.6]);
        subplot(142);plot((lineSamp),meanG,'g');title("G Diffuse") ;ylim([0, 0.6]);
        subplot(143);plot((lineSamp),meanB,'b');title("B Diffuse");ylim([0, 0.6]);
        subplot(144); plot((lineSamp),allMeanDiff);title("Mean Diffuse");  ylim([0, 0.6]);
        sgtitle('Mean Accross subjects');
end  
%% do means accross subjects 

% Convert the image to double precision for manipulation
im = im2double(im);

maskIm = im; 
% Apply the mask to the image
maskIm(repmat(~mask, [1, 1, 3])) = NaN;

% Create a mask for NaN values
nanMask = isnan(maskIm);

% Display the masked image with mask in the image
figure;
subplot(121);
h = imshow(maskIm); 
title('Masked');

% Set the AlphaData property to make NaN values transparent
alphaData = ~any(nanMask, 3);
set(h, 'AlphaData', alphaData);


% Display the masked image without mask in the image
subplot(122);
imshow(maskIm);  
title('Unmasked');

%% apply accross all
count =1;
meanSpecs = zeros(length(subjs),4); % per channel
meanArray = zeros(length(subjs),4);

for subj = subjs
    
    specPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\", subj_id_string ,"\shader\spec_textureISONormFlipped.exr");
    spec = exrread(specPath);
    spec = flipud(spec); % flip due to saving

    mask = masks(:,:,count);
    mask = reshape(mask,dims(1),dims(2));
    if debug
        figure; imagesc(mask);title('mask');
    end
    maskSpec = spec; 
    maskSpec(repmat(~mask, [1, 1, 3])) = NaN;
    % apply the mask to the diffuse image
    maskR = allArr(count,:,:,1); %get the r channel
    
    maskG = allArr(count,:,:,2);
    maskB = allArr(count,:,:,3);
    %reshape
    maskR = reshape(maskR,dims(1),dims(2));
    maskG = reshape(maskG,dims(1),dims(2));
    maskB = reshape(maskB,dims(1),dims(2));
    if debug
        figure; imshow(reshape(allArr(count,:,:,1),dims(1),dims(2))); 
        figure; imagesc(maskR); title('premasked image');
    end 
    % apply the mask
    maskR(repmat(~mask, [1, 1, 1])) = NaN;
    if debug
    figure; imagesc(maskR); title('Masked channel')
    end 
    maskG(repmat(~mask, [1, 1, 1])) = NaN;
    maskB(repmat(~mask, [1, 1, 1])) = NaN;
    
    for i=1:3
        meanSpec = mean(maskSpec(:,:,i), 'all','omitnan'); 
        meanSpecs(count,i) = meanSpec;
    end 
    meanSpecs(count,4) = mean(meanSpecs(count,1:3));
    % allArr key - subjs,y,x,channel
    

    % remove infs
    tmp = allArr(count,:,:,:);
    tmp (tmp == inf) = NaN; 
    allArr(count,:,:,:) =tmp; 

    % now do means 
    meanR = mean(allArr(count,:,:,1),'all','omitnan');
    meanG = mean(allArr(count,:,:,2),'all','omitnan');
    meanB = mean(allArr(count,:,:,3),'all','omitnan');

    % add means to array
    meanArray(count,1) = meanR;
    meanArray(count,2) = meanG;
    meanArray(count,3) = meanB;
    meanArray(count,4) = mean([meanR,meanG,meanB],'all','omitnan'); % mean of all channels
    
    count = count+1; 
end

%% plot the aggregate means
% labels
subj_IDs = cell(length(0:22),1); 

for i = 0:22

    subj_id_string = ['S' num2str(i, '%03d')]; 
    subj_IDs{i+1,1} = subj_id_string; 

end 

figure; sgtitle('Aggregate Albedo per Subject');
subplot(221);scatter(meanArray(:,1),meanSpecs(:,1));title('R Diffuse vs Specular'); xlabel('diffuse'); ylabel('specular');
% Annotate each data point with a string
for i = 1:length(subj_IDs)
    text(meanArray(i,1), meanSpecs(i,1), subj_IDs{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end
subplot(222);scatter(meanArray(:,2),meanSpecs(:,2));title('G Diffuse vs Specular');xlabel('diffuse'); ylabel('specular');
for i = 1:length(subj_IDs)
    text(meanArray(i,2), meanSpecs(i,2), subj_IDs{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end
subplot(223);scatter(meanArray(:,3),meanSpecs(:,3));title('B Diffuse vs Specular');xlabel('diffuse'); ylabel('specular');
for i = 1:length(subj_IDs)
    text(meanArray(i,3), meanSpecs(i,3), subj_IDs{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end
subplot(224);scatter(meanArray(:,4),meanSpecs(:,4));title('Mean Overall Diffuse vs Specular');xlabel('diffuse'); ylabel('specular');
for i = 1:length(subj_IDs)
    text(meanArray(i,4), meanSpecs(i,4), subj_IDs{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end


%% plot the means

%% mask buddy 
%% plot the function
% figure; plot(lineDiff,lineSpec); title("spec vs map, scanline across forehead");
% xlabel("Albedo vals, linRGB");
% ylabel("Specular vals,linRGB");
% 
% figure;plot(lineDiff,lineAdjSpec);title('adjusted spec for normals');
% xlabel("Albedo vals, linRGB");
% ylabel("Specular vals,linRGB");
% 
% figure;plot((lineSamp),lineAdjSpec); title('spec vs scanline');
% xlabel("scaline")
% ylabel("Adjusted Specularity")
% 
% figure;plot((lineSamp),lineSpec); title('standard specularity');
% xlabel("scaline")
% ylabel("Raw Specularity")
% 
% figure;plot((lineSamp),lineDiff); title('Diffuse against scanline');
% xlabel("scaline")
% ylabel("Adj Diffuse")

function out_im = iso_norm(in_im,subj,isoValues)
    % ISO normalise
    ISO = isoValues(subj +1,2);
    ISO = table2array(ISO);
    ISOref = 250; %min ISO from table

    %Input_Img_spec = imread([rendering.shaderPath '\spec_texture.bmp']);

    %normalise 
    out_im = (in_im.*ISOref)/ISO;

end
