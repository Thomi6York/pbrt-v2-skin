load results\experiments\reRunWNormsandCorrectSpec\pigmentMaps\S000_newMapsISONorm.mat

figure; subplot(221); imagesc(Out_Hem); title('Hemoglobin Concentration Maps');
 subplot(222); imagesc(Out_Mel); title('Melanin Concentration Map');
 subplot(223); imagesc(Out_Beta); title('Beta Ratio Map')
 subplot(224); imagesc(Out_Epth); title('Epidermal Thickness Maps')