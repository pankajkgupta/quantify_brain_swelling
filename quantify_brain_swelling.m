clear;
close all;

%list all the subjects to be processed
data_path = 'C:\Users\user\Desktop\blood flow\';
sub_list = {'vgat 4 hz-ipsi'};
regmethod = 1;
runningbaseline = 0;

for i = 1:length(sub_list)
    
    sub = sub_list{i};
    
    baselineName = 'bas_Spckl.tif';
    baseline  = imread([data_path sub '/' baselineName]);
%     baseline  = imread([data_path sub '/day0/12 min dw2 sp.tif']);

    baseline = image_clamp(baseline);
    baseline = imgaussfilt(baseline,4);
    
    imagefiles = {};
    totalswellL = [];
    totalswellR = [];
    maxswellL = [];
    maxswellR = [];

    % Create a mask if does not exist
    maskPath = [data_path sub '\baseline mask.png'];
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
   
        dailyTiffs = dir([data_path sub '\' recordDays(ix_day).name '\*.tif']);
        dailyTiffsName = natsort({dailyTiffs.name});
        
%         toRegister  = imread([data_path sub '/' recordDays(ix_day).name '/' dailyTiffsName{1}]);

%         tform = registrationbank(toRegister, baseline, regmethod);
        imageseries = [];
        binaryMaskSeries = [];
        tform = [];
        for ix_img = 1:length(dailyTiffsName)
            close all;
            fprintf('\t registering %s\n', dailyTiffsName{ix_img});
            toRegister = imread([data_path sub '\' recordDays(ix_day).name '\' dailyTiffsName{ix_img}]);
            toRegister = image_clamp(toRegister);
            toRegister = imgaussfilt(toRegister,4);
            figure; imshowpair(baseline, toRegister,'Scaling','joint');
            if isempty(tform)
                tform = registrationbank(toRegister, baseline, regmethod);
            end
            
            registered = imwarp(toRegister,tform,'OutputView',imref2d(size(baseline)));

            figure; imshowpair(baseline, registered,'Scaling','joint');
            title([baselineName ' + ' dailyTiffsName{ix_img}]);
            saveas(gcf, [data_path sub '\' dailyTiffsName{ix_img}(1:end-4) ...
                ' registered.png']);
            
            baselineMasked = baseline;
            baselineMasked(~binaryMask) = 0;
            registeredMasked = registered;
            registeredMasked(~binaryMask) = 0;
            
%             [u,v] = getoptflow(baselineMasked,registeredMasked);
%             [u,v] = getoptflow(baseline,registered);
%             imageflow = sqrt(u.^2 + v.^2);
            
            % downsize u and v
%             u_deci = u(1:10:end, 1:10:end);
%             v_deci = v(1:10:end, 1:10:end);
            % get coordinate for u and v in the original frame
%             [m, n] = size(baselineMasked);
%             [X,Y] = meshgrid(1:n, 1:m);
%             X_deci = X(1:10:end, 1:10:end);
%             Y_deci = Y(1:10:end, 1:10:end);
            diffImage = baselineMasked -registeredMasked; 
            diffImage = imgaussfilt(diffImage,4);
            diffImage(~binaryMask) = 255;
            imageseries=[imageseries, diffImage];
            binaryMaskSeries = [binaryMaskSeries, binaryMask];
            figure; imagesc(diffImage); colorbar; caxis([-0.05 0.05]);
            saveas(gcf, [data_path sub '\' dailyTiffsName{ix_img}(1:end-4) ' forheatmap.png']);
            fid=fopen([data_path sub '\' dailyTiffsName{ix_img}(1:end-4) ' forheatmap_FIJI.raw'],'w','b');
            fwrite(fid,diffImage,'float32');
            fclose(fid);
            figure; aaaa = flip(diffImage,1); surf(aaaa); shading interp;
            
            % Get coordinates of the boundary of the freehand drawn region.
            structBoundaries = bwboundaries(binaryMask);
            % First cell array is for left hemi
            xy=structBoundaries{1}; % Get n by 2 array of x,y coordinates.
            x = xy(:, 2); % Columns.
            y = xy(:, 1); % Rows.
            polyin = polyshape(x,y);
            %interiorL = polyin.isinterior(X_deci(:),Y_deci(:));
            binaryMaskL = roipoly(binaryMask, x, y);
            diffImageL = diffImage;
            diffImageL(~binaryMaskL) = 0;
            diffImageL(diffImageL < 0.007) = 0;
            % Second one is for right hemi
            xy=structBoundaries{2}; % Get n by 2 array of x,y coordinates.
            x = xy(:, 2); % Columns.
            y = xy(:, 1); % Rows.
            polyin = polyshape(x,y);
            %interiorR = polyin.isinterior(X_deci(:),Y_deci(:));
            binaryMaskR = roipoly(binaryMask, x, y);
            diffImageR = diffImage;
            diffImageR(~binaryMaskR) = 0;
            diffImageR(diffImageR < 0.007) = 0;

            
            imagefiles = [imagefiles; dailyTiffsName{ix_img}];
            totalswellL = [totalswellL; sum(diffImageL(:))];
            totalswellR = [totalswellR; sum(diffImageR(:))];
            maxswellL = [maxswellL; max(max(diffImageL))];
            maxswellR = [maxswellR; max(max(diffImageR))];
            
%             hold on;
            % draw the velocity vectors
%             quiver(X_deci(interiorL), Y_deci(interiorL), u_deci(interiorL),v_deci(interiorL), 'y')
%             quiver(X_deci(interiorR), Y_deci(interiorR), u_deci(interiorR),v_deci(interiorR), 'y')
            title(['Vessel movement: ' dailyTiffsName{ix_img}]);
            saveas(gcf, [data_path sub '\' dailyTiffsName{ix_img}(1:end-4) ' diff.png']);
            if runningbaseline
                %set baseline as current image
                baselineName = dailyTiffsName{ix_img};
                baseline = toRegister;
            end
        end
        
    end
    figure; imagesc(imageseries,'alphadata',imageseries ~= 255); colormap('jet'); 
    set(gcf, 'Position',  [100, 100, 200*length(dailyTiffsName), 200]);
    set(gca,'visible','off'); caxis([-0.05 0.02]); colorbar;
    saveas(gcf, [data_path sub '/imageseries.png']);
    totalswellL = cumsum(totalswellL);
    totalswellR = cumsum(totalswellR);
    maxswellL = cumsum(maxswellL);
    maxswellR = cumsum(maxswellR);
    
    fname=[sub '_swelling.csv'];
    writetable(cell2table([imagefiles num2cell(totalswellL) num2cell(totalswellR)...
        num2cell(maxswellL) num2cell(maxswellR)]), fname,'writevariablenames',1);
    figure; 
    subplot(121); plot(totalswellL); hold on; plot(totalswellR); 
    title('Progression of swelling'); 
    xlabel('time course'); ylabel('total optical flow(pixels)'); 
    legend('Left', 'Right'); axis tight; xticks([1:numel(imagefiles)]); 
    xticklabels(imagefiles); xtickangle(70);
    
    subplot(122); plot(maxswellL); hold on; plot(maxswellR);
    title('maximum swelling'); 
    xlabel('time course'); ylabel('max. optical flow(pixels)'); 
    legend('Left', 'Right'); axis tight; xticks([1:numel(imagefiles)]); 
    xticklabels(imagefiles); xtickangle(70);
    
    saveas(gcf, [data_path sub '/total optflow timecourse.png']);
    close all;
end

function img = image_clamp(img)
    c = img<-0.5;
    d = img>0.5;
    img(c) = 0;
    img(d) = 0;
end
