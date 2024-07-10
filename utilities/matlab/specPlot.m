%% spec mapping
close all
clear all

%% load images
imagePath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\experiments\reRunWNormsandCorrectSpec\pigmentMaps\", "S000", "normTexISONorm.mat");
load(imagePath);
dims = size(Out_Img);



subjs = [0,3,5,7];

allArr = zeros(length(subjs),dims(1),dims(2),4);



sampl = 100;
interval = ((959-422)/sampl);
interval = round(interval); 
 

%% draw a line along subj000's head 

lineSamp = 422:interval:959; 
y = 418;

figure;imshow(Out_Img); hold on; plot(lineSamp,y,'-x')

%% 
meanArray = zeros(length(subjs),length(lineSamp));
count = 1; 
for subj = subjs
    

    subj_id_string = ['S' num2str(subj, '%03d')];
    dataSetPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\", subj_id_string,  "\shader\");
    imagePath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\experiments\reRunWNormsandCorrectSpec\pigmentMaps\", subj_id_string , "normTexISONorm.mat"); %load from pigment maps bc image is normalised
    specPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\", subj_id_string ,"\shader\spec_textureISONormFlipped.exr");
    normalPath = strcat("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet\", subj_id_string ,"\shader\spec_normalFlipped.exr");
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

    % convert to linear
    RNI = rgb2lin(RNI);
    GNI = rgb2lin(GNI);
    BNI = rgb2lin(BNI);

    % convert to double
    RNI = double(RNI)./255;
    GNI = double(GNI)./255;
    BNI = double(BNI)./255;




    %normal
    SpecNormal = exrread(normalPath);
    SpecNormal = flipud(SpecNormal);

    %spec text
    spec = exrread(specPath);
    spec = flipud(spec); % flip due to saving

    % eliminate pixels greater than 45 degrees to the viewing angle to
    % remove fresnel

    viewDir = [0,0,1]; % z axis
    dotNormSpec = SpecNormal(:,:,1)*viewDir(1)+SpecNormal(:,:,2)*viewDir(2)+SpecNormal(:,:,3)*viewDir(3);
    SpecDeg = rad2deg(dotNormSpec); 
    
    figure;
    for i = 1:3
        temp = spec(:,:,i);
        temp = reshape(temp,size(SpecNormal,1,2));
        temp(SpecDeg<45) = 0;
        subplot(1,3,i);imshow(temp); title('attempt to remove fresenel)') %check this removes the frensnel
        spec(:,:,i) = temp; 
    end
   

    %spec

    %inverse rendered map
    load(imagePath);
    im = Out_Img; 

    %% correct specular textures accounting for nomals by dividing by the cosine 
    % load in normals 

%    coNorm = cos(normal);

    viewDir = [0,0,1]; % assume z axis viewing 
    dotNormR = RNI(:,:,1)*viewDir(1)+RNI(:,:,2)*viewDir(2)+RNI(:,:,3)*viewDir(3);
    dotNormG = GNI(:,:,1)*viewDir(1)+GNI(:,:,2)*viewDir(2)+GNI(:,:,3)*viewDir(3);
    dotNormB = BNI(:,:,1)*viewDir(1)+BNI(:,:,2)*viewDir(2)+BNI(:,:,3)*viewDir(3);


    rDiff = im(:,:,1)./dotNormR;
    
    if subj == 0
        figure; imshow(rDiff); title('Diffuse albedo accounting for viewing angle via dot product')
    end

    
    gDiff = im(:,:,2)./dotNormG;
    bDiff = im(:,:,3)./dotNormB; 
    

    % add to a bigger array
    allArr(count,:,:,1) = rDiff;
    allArr(count,:,:,2) = gDiff;
    allArr(count,:,:,3) = bDiff; 
    allArr(count,:,:,4) = mean(spec,3); 

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

    figure; hold on; subplot(141);plot(lineSamp,RDiffLine(:),'-xr');title("R Diffuse"); ylim([0, 0.35]);
    subplot(142);plot((lineSamp),GDiffLine(:),'-xg');title("G Diffuse"); ylim([0, 0.35]);
    subplot(143);plot((lineSamp),BDiffLine(:),'-xb');title("B Diffuse"); ylim([0, 0.35]);
    subplot(144); plot((lineSamp),meanDiff(i,:));title("Mean Diffuse"); ylim([0, 0.35]);
    sgtitle(strcat('Plots for subj ' ,num2str(subjs(i))));
    hold off

end 

lineSpec =  meanSpec(1,y,lineSamp);
lineSpec= lineSpec(lineSpec>0); % eliminate fresnel pixels
lineSpec = lineSpec(:); 

allMeanDiff = mean(meanDiff,1);
figure; scatter(allMeanDiff,lineSpec); xlabel('Diffuse');ylabel('Specular')
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



figure; hold on; subplot(141);plot((lineSamp),meanR,'r');title("R Diffuse"); ylim([0, 0.35]);
    subplot(142);plot((lineSamp),meanG,'g');title("G Diffuse") ;ylim([0, 0.35]);
    subplot(143);plot((lineSamp),meanB,'b');title("B Diffuse");ylim([0, 0.35]);
    subplot(144); plot((lineSamp),allMeanDiff);title("Mean Diffuse");  ylim([0, 0.35]);
    sgtitle('Mean Accross subjects');
   

%% plot the function
figure; plot(lineDiff,lineSpec); title("spec vs map, scanline across forehead");
xlabel("Albedo vals, linRGB");
ylabel("Specular vals,linRGB");

figure;plot(lineDiff,lineAdjSpec);title('adjusted spec for normals');
xlabel("Albedo vals, linRGB");
ylabel("Specular vals,linRGB");

figure;plot((lineSamp),lineAdjSpec); title('spec vs scanline');
xlabel("scaline")
ylabel("Adjusted Specularity")

figure;plot((lineSamp),lineSpec); title('standard specularity');
xlabel("scaline")
ylabel("Raw Specularity")

figure;plot((lineSamp),lineDiff); title('Diffuse against scanline');
xlabel("scaline")
ylabel("Adj Diffuse")


