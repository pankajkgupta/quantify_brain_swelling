clear;
close all;

%list all the subjects to be processed
data_path = './';
sub_list = {'m1'};

for i = 1:length(sub_list)
    sub = sub_list{i};
    baseline  = imread([data_path sub '/baseline_spckl.tif']);
%     baseline  = imread([data_path sub '/day0/12 min dw2 sp.tif']);

    % Create a mask if does not exist
    maskPath = [data_path sub '/baseline_mask.png'];
    if exist(maskPath, 'file') == 2
        binaryMask = imread(maskPath);
    else
        binaryMask = getmask(baseline);
        imwrite(binaryMask, maskPath)
    end
    
    % Get a list of all files and folders in this folder.
    files = dir([data_path sub]);
    % Get a logical vector that tells which is a directory.
    dirFlags = [files.isdir] & ~strcmp({files.name},'.') & ~strcmp({files.name},'..');
    % Extract only those that are directories.
    recordDays = files(dirFlags);
    % Print folder names to command window.
    for ix_day = 1 : length(recordDays)
        
        fprintf('Processing %s\n', recordDays(ix_day).name);
   
        dailyTiffs = dir([data_path sub '/' recordDays(ix_day).name '/*.tif']);
        dailyTiffsName = natsort({dailyTiffs.name});
        
        toRegister  = imread([data_path sub '/' recordDays(ix_day).name '/' dailyTiffsName{1}]);

        figure; imshowpair(baseline, toRegister,'Scaling','independent');

        [optimizer, metric] = imregconfig('multimodal');

        optimizer.InitialRadius = 0.0001;
        optimizer.Epsilon = 1.5e-4;
        optimizer.GrowthFactor = 1.001;
        optimizer.MaximumIterations = 200;

        % tform = imregtform(toRegister, baseline, 'affine', optimizer, metric)
        tform = imregtform(toRegister, baseline, 'similarity', optimizer, metric, 'PyramidLevels', 5);

        for ix_img = 1:length(dailyTiffsName)
            close all;
            fprintf('\t registering %s\n', dailyTiffsName{ix_img});
%             toRegister = imread([data_path sub '/' recordDays(ix_day).name '/' dailyTiffs(ix_img).name]);
%             figure; imshowpair(baseline, toRegister,'Scaling','independent');
            
            registered = imwarp(toRegister,tform,'OutputView',imref2d(size(baseline)));

            figure
            imshowpair(baseline, registered,'Scaling','independent')
            title(['baseline + ' dailyTiffsName{ix_img}])
            saveas(gcf, [data_path sub '/' dailyTiffsName{ix_img}(1:end-4) ' registered.png']);
            
            baselineMasked = baseline;
            baselineMasked(~binaryMask) = 0;
            registeredMasked = registered;
            registeredMasked(~binaryMask) = 0;
            [u,v] = getoptflow(baselineMasked,registeredMasked);
            
            % downsize u and v
            u_deci = u(1:10:end, 1:10:end);
            v_deci = v(1:10:end, 1:10:end);
            % get coordinate for u and v in the original frame
            [m, n] = size(baselineMasked);
            [X,Y] = meshgrid(1:n, 1:m);
            X_deci = X(1:20:end, 1:20:end);
            Y_deci = Y(1:20:end, 1:20:end);


            figure();
            imshow(registeredMasked);
            hold on;
            % draw the velocity vectors
            quiver(X_deci, Y_deci, u_deci,v_deci, 'y')
            title(['Optical flow: ' dailyTiffsName{ix_img}]);
            saveas(gcf, [data_path sub '/' dailyTiffsName{ix_img}(1:end-4) ' optflow.png']);
            
            %set baseline as current image
%             baseline = toRegister;
            
        end
        
    end

end
