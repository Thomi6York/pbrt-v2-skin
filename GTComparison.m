%%
close all 
clear all
%%
format longG;
subj_id_string = 'S000'; 

face_mask = imread(['C:\Users\Tom\OneDrive - University of York\Documents\GitHub\Skin_code\data\ICT_3DRFE_mod\' subj_id_string '\shader\' subj_id_string '_E00_Mask.bmp']); 
face_mask = face_mask(:,:,2)>0;


% load images you want to compare

texRend = exrread("sharedFolder\S000_PermNo_1_ManipNoOverHead.exr");
bruteRend = exrread("sharedFolder\Subj000PermID1Backgr.exr");

figure;subplot(121);imshow(lin2rgb(texRend)); title('Textured PBRT rendered'); subplot(122);imshow(lin2rgb(bruteRend)); title('Brute rendered'); sgtitle('Perm ID 1');

signedError = double(bruteRend) - double(texRend); 
figure;
for i = 1:3
    gcf; subplot(1,3,i); imagesc(signedError(:,:,i));
    clim([-0.4, 0.4]);
end
gcf; colorbar; sgtitle('signed error (CompositedBaseImages - (original textured head w/3rd perc concentrations))')
% compare the brute rendered head and the current method


%% relative error 

relError = abs(double(bruteRend) - double(texRend));  

figure;
for i = 1:3
    gcf; subplot(1,3,i); imagesc(relError(:,:,i));
    clim([-0.4, 0.4]);
end
gcf; colorbar;sgtitle('relative error')