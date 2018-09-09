function [u,v] = getoptflow(fr1,fr2)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
im1t = im2double(fr1);
im1 = imresize(im1t, 0.5); % downsize to half
im2t = im2double(fr2);
im2 = imresize(im2t, 0.5); % downsize to half

ww = 20;
w = round(ww/2);

% Lucas Kanade Here
% for each point, calculate I_x, I_y, I_t
Ix_m = conv2(im1,[-1 1; -1 1], 'valid'); % partial on x
Iy_m = conv2(im1, [-1 -1; 1 1], 'valid'); % partial on y
It_m = conv2(im1, ones(2), 'valid') + conv2(im2, -ones(2), 'valid'); % partial on t
u = zeros(size(im1));
v = zeros(size(im2));

% within window ww * ww
for i = w+1:size(Ix_m,1)-w
   for j = w+1:size(Ix_m,2)-w
      Ix = Ix_m(i-w:i+w, j-w:j+w);
      Iy = Iy_m(i-w:i+w, j-w:j+w);
      It = It_m(i-w:i+w, j-w:j+w);

      Ix = Ix(:);
      Iy = Iy(:);
      b = -It(:); % get b here

      A = [Ix Iy]; % get A here
      nu = pinv(A)*b; % get velocity here

      u(i,j)=nu(1);
      v(i,j)=nu(2);
   end
end


end

