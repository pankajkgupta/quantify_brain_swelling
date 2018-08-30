function [binaryImage] = getmask(grayImage)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% Read in standard MATLAB gray scale demo image.
fontSize = 16;
figure('units','normalized','outerposition',[0 0 1 1]); subplot(1, 2, 1);
imshow(grayImage, []);
title('Original Grayscale Image', 'FontSize', fontSize);
binaryImage = zeros(size(grayImage));
while true
    while true
        message = sprintf('Left click and hold to begin drawing one hemi-sphere.\nSimply lift the mouse button to finish');
        uiwait(msgbox(message));
        hFH = imfreehand();
        dlgTitle    = 'Mask looks okay?';
        dlgQuestion = 'The mask looks right?';
        choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
        if strcmp(choice, 'Yes')
            % Create a binary image ("mask") from the ROI object.
            binaryImage = binaryImage + hFH.createMask();
            break;
        else
            hFH.delete;
        end
    end
    dlgTitle    = 'Draw more?';
    dlgQuestion = 'Do you want to draw more regions?';
    choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
    if strcmp(choice, 'No')
        break;
    end
end

% Get coordinates of the boundary of the freehand drawn region.
% structBoundaries = bwboundaries(binaryImage);
% xy=structBoundaries{1}; % Get n by 2 array of x,y coordinates.
% x = xy(:, 2); % Columns.
% y = xy(:, 1); % Rows.
% hold on; % Don't blow away the image.
% plot(x, y, 'LineWidth', 2);
% drawnow; % Force it to draw immediately.

% Mask the image and display it.
% Will keep only the part of the image that's inside the mask, zero outside mask.
blackMaskedImage = grayImage;
blackMaskedImage(~binaryImage) = 0;
subplot(1, 2, 2);
imshow(blackMaskedImage);
title('Masked Outside Region', 'FontSize', fontSize);
end

