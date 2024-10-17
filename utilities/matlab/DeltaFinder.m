%% Notes
% if multipicative the perm5 is the GT for all mags


%%
close all
clear all
%% DeltaE across all images

%vars
thr = 33; %distance threshold
goal = 30; % goal number of trials 
%% make a loop that loads an image and then compares it to its nearest neihbour
%for this the meaningful comparison is within scale types
% e.g. we load all scale mag 1 images for a permuation and then mutiply it
ImDir = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\experiments\MultipleScalings\groundTruth\perms\S000_";
scaleType = "Multiplicative";
imHandle = "_ManipnormTexISONormnormTexISONormFinal"; % this is just for the im handle

%need the delta function

mags = 2:9;
permList = 1:9;
image = exrread(strcat(ImDir, "PermNo_1",imHandle,scaleType,"2.0.exr")); %example im


%% load mask
mask = loadMask();

%% load all images to a struct
numImages = length(mags)*length(permList); % Assuming images is a 3D array where the 3rd dimension is the number of images

ids = zeros(numImages,3); % 1st for perms, 2nd for mags, 3rd for scaling type where 1 is multi, 2 is additive 
count = 1;

images = struct('data', cell(length(permList)* length(mags),1)); %preallocate struct

for i = 1:length(permList)
    for j = 1:length(mags)
        if permList(i) == 5 % Only add one image from perm 5
            if mags(j) == 2 % Only add the image for mag 1
                path = strcat(ImDir, "PermNo_", num2str(permList(i)), imHandle, scaleType, num2str(mags(j), '%.1f'), ".exr");

                % Apply mask
                image = exrread(path);
                tmp = size(image);
                image = reshape(repmat(image(mask), [1, 1, 3]),[],3);

                images(count).data = image;
                ids(count,1) = permList(i); % Create an id for each image that corresponds to the permutation and magnitude
                ids(count,2) = mags(j);
                ids(count,3) = 1; 
                count = count+1;

                gtID = count; % Store the ID of the GT image
            
            else
                images(count).data = NaN; % Skip all other images for perm 5
                ids(count,1) = NaN; % Create an id for each image that corresponds to the permutation and magnitude
                ids(count,2) = NaN;
                ids(count,3) = NaN;
                count = count+1;
            end 
        else % Add all other images
            path = strcat(ImDir, "PermNo_", num2str(permList(i)), imHandle, scaleType, num2str(mags(j), '%.1f'), ".exr");

            % Apply mask
            image = exrread(path);
            tmp = size(image);
            image = reshape(repmat(image(mask), [1, 1, 3]),[],3);

            images(count).data = image;
            ids(count,1) = permList(i); % Create an id for each image that corresponds to the permutation and magnitude
            ids(count,2) = mags(j);
            ids(count,3) = 1;
            count = count+1;
        end
    end 
end

%% load all Addtive images as well
numImages = (length(permList)-1)* length(mags);

images2 = struct('data', cell(numImages,1)); %preallocate struct

count = 1;
ids2 = zeros(numImages,3); % 1st for perms, 2nd for mags, 3rd for scaling type where 1 is multi, 2 is additive 
scaleType = "Additive";

for i = 1:length(permList)-1
    for j = 1:length(mags)
        % Add all other images
        path = strcat(ImDir, "PermNo_", num2str(permList(i)), imHandle, scaleType, num2str(mags(j), '%.1f'), ".exr");

        % Apply mask
        image = exrread(path);
        tmp = size(image);
        image = reshape(repmat(image(mask), [1, 1, 3]),[],3);

        images2(count).data = image;
        ids2(count,1) = permList(i); % Create an id for each image that corresponds to the permutation and magnitude
        ids2(count,2) = mags(j);
        ids2(count,3) = 2; 
        count = count+1;
    end 
end

%% remove nan images from struct
% Remove NaN cells from the struct
% images is multiplicative and images 2 is additive  
images = images(~arrayfun(@(x) any(isnan(x.data(:))), images));
ids = ids(~isnan(ids(:,1)),:); % Remove empty IDs

%% append images 2 to the end of images 
images = [images; images2];
ids = [ids; ids2];
numImages = length(images); % Update the number of images

%% convert to lab
meanLab = zeros(numImages,3);
for i = 1:numImages

    mag1 = images(i).data;

    % Convert to LAB
    labIm1 = rgb2lab(mag1);

    meanLab(i,:) = mean(labIm1,1); 
end

%% just apply cluster directly to lab sapce
numClusters = goal; % Set the number of clusters to the goal amount
[idx, centroids] = kmeans(meanLab(:, 1:3), numClusters);

outputListLab = zeros(numClusters, size(meanLab, 2)+3);
for k = 1:numClusters
    clusterIndices = find(idx == k);
    clusterDists = meanLab(clusterIndices, :);
    [~, minIdx] = min(abs(clusterDists(:, 1) - centroids(k)));
    outputListLab(k, :) = [clusterDists(minIdx, :), ids((clusterIndices(minIdx)),1),ids((clusterIndices(minIdx)),2),ids(clusterIndices(minIdx),3)]; % get nearest to centroid and store the id
end

%% plot the lab clusters as 3d images and selected images
figure;
% Plot the selected images in the cluster
x = outputListLab(:,1);
y = outputListLab(:,2);
z = outputListLab(:,3);
scatter3(x, y, z, 'b', 'SizeData', 100);
hold on; % Ensure that the plots are held

%Plot all images in the LAB space
x = meanLab(:,1);
y = meanLab(:,2);
z = meanLab(:,3);
scatter3(x, y, z, 'r');

% Add labels and title for clarity
xlabel('L*');
ylabel('a*');
zlabel('b*');
title('LAB Space Clustering');
legend('Selected Images', 'All Images');
hold off; % Optional: Release the hold state

%% plot the ids 
figure;
x = ids(ids(:,3) == 1, 1);
y = ids(ids(:,3) == 1, 2);
scatter(x, y, 'red', 'SizeData', 100)
hold on
x = outputListLab(outputListLab(:,6) == 1, 4);
y = outputListLab(outputListLab(:,6) == 1, 5);
scatter(x, y, 'blue');

title('Scatter by identity i.e. the scaling factor applied (multiplicative)')

legend('All Images','Selected Images');

figure;
x = ids(ids(:,3) == 2, 1);
y = ids(ids(:,3) == 2, 2);
scatter(x, y, 'red', 'SizeData', 100)
hold on
x = outputListLab(outputListLab(:,6) == 2, 4);
y = outputListLab(outputListLab(:,6) == 2, 5);
scatter(x, y, 'blue');

title('Scatter by identity i.e. the scaling factor applied (additive)')
legend('All Images','Selected Images');
%% custom clustering using delta

% Number of clusters
numClusters = goal;

% Initialize outputListLab to store the LAB values and IDs
outputListLab = zeros(numClusters, size(meanLab, 2) + 3);

% Select the GT first
gtID = find(ids(:,1) == 5 & ids(:,2) == 2 & ids(:,3)==1); % Find the index of the GT image
selectedIndices = gtID; % Select the GT image, or you can initialize randomly
outputListLab(1, :) = [meanLab(selectedIndices, :), ids(selectedIndices,1),ids(selectedIndices,2),ids(selectedIndices,3)];

% Select remaining images to maximize perceptual distance
%copilot's comment:
% If you were to select the image with the maximum distance from the start, you might end up with a suboptimal selection. For example, if B is slightly further from A than C, you would select B. However, C might be much further from B than A is from B, leading to a better overall distribution.
 
%% essentialyl we are looking for a difference small enough that its local to the selected images, but large enough that it is not the same image for uniform sampling in the space
% looking at just the biggest difference is not the best way to do this because it creates clusters of similar images at extrema of the space
% we look for the minimal distance from candidate images and compare this
% to all other images to find the max, rather than just using the max

for k = 2:numClusters % number of goal images
    maxDist = -inf; % init value
    maxIdx = 1; % init value
    for i = 1:size(meanLab, 1) % for all images
        if ismember(i, selectedIndices) % if image is already selected
            continue; 
        end
        minDistToSelected = inf; % init value
        for j = 1:length(selectedIndices) % for all selected images (original is GT)
            % Calculate the distance between the current image and each selected image
            dist = DeltaE_94_pix_to_Matrix1D(meanLab(i, :), meanLab(selectedIndices(j), :));
            if dist < minDistToSelected % if the distance is less than the minimum distance to selected images
                minDistToSelected = dist; % Update the minimum distance to selected images
            end
        end
        if minDistToSelected > maxDist % if the minimum distance to selected images is greater than the maximum distance
            maxDist = minDistToSelected; % Update the maximum distance -- this is the image with the maximum distance to the selected images that will be selected
            maxIdx = i; % Update the index of the image with maximum distance
        end
    end
    selectedIndices = [selectedIndices; maxIdx]; % Add the image with maximum distance to the selected indices
    outputListLab(k, :) = [meanLab(maxIdx, :), ids(maxIdx,1),ids(maxIdx,2), ids(maxIdx,3)]; % Store the LAB values and IDs of the selected image
end

% Plot the LAB clusters as 3D images and selected images
figure;
% Plot the selected images in the cluster
x = outputListLab(:, 1);
y = outputListLab(:, 2);
z = outputListLab(:, 3);
scatter3(x, y, z, 'b', 'SizeData', 100);
hold on; % Ensure that the plots are held

% Plot all images in the LAB space
x = meanLab(:, 1);
y = meanLab(:, 2);
z = meanLab(:, 3);
scatter3(x, y, z, 'r');

% Add labels and title for clarity
xlabel('L*');
ylabel('a*');
zlabel('b*');
title('LAB Space Clustering using delta 94');
legend('Selected Images', 'All Images');

%% plot the ids 
figure;
x = ids(:,1);
y = ids(:,2);
scatter(x,y,'red', 'SizeData',100)
hold on
x = outputListLab(:,4);
y = outputListLab(:,5);
scatter(x,y,'blue');

title('Scatter by identity usign delta 94')

legend('All Images','Selected Images');

%% load in the selected images with a roughly square crop and coalate them into a grid
clear images % clear the main dataset for memory 
% Load the selected images
chosenPerms = outputListLab(:,4);
chosenMagnitudes = outputListLab(:,5);
chosenScalingTypes = outputListLab(:,6);
chosenImages = struct('data', cell(length(chosenPerms), 1));

% Load the images
path = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\experiments\MultipleScalings\groundTruth\perms\S000_";
count =1; 
for i = 1:size(outputListLab,1)
        if chosenScalingTypes(i) == 1
            scaleType = "Multiplicative";
            path = strcat(ImDir, "PermNo_", num2str(chosenPerms(i)), imHandle, scaleType, num2str(chosenMagnitudes(i), '%.1f'), ".exr");
        else
            scaleType = "Additive";
            path = strcat(ImDir, "PermNo_", num2str(chosenPerms(i)), imHandle, scaleType, num2str(chosenMagnitudes(i), '%.1f'), ".exr");
        end

        image = exrread(path); 

        % crop image to central region
        image = image(:, 300:900, :);
        % lower resolution
        image = imresize(image, [100, 100]);
        chosenImages(count).data = image;
        count = count+1;       
end 

% Create a grid of images
numCols = 6; % Number of columns in the grid
numRows = ceil(length(chosenImages) / numCols); % Number of rows in the grid
figure;
% remove white space
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
for i = 1:length(chosenImages)
    subplot(numRows, numCols, i);
    imshow(lin2rgb(chosenImages(i).data));
    if chosenScalingTypes(i) == 1
        type = "Multiplicative";
        title(sprintf('Perm %d, Mag %.1f, Type %s', chosenPerms(i), chosenMagnitudes(i), type));
    else
        type = "Additive";
        title(sprintf('Perm %d, Mag %.1f, Type %s', chosenPerms(i), chosenMagnitudes(i), type));
    end
end

% Copy the chose images to their own folder

% Create a folder to store the selected images
outputDir = "C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\results\experiments\MultipleScalings\groundTruth\selectedImages\";
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% copy the selected images to the output directory using terminal commands
for i = 1:length(chosenImages)
    if chosenScalingTypes(i) == 1
        scaleType = 'Multiplicative';
        path = strcat(ImDir, "PermNo_", num2str(chosenPerms(i)), imHandle, scaleType, num2str(chosenMagnitudes(i), '%.1f'), ".exr");
    else
        scaleType = 'Additive';
        path = strcat(ImDir, "PermNo_", num2str(chosenPerms(i)), imHandle, scaleType, num2str(chosenMagnitudes(i), '%.1f'), ".exr");
    end
    copyfile(path, outputDir);

    %png options 
    %im = exrread(path);
    %imwrite(lin2rgb(im), strcat(outputDir, "PermNo_", num2str(chosenPerms(i)), imHandle, scaleType, num2str(chosenMagnitudes(i), '%.1f'), ".png"));
end





%% funcs 
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


function mask = loadMask()
    uv = exrread("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\UVPasses\UVSubj000.exr");
    mask = uv; 
    
    mask(uv>0.5) = 1; % should thresh it
    
    %remove other color channels
    mask = mask(:,:,1); 
    mask = logical(mask);
end 



function dists = massDelta(images)

dists = zeros(numImages, numImages, 4);
for i = 1:numImages
    for j = 1:numImages
        if i ~= j % Skip comparison with the same image
            % Calculate perceptual distance between image i and image j
            mag1 = images(i).data;
            mag2 = images(j).data;

            % Convert to LAB
            labIm1 = rgb2lab(mag1);
            labIm2 = rgb2lab(mag2);

            % Compare with delta function
            dist = DeltaE_94_pix_to_Matrix1D(labIm1, labIm2);
            dist = mean(dist, 'all');

            % Store distance and IDs
            dists(i, j, 1) = dist;
            dists(i, j, 2) = i;
            dists(i, j, 3) = j;
            dists(i, j, 4) = 1; % Mark as a valid comparison

            
        end
    end 
end 

end
% 
% meanLab = zeros(numImages,3);
% for i = 1:numImages
% 
%     mag1 = images(i).data;
% 
%     % Convert to LAB
%     labIm1 = rgb2lab(mag1);
% 
%     meanLab(i,:) = mean(labIm1,1); 
% end

%% old stuff
%% main loop

%dists = massDelta(images); 

%% add to a lab stuct

%% discard smallest distances working from the largest scale magnitudes backwards

% % discard all non matches
% match = dists(:,:,4);
% 
% logicalIndex = repmat(match, [1, 1, size(dists, 3)]);
% logicalIndex = logical(logicalIndex);
% 
% % throw away all non matches in array
% %OutDists = dists(logicalIndex); %throw away all non thresholded matches 
% 
% % Use the logical index to filter the dists array
% filteredDists = dists(logicalIndex);
% 
% % Reshape the filtered array to maintain the original structure
% numMatches = sum(match(:));
% OutDists = reshape(filteredDists, numMatches, size(dists, 3));

%% now organise distances by magnitudes 
% % extract to variables
% 
% deltaDists = OutDists(:,1);
% deltaDists = deltaDists(:);
% 
% id1s= OutDists(:,2);
% id1s = id1s(:);
% 
% id2s = OutDists(:,3);
% id2s = id2s(:);
% 
% %put into a table
% 
% finalDists = [deltaDists,id1s, id2s]; 
% 
% % sort by dist value e.g. 1st dim 
% finalDists = sortrows(finalDists, 1);
% 
% 
% % Apply K-means clustering
% numClusters = goal; % Set the number of clusters to the goal amount
% [idx, centroids] = kmeans(finalDists(:, 1), numClusters);
% 
% % Select representative images from each cluster
% outputList = zeros(numClusters, size(finalDists, 2));
% for k = 1:numClusters
%     clusterIndices = find(idx == k);
%     clusterDists = finalDists(clusterIndices, :);
%     [~, minIdx] = min(abs(clusterDists(:, 1) - centroids(k)));
%     outputList(k, :) = clusterDists(minIdx, :);
% end
% 
% %just take the goal amount 
% %outputList = finalDists(1:goal,:);
% 
% %% validate the sorting algorithm by plotting the matches/comparison spread -- should be fairly even
% 
% figure;
% x = outputList(:,2);
% y = outputList(:,3);
% scatter(x,y);

%% funcs 

%%

