% flip specular textures and normal maps

subjects = [0,3,5,7,22];

%load these in from the starting directory
isoValues = readtable("C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\csv\CaptureISO_perSubject.csv");


%switch to the dataset
cd(".\scenes\PilotDataSet\")
%%
for subj = subjects
    subj_id_string =  ['S' num2str(subj, '%03d')];

    specular_image = imread(strcat(subj_id_string ,'\shader\spec_texture.bmp'));
    specular_image = flipud(specular_image);
    specular_image = rgb2lin(specular_image);
    specular_image = double(specular_image)./255;


    %do the same to the nomral images 
    normal_image = imread([subj_id_string '\shader\spec_normal.bmp']);
    normal_image = double(normal_image)./255;
    normal_image = flipud(normal_image);
    normal_image = rgb2lin(normal_image);

    %normalise ISOs for spec text (only)
    ISO = isoValues(subj +1,2);
    ISO = table2array(ISO);
    ISOref = 250; %min ISO from table 

    specular_image = (specular_image.*ISOref)/ISO;

    %display image for checking
    figure; imshow(specular_image); title('Flipped Specular Texture');
    figure; imshow(normal_image); title('Flipped Normal Map');

    %save the flipped texture as an .exr
    exrwrite(specular_image, [subj_id_string '\shader\spec_textureISONormFlipped.exr']);
    exrwrite(normal_image, [subj_id_string '\shader\spec_normalFlipped.exr']);

    disp(['Flipped specular texture and normal texture for subject' subj_id_string 'saved as spec_textureISONormFlipped.exr'])

end