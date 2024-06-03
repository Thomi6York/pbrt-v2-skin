subjects = [0,3,5,7,22];

%load these in from the starting directory
isoValues = readtable('CaptureISO_perSubject.csv');

%switch to the dataset
cd("E:\pbrt-v2-skinPat\scenes\PilotDataSet\")

for subj = subjects
    subj_id_string =  ['S' num2str(subj, '%03d')];

    specular_image = imread([subj_id_string '\shader\spec_texture.bmp']);
    specular_image = rgb2lin(specular_image);

    specular_image = double(specular_image)/255;

    %normalise ISOs
     ISO = isoValues(subj +1,2);
     ISO = table2array(ISO);
     ISOref = 250; %min ISO from table 

     %normalise 
     specular_image = (specular_image.*ISOref)/ISO;

    %display image for checking
    figure; imshow(lin2rgb(specular_image)); title('Normalised Specular Texture');

    %save the normalised texture as an .exr in lin rgb
    exrwrite(specular_image, [subj_id_string '\shader\spec_textureISONorm.exr']);

    disp(['Normalised specular texture for subject' subj_id_string 'saved as spec_textureISONorm.exr'])

end