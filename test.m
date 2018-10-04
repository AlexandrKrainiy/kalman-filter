clear all; 
close all; 
clc 
%% Read video into MATLAB using aviread
video = VideoReader('18p5_2.AVI');
%'n' for calculating the number of frames in the video file
n =video.FrameRate*video.Duration;
% Calculate the background image by averaging the first 10 images
%imshow(imbkg);

CurrentTime1=0;
th=25;
for i=1:n
    CurrentTime1=video.CurrentTime;
    if(i<n-10)
          temp = zeros(video.Height,video.Width,3);
        [M,N] = size(temp(:,:,1));
        for ii = 1:10 
            temp = double(readFrame(video)) + temp;
        end
        imbkg = temp/10; 
        %imshow(imbkg);
        imbkg(find(imbkg>100))=255;
    end
    video.CurrentTime=CurrentTime1;
    close all;
     mframe=readFrame(video);
     figure;
      imshow(mframe);
      imcurrent = double(mframe);
      diffimg = (abs(imcurrent(:,:,1)-imbkg(:,:,1))>th) ...
           | (abs(imcurrent(:,:,2)-imbkg(:,:,2))>th) ...
           | (abs(imcurrent(:,:,3)-imbkg(:,:,3))>th);
      %figure;
     
    %  imshow(diffimg);
    BWs = edge(diffimg,'Canny',0.01);
    %figure, imshow(BWs), title('binary gradient mask');
    BWs = bwareaopen(BWs, 80);
    se90 = strel('line', 3, 90);
    se0 = strel('line', 3, 0);
    BWsdil = imdilate(BWs, [se90 se0]);
%     BW2 = bwmorph(BWs,'erode');
%     BW2 = bwmorph(BW2,'dilate');
%     BW2 = bwmorph(BW2,'dilate');
%     BWdfill = bwmorph(BW2,'dilate');
  %  figure, imshow(BWsdil), title('dilated gradient mask');
   % BW2=imadjust(BW2);

    BWnobord = imclearborder(BWsdil, 4);
%figure, imshow(BWnobord), title('cleared border image');
    BWdfill = imfill(BWnobord, 'holes');
    %figure, imshow(BWdfill);title('binary image with filled holes');
    
seD = strel('diamond',1);

BWfinal = imerode(BWdfill,seD);
% BWfinal = imerode(BWfinal,seD);
%figure, imshow(BWfinal), title('segmented image');
BWoutline = bwperim(BWfinal);
Segout = diffimg; 
Segout(BWoutline) = 255; 
Segout(find(BWoutline==0)) = 0; 
figure, imshow(Segout), title('outlined original image');
cc = bwconncomp(Segout, 18);
grain = false(size(Segout));
for j=1:length(cc.PixelIdxList)
grain(cc.PixelIdxList{j}) = true;

imshow(grain);
grain=midpoint(cc.PixelIdxList{j},grain);
grain = bwareaopen(grain, 30);
imshow(grain);
end
end
% Initialization step for Kalman Filter
% centroidx = zeros(n,1);
% centroidy = zeros(n,1);
% predicted = zeros(n,4);
% actual = zeros(n,4); 
% % % Initialize the Kalman filter parameters
% % R - measurement noise,
% % H - transform from measure to state
% % Q - system noise,
% % P - the status covarince matrix
% % A - state transform matrix
% 
% R=[[0.2845,0.0045]',[0.0045,0.0455]'];
% H=[[1,0]',[0,1]',[0,0]',[0,0]'];
% Q=0.01*eye(4);
% P = 100*eye(4);
% dt=1;
% A=[[1,0,0,0]',[0,1,0,0]',[dt,0,1,0]',[0,dt,0,1]']; 
% % loop over all image frames in the video
% kfinit = 0;
% th = 38;
% video.CurrentTime=0;
% for i=1:n
%    cdata=readFrame(video);
%   imshow(cdata);
%   hold on
%   imcurrent = double(cdata);
%   
%   % Calculate the difference image to extract pixels with more than 40(threshold) change
%   diffimg = zeros(M,N); 
%   diffimg = (abs(imcurrent(:,:,1)-imbkg(:,:,1))>th) ...
%       | (abs(imcurrent(:,:,2)-imbkg(:,:,2))>th) ...
%       | (abs(imcurrent(:,:,3)-imbkg(:,:,3))>th); 
%   % Label the image and mark
%   labelimg = bwlabel(diffimg,4);
%   markimg = regionprops(labelimg,['basic']);
%   [MM,NN] = size(markimg); 
%   % Do bubble sort (large to small) on regions in case there are more than 1
%   % The largest region is the object (1st one)
%   for nn = 1:MM
%       if markimg(nn).Area > markimg(1).Area
%           tmp = markimg(1);
%           markimg(1)= markimg(nn);
%           markimg(nn)= tmp;
%       end
%   end 
%   % Get the upper-left corner, the measurement centroid and bounding window size
%   bb = markimg(1).BoundingBox;
%   xcorner = bb(1);
%   ycorner = bb(2);
%   xwidth = bb(3);
%   ywidth = bb(4);
%   cc = markimg(1).Centroid;
%   centroidx(i)= cc(1);
%   centroidy(i)= cc(2); 
%   % Plot the rectangle of background subtraction algorithm -- blue
%   hold on
%   rectangle('Position',[xcorner ycorner xwidth ywidth],'EdgeColor','b');
%   hold on
%   plot(centroidx(i),centroidy(i), 'bx'); 
%   % Kalman window size
%   kalmanx = centroidx(i)- xcorner;
%   kalmany = centroidy(i)- ycorner; 
%   if kfinit == 0
%       % Initialize the predicted centroid and volocity
%       predicted =[centroidx(i),centroidy(i),0,0]' ;
%   else
%       % Use the former state to predict the new centroid and volocity
%       predicted = A*actual(i-1,:)';
%   end
%   kfinit = 1; 
%   Ppre = A*P*A' + Q;
%   K = Ppre*H'/(H*Ppre*H'+R);
%   actual(i,:) = (predicted + K*([centroidx(i),centroidy(i)]' - H*predicted))';
%   P = (eye(4)-K*H)*Ppre; 
%   % Plot the tracking rectangle after Kalman filtering -- red
%   hold on
% rectangle('Position',[(actual(i,1)-kalmanx) (actual(i,2)-kalmany) xwidth ywidth], 'EdgeColor', 'r','LineWidth',1.5);
%   hold on
%   plot(actual(i,1),actual(i,2), 'rx','LineWidth',1.5);
%   drawnow;


