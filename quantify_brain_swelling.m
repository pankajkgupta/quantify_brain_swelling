clear;
close all;

%list all the subjects to be processed
data_path = './';
sub_list = {'m1'};
regmethod = 1;
runningbaseline = 1;

for i = 1:length(sub_list)
    
    sub = sub_list{i};
    
    baselineName = 'baseline_spckl.tif';
    baseline  = imread([data_path sub '/' baselineName]);
%     baseline  = imread([data_path sub '/day0/12 min dw2 sp.tif']);

    imagefiles = {};
    totalswellL = [];
    totalswellR = [];

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
        
        toRegister  = imread([data_path sub '/' recordDays(ix_day).name '/' ...
            dailyTiffsName{1}]);

%         tform = registrationbank(toRegister, baseline, regmethod);

        for ix_img = 1:length(dailyTiffsName)
            close all;
            fprintf('\t registering %s\n', dailyTiffsName{ix_img});
            toRegister = imread([data_path sub '/' recordDays(ix_day).name '/' dailyTiffs(ix_img).name]);
            figure; imshowpair(baseline, toRegister,'Scaling','joint');
            tform = registrationbank(toRegister, baseline, regmethod);
            
            registered = imwarp(toRegister,tform,'OutputView',imref2d(size(baseline)));

            figure; imshowpair(baseline, registered,'Scaling','joint');
            title([baselineName ' + ' dailyTiffsName{ix_img}]);
            saveas(gcf, [data_path sub '/' dailyTiffsName{ix_img}(1:end-4) ...
                ' registered.png']);
            
            baselineMasked = baseline;
            baselineMasked(~binaryMask) = 0;
            registeredMasked = registered;
            registeredMasked(~binaryMask) = 0;
            [u,v] = getoptflow(baselineMasked,registeredMasked);
%             [u,v] = getoptflow(baseline,registered);
            
            % downsize u and v
            u_deci = u(1:10:end, 1:10:end);
            v_deci = v(1:10:end, 1:10:end);
            % get coordinate for u and v in the original frame
            [m, n] = size(baselineMasked);
            [X,Y] = meshgrid(1:n, 1:m);
            X_deci = X(1:20:end, 1:20:end);
            Y_deci = Y(1:20:end, 1:20:end);
            
            % Get coordinates of the boundary of the freehand drawn region.
            structBoundaries = bwboundaries(binaryMask);
            % First cell array is for left hemi
            xy=structBoundaries{1}; % Get n by 2 array of x,y coordinates.
            x = xy(:, 2); % Columns.
            y = xy(:, 1); % Rows.
            polyin = polyshape(x,y);
            interiorL = polyin.isinterior(X_deci(:),Y_deci(:));
            % Second one is for right hemi
            xy=structBoundaries{2}; % Get n by 2 array of x,y coordinates.
            x = xy(:, 2); % Columns.
            y = xy(:, 1); % Rows.
            polyin = polyshape(x,y);
            interiorR = polyin.isinterior(X_deci(:),Y_deci(:));


            imagefiles = [imagefiles; dailyTiffsName{ix_img}];
            totalswellL = [totalswellL; sum(sqrt(u_deci(interiorL).^2 + v_deci(interiorL).^2))];
            totalswellR = [totalswellR; sum(sqrt(u_deci(interiorR).^2 + v_deci(interiorR).^2))];
            
            figure();
            imshow(registeredMasked);
            hold on;
            % draw the velocity vectors
            quiver(X_deci(interiorL), Y_deci(interiorL), u_deci(interiorL),v_deci(interiorL), 'y')
            quiver(X_deci(interiorR), Y_deci(interiorR), u_deci(interiorR),v_deci(interiorR), 'y')
            title(['Optical flow: ' dailyTiffsName{ix_img}]);
            saveas(gcf, [data_path sub '/' dailyTiffsName{ix_img}(1:end-4) ' optflow.png']);
            if runningbaseline
                %set baseline as current image
                baselineName = dailyTiffsName{ix_img};
                baseline = toRegister;
            end
        end
        
    end
    totalswellL = cumsum(totalswellL);
    totalswellR = cumsum(totalswellR);
    fname=[sub '_swelling.csv'];
    writetable(cell2table([imagefiles num2cell(totalswellL) num2cell(totalswellR)]),...
        fname,'writevariablenames',0);
    figure; plot(totalswellL); hold on; plot(totalswellR); 
    title('Progression of swelling'); 
    xlabel('time course'); ylabel('total optical flow(pixels)'); 
    legend('Left', 'Right'); axis tight; xticks([1:numel(imagefiles)]); 
    xticklabels(imagefiles); xtickangle(70);
    saveas(gcf, [data_path sub '/total optflow timecourse.png']);
end
