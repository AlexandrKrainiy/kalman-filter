%% the program for fish counting
function fishcounting()
clc; clear all; close all;
%%
frame = [];
utilities.videoReader = vision.VideoFileReader('fishC.AVI');
utilities.videoPlayer = vision.VideoPlayer('Position', [100,100,500,400]);
%utilities = createUtilities(param);
  while ~isDone(utilities.videoReader)
    frame = readFrame();
    gray_IMG = rgb2gray(frame);
%     Adt_Img  = imadjust(gray_IMG); 
%     Adt_Img = imgaussfilt(Adt_Img);
    [~, threshold] = edge(gray_IMG, 'sobel');
    fudgeFactor = 0.4;
    BWs = edge(gray_IMG,'sobel', threshold * fudgeFactor);
    
    se90 = strel('line', 2, 90);
    se0 = strel('line', 5, 0);
    BWsdil = imdilate(BWs, [se90 se0]);
    
    BWnobord = imclearborder(BWsdil, 4);
    BWnobord1 = bwareaopen(BWnobord, 50);
    
    %figure, imshow(BWnobord1);
    BWsdil =BWnobord1;
    BWdfill = imfill(BWsdil, 'holes');

    seD = strel('diamond',1);
     BWfinal = imerode(BWdfill,seD);
    
     BWnobord = bwareaopen(BWfinal, 100);
     
    se = strel('line',3,3);
    % BWfinal = imdilate(BWnobord,se);
    BWfinal = BWnobord;
   % imshow(BWfinal);
    BWoutline = bwperim(BWfinal);
    [row, col] = find(BWoutline==1);
    for i = 1:length(row)
        frame(row(i),col(i),1) = 0; frame(row(i),col(i),2) = 255; frame(row(i),col(i),3) = 0;
    end
    
    BWnobord = bwmorph(logical(BWfinal),'thin',Inf);
    [row, col] = find(BWnobord==1);
    
    for i = 1:length(row)
        frame(row(i),col(i),1) = 255; frame(row(i),col(i),2) = 0; frame(row(i),col(i),3) = 0;
    end
    
    step(utilities.videoPlayer, frame);
  end

  
  function frame = readFrame()
      frame = step(utilities.videoReader);
   end
end