clear all

% get current directory
ogPath = pwd;

chromPath = "C:\Users\tw1700\Downloads\Code_chromophores_estimation\";
cd(chromPath);

%% get reflection of third percentiles using LUT
load(".\data\LUTs_luxeon_CIEcmfwithbeta.mat");
load LUTs_Lab; % get the lab version to avoid computing on the fly
load('.\data\inverse_rendering_data.mat')
load('.\data\LED_spectrum_luxeon.mat');
light_spectrum = light_spectrum(21:10:321,2);

%% crop the LUT as in texture editor since we ignore beta and limit variable thickness to produce a 3D array
%between 110 and 30 epi 1:9

LUTCrop = LUTs(:,1:9,:,:,:);

[d1, d2, d3, d4, d5] = size(LUTCrop);

visLUT = LUTCrop(1,1,:,:,:);
visLUT = reshape(visLUT,d3,d4,d5);

figure; imshow(lin2rgb(visLUT)); hold on; plot(25,1,'r+', 'MarkerSize', 10);
% epth,hem,mel

% best beta is clamped to optimal -- so get LUT per beta?
%% split LUT channels into 3D arrays

x = zeros(d2,3);
y = zeros(d3,3);
z = zeros(d4,3);

xq = 0:0.001:0.5;
yq = Epth_sampling(1:d2); %leave epth alone bc sampled regularly 
zq = 0:0.001:0.5;

% generate actual permutations of new coordinate system
count = 0;

perms =zeros((length(xq)*length(zq)*length(yq)),3);
permsID =perms; 
    % permute all values
    for i = 1:size(xq,2)
        for j = 1:size(yq,2)
            for k =1:size(zq,2)
                %don't add a perm if its just the GT 
    
                    count = count + 1;
                    perms(count,1) = xq(1,i);
                    perms(count,2) = yq(1,j);
                    perms(count,3) = zq(1,k);
                    % correspondence 
                    permsID(count,1) = i;
                    permsID(count,2) = j;
                    permsID(count,3) = k; 
    
            end
 
        end
    end

    %% permute old points 
     % permute all values

 permsOld = zeros(5*length(Hem_sampling)*length(Mel_sampling),3); 

count=0;
    for i = 1:length(Hem_sampling)
        for j = 1:9
            for k =1:length(Mel_sampling)
                %don't add a perm if its just the GT 
    
                    count = count + 1;
                    permsOld(count,1) = Hem_sampling(i);
                    permsOld(count,2) = Epth_sampling(j);
                    permsOld(count,3) = Mel_sampling(k);
    
            end
 
        end
    end

%% plot the new 3d points
figure; subplot(121);scatter3(perms(:,1),perms(:,2),perms(:,3), 'filled'); title('new sampling space');
subplot(122); scatter3(permsOld(:,1),permsOld(:,2),permsOld(:,3), 'filled'); title('Original sampling space'); 

%% interpolation step

newLUT = zeros(d1,d2,length(xq),length(yq),3); 
Vq = zeros(d1,size(perms,1),3); 

for b = 1:d1 % beta vals
    for i = 1:3
        v = LUTCrop(b,:,:,:,i);
        v = reshape(v,d2,d3,d4);
        
        % for some reason x is the second dim of V
        yi = Epth_sampling(1:d2);

        xi = Hem_sampling;
        zi = Mel_sampling;

        
        
        Vq(b,:,i) = interp3(xi,yi,zi,v,perms(:,1),perms(:,2),perms(:,3));

       for row = 1:length(Vq)
           I = permsID(row,1); % remember to switch 2nd and first dims  
           J = permsID(row,2);
           K = permsID(row,3);

           newLUT(b,J,I,K,i) = Vq(b,row,i); 
     
       end



    
    end 
end 

[d1, d2, d3, d4, d5] = size(newLUT);

visLUT = newLUT(1,1,:,:,:);
visLUT = reshape(visLUT,d3,d4,d5);

figure; imshow(lin2rgb(visLUT)); hold on; plot(25,1,'r+', 'MarkerSize', 10);

% go back to original dir
cd(ogPath);
