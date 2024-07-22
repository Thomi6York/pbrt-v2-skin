outIm = exrread('C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\Experiments\SpectralData\Skin_code\bruteAlbedoBackground.exr'); 
compIm = exrread('C:\Users\tw1700\OneDrive - University of York\Documents\PhDCore\pbrt-v2-skin\utilities\BruteRender\BruteRenderpbrt.exr'); % for background

figure; subplot(1,2,1); imshow(lin2rgb(outIm)); title('Brute Render from Composite According to UV map');
subplot(1,2,2); imshow(lin2rgb(compIm)); title('Rendered from pbrt Using the Pipeline');

diffIm = abs(outIm - compIm);
figure;
sgtitle('Absolute Difference');
subplot(1,3,1); imagesc(diffIm(:,:,1)); title('R channel');
subplot(1,3,2); imagesc(diffIm(:,:,2)); title(' G channel');
subplot(1,3,3); imagesc(diffIm(:,:,3)); title(' B channel');


