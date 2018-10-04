
load('frameData.mat', 'frameData')
for i=1:length(frameData)
    a=0;
a=(frameData(i).fishesData(19).midline);
m{i}=a; %% midline of fish 19
end

clearvars -except m frameData

%% Read video into MATLAB using aviread


vid1=VideoReader('fishC.AVI');
numFrames = vid1.NumberOfFrames;
n=numFrames;
for i = 1:n
I = read(vid1,i);
I1 = rgb2gray(I);

imshow(I1) 
hold on
a=0;
a=m{i}
plot(a(:,1),a(:,2))
pause (0.1)
 
end