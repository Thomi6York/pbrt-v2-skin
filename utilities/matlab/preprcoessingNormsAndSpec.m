% flip specular textures and normal maps
close all;
clear all; 
subjects = [0:22];

%load these in from the starting directory
isoValues = readtable("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\csv\CaptureISO_perSubject.csv");


%switch to the dataset
cd("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\scenes\PilotDataSet")
%%
for subj = subjects
    subj_id_string =  ['S' num2str(subj, '%03d')];

    specular_image = imread(strcat(subj_id_string ,'\shader\spec_texture.bmp'));
    specular_image = flipud(specular_image);
     specular_image = double(specular_image)./255;
    specular_image = rgb2lin(specular_image);
    spec_In = specular_image; 
   


    %do the same to the nomral images 
    normal_image = imread([subj_id_string '\shader\spec_normal.bmp']);
    normal_image = double(normal_image)./255;
    normal_image = flipud(normal_image);
    normal_image = rgb2lin(normal_image);
    
    %% this is done in the code, uneeded 
%     % Convert to normals
%     normals = normal_image * 2.0 - 1.0;
% 
%     % Normalize the normal vectors
%     lengths = sqrt(sum(normals.^2, 3));
%     normals(:, :, 1) = normals(:, :, 1) ./ lengths;
%     normals(:, :, 2) = normals(:, :, 2) ./ lengths;
%     normals(:, :, 3) = normals(:, :, 3) ./ lengths;
%    
%     normal_image = normals;

    %normalise ISOs for spec text (only)
    ISO = isoValues(subj +1,2);
    ISO = table2array(ISO);
    ISOref = 250; %min ISO from table 

    specular_image = (specular_image.*ISOref)/ISO;


%     % compare 
%     for i = 1:3
%         diff = normal_In(:,:,i) - normal_image(:,:,i);
%         figure; imagesc(diff)
% 
%     end

    %display image for checking
    figure; imshow(specular_image); title('Flipped Specular Texture');
    figure; imshow(normal_image); title('Flipped Normal Map');

    %save the flipped texture as an .exr
    exrwrite(specular_image, [subj_id_string '\shader\spec_textureISONormFlipped.exr']);
    exrwrite(normal_image, [subj_id_string '\shader\spec_normalFlipped.exr']);

    % reflip and save as exr
    specular_image = flipud(specular_image);
    normal_image = flipud(normal_image);

    exrwrite(specular_image, [subj_id_string '\shader\spec_textureISONorm.exr']);
    exrwrite(normal_image, [subj_id_string '\shader\spec_normal.exr']);

    disp(['Flipped specular texture and normal texture for subject' subj_id_string 'saved as spec_textureISONormFlipped.exr'])

end