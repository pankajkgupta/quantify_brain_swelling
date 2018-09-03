function [tform] = registrationbank(toRegister, baseline, method)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

[optimizer, metric] = imregconfig('multimodal');
optimizer.InitialRadius = 0.0001;
optimizer.Epsilon = 1.5e-4;
optimizer.GrowthFactor = 1.001;
optimizer.MaximumIterations = 500;
        
switch method
    case 1
        disp('case 1');
%         tform = imregtform(toRegister, baseline, 'affine', optimizer, metric);
        tform = imregtform(toRegister, baseline, 'similarity', optimizer, metric);
    case 2
        disp('case 2');
        
        toRegisterBW = imbinarize(toRegister,'adaptive','ForegroundPolarity',...
            'dark','Sensitivity',0.6);
        baselineBW = imbinarize(baseline,'adaptive','ForegroundPolarity',...
            'dark','Sensitivity',0.6);
        SE = strel('rectangle',[10,10]);
        toRegisterBW = imopen(toRegisterBW, SE);
        baselineBW = imopen(baselineBW,SE);
        figure; imshowpair(toRegisterBW,baselineBW,'montage');
        tform = imregtform(single(toRegisterBW), single(baselineBW), 'similarity',...
            optimizer, metric);
    otherwise
        disp('Invalid registration method');
        tform = [];
end
end

