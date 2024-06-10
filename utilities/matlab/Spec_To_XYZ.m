function XYZ  = Spec_To_XYZ(Light_spectrum, CMFs, delta_lambda)


XYZ = [-1 -1 -1];

dims = size(CMFs);
n_samples_cmfs = dims(1);
if n_samples_cmfs ~= Light_spectrum
    return;
end


XYZ(1) = (sum((Light_spectrum .* CMFs(:,1))* delta_lambda)); 
XYZ(2) = (sum((Light_spectrum .* CMFs(:,2))* delta_lambda));
XYZ(3) = (sum((Light_spectrum .* CMFs(:,3))* delta_lambda)); 

    
