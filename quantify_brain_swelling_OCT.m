clear;
close all;

%list all the subjects to be processed
data_path = './';
sub_list = {'oct1'};
regmethod = 1;
runningbaseline = 0;

for i = 1:length(sub_list)
    
    sub = sub_list{i};
    
    tiffStack = dir([data_path sub '/*.tif']);
    tiffStackName = tiffStack.name;
    
    baseline  = imread([data_path sub '/' tiffStackName],1);

    %baseline = image_clamp(baseline);
    %baseline = imgaussfilt(baseline,2);
    
    imagefiles = {};
    totalswellL = [];
    maxswellL = [];

    % Create a mask if does not exist
    maskPath = [data_path sub '/baseline mask.png'];
    if exist(maskPath, 'file') == 2
        binaryMask = imread(maskPath);
    else
        binaryMask = getmask(baseline);
        imwrite(binaryMask, maskPath)
    end
    
    stackInfo = imfinfo([data_path sub '/' tiffStackName]);
    num_images = numel(stackInfo);
    imageseries = [];
    for k = 2:num_images
        
        
        
        close all;
        fprintf('\t registering stack: %d\n', k);
        toRegister = imread([data_path sub '/' tiffStackName], k);
        %toRegister = image_clamp(toRegister);
        %toRegister = imgaussfilt(toRegister,4);
        figure; imshowpair(baseline, toRegister,'Scaling','joint');
        tform = registrationbank(toRegister, baseline, regmethod);

        registered = imwarp(toRegister,tform,'OutputView',imref2d(size(baseline)));

        figure; imshowpair(baseline, registered,'Scaling','joint');
        title(['Stack ' num2str(k-1) ' + Stack ' num2str(k)]);
%         saveas(gcf, [data_path sub '/' 'Stack' num2str(k-1) ' + Stack' num2str(k) ' registered.png']);

        baselineMasked = baseline;
        baselineMasked(~binaryMask) = 0;
        registeredMasked = registered;
        registeredMasked(~binaryMask) = 0;

            [u,v] = getoptflow(baselineMasked,registeredMasked);
            [u,v] = getoptflow(baseline,registered);
            imageflow = sqrt(u.^2 + v.^2);

        % downsize u and v
            u_deci = u(1:10:end, 1:10:end);
            v_deci = v(1:10:end, 1:10:end);
        % get coordinate for u and v in the original frame
            [m, n] = size(baselineMasked);
            [X,Y] = meshgrid(1:n, 1:m);
            X_deci = X(1:10:end, 1:10:end);
            Y_deci = Y(1:10:end, 1:10:end);
        diffImage = baselineMasked -registeredMasked; 
        diffImage = imgaussfilt(diffImage,4);
        diffImage(~binaryMask) = 0;
        imageseries = [imageseries, diffImage];
%         figure; imagesc(diffImage); colorbar; caxis([-0.05 0.05]);
        
%         figure; aaaa = flip(diffImage,1); surf(aaaa); shading interp;

        % Get coordinates of the boundary of the freehand drawn region.
        structBoundaries = bwboundaries(binaryMask);
        % First cell array is for left hemi
        xy=structBoundaries{1}; % Get n by 2 array of x,y coordinates.
        x = xy(:, 2); % Columns.
        y = xy(:, 1); % Rows.
        polyin = polyshape(x,y);
        interiorL = polyin.isinterior(X_deci(:),Y_deci(:));
        binaryMaskL = roipoly(binaryMask, x, y);
        diffImageL = diffImage;
        diffImageL(~binaryMaskL) = 0;
        diffImageL(diffImageL < 0.007) = 0;

        imagefiles = [imagefiles;  'Stack' num2str(k-1) ' + Stack' num2str(k)];
        totalswellL = [totalswellL; sum(diffImageL(:))];
        maxswellL = [maxswellL; max(max(diffImageL))];

        hold on;
        % draw the velocity vectors
        quiver(X_deci(interiorL), Y_deci(interiorL), u_deci(interiorL),v_deci(interiorL), 'y')
%             quiver(X_deci(interiorR), Y_deci(interiorR), u_deci(interiorR),v_deci(interiorR), 'y')
        title(['Vessel movement: '  'Stack' num2str(k-1) ' + Stack' num2str(k)]);
        saveas(gcf, [data_path sub '/'  'Stack' num2str(k-1) ' + Stack' num2str(k) ' diff.png']);
        if runningbaseline
            %set baseline as current image
            baseline = toRegister;
        end
    end
    
    totalswellL = cumsum(totalswellL);
    maxswellL = cumsum(maxswellL);
    
    fname=[sub '_swelling.csv'];
    writetable(cell2table([imagefiles num2cell(totalswellL) ...
        num2cell(maxswellL)]), fname,'writevariablenames',1);
    figure; 
    subplot(121); plot(totalswellL);
    title('Progression of swelling'); 
    xlabel('time course'); ylabel('total optical flow(pixels)'); 
    axis tight; xticks([1:numel(imagefiles)]); 
    xticklabels(imagefiles); xtickangle(70);
    
    subplot(122); plot(maxswellL)
    title('maximum swelling'); 
    xlabel('time course'); ylabel('max. optical flow(pixels)'); 
    axis tight; xticks([1:numel(imagefiles)]); 
    xticklabels(imagefiles); xtickangle(70);
    
    saveas(gcf, [data_path sub '/total optflow timecourse.png']);
end

function img = image_clamp(img)
    c = img<-0.5;
    d = img>0.5;
    img(c) = 0;
    img(d) = 0;
end
