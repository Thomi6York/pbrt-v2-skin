% flip specular textures and normal maps

subjects = [0,3,5,7,22];

%switch to the dataset
cd(".\scenes\PilotDataSet\")
%%
for subj = subjects
    subj_id_string =  ['S' num2str(subj, '%03d')];

    specular_image = exrread(strcat(subj_id_string ,'\shader\spec_textureISONorm.exr'));
    specular_image = flipud(specular_image);

    %do the same to the nomral images 
    normal_image = imread([subj_id_string '\shader\spec_normal.bmp']);
    normal_image = double(normal_image)/255;
    normal_image = flipud(normal_image);

    %display image for checking
    figure; imshow(specular_image); title('Flipped Specular Texture');
    figure; imshow(normal_image); title('Flipped Normal Map');

    %save the flipped texture as an .exr
    exrwrite(specular_image, [subj_id_string '\shader\spec_textureISONormFlipped.exr']);
    exrwrite(normal_image, [subj_id_string '\shader\spec_normalFlipped.exr']);

    disp(['Flipped specular texture and normal texture for subject' subj_id_string 'saved as spec_textureISONormFlipped.exr'])

end