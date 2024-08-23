%% DeltaE across all images

%vars
thr = 0.2; %distance threshold
goal = 50; % goal number of trials 
%% make a loop that loads an image and then compares it to its nearest neihbour
%for this the meaningful comparison is within scale types
% e.g. we load all scale mag 1 images for a permuation and then mutiply it

%need the delta function

mags = 2:10;
perms = 1:9;

permIDs = perms .*100;
magsIDs = mags; 

%ID = permIDs + magsIDs; 
% create distance matrix
dists = zeros(size(mags,1),size(perms,1),4); %2nd and 3rd dim is the image id, 4 is a bool of whether a match was made 

for i = perms
    for j = mags
        dist =1000; %initalise big
        % compare to every other mag in reverse order 
        count =0; 
        while dist>thresh %kill when not big enough and just consider the match to be zero
            1path =  strcat(str2num(i),str2num(j)); 
            %load first mag 
            mag = exrread(1path); 
    
            % load second mag from back of list
            2path = strcat(str2num(perms(end-count)),str2num(end-count));
    
            %compare with delta function
            dist = %func here 
            dist =mean(dist,'all');
            
            dists(j,i,1) = dist;
            id1 = permIDs(i) + magsIDs(j);
            id2 = permIDs(i+1) + magsIDs(j+1);
            dists(j,i,2) = id1;
            dists(j,i,3) = id3; 
            dists(k,i,4) = 1; 
            count = count+1; 
        end 
        
    end 
end

%% discard smallest distances working from the largest scale magnitudes backwards

% discard all non matches
match = dists(:,:,4);

tmp =zeros(size(match),4);
for i = 1:4
    tmp(:,:,i) = match;
end
match = tmp; %create a 4d bool to get all wanted arrays
    
dists = dists(match); %throw away all non thresholded matches 

%% now organise distances by magnitudes 
%extract to variables

deltaDists = dists(:,:,1);
delateDists = deltaDists(:);

id1s= dists(:,:,2);
id1s = id1s(:);

id2s = dists(:,:,3);
id2s = id2s(:);

%put into a table

dists = deltaDists;id1s; id2s; 

% sort by dist value e.g. 1st dim 
dists = sortrows(dists, 1);


%just take the goal amount 

outputList = dists(goal,:);

%% copy the images to another folder 













