load S000newMaps.mat

figure; subplot(221); imagesc(Out_Hem); title('Hemoglobin Concentration Maps'); colorbar; 
 subplot(222); imagesc(Out_Mel); title('Melanin Concentration Map'); colorbar; 
 subplot(223); imagesc(Out_Beta); title('Beta Ratio Map');  colorbar; 
 subplot(224); imagesc(Out_Epth); title('Epidermal Thickness Maps');  colorbar; 
