%% Motion-Based Multiple Object Tracking

function multiObjectTracking1()

obj = setupSystemObjects();
tracks = initializeTracks(); % Create an empty array of tracks.
nextId = 1; % ID of the next track

% Detect moving objects, and track them across video frames.
while ~isDone(obj.reader)
    frame = readFrame(); 
    [centroids,bboxes,frame] = detectObjects(frame);
    predictNewLocationsOfTracks();
    [assignments, unassignedTracks, unassignedDetections] =  detectionToTrackAssignment();
    
    updateAssignedTracks();
    updateUnassignedTracks();
    deleteLostTracks();
    createNewTracks();
    
    displayTrackingResults();
end


%% Create System Objects
    function obj = setupSystemObjects()
        obj.reader = vision.VideoFileReader('10p5_3_1.AVI');
        % obj.reader = vision.VideoFileReader('fish2.avi');
        obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.maskPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.detector = vision.ForegroundDetector('NumGaussians', 3,     'NumTrainingFrames', 5, 'MinimumBackgroundRatio', 0.4);
        obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true,    'AreaOutputPort', true, 'CentroidOutputPort', true,   'MinimumBlobArea', 100);
    end

%% Initialize Tracks
    function tracks = initializeTracks()
        % create an empty array of tracks
        tracks = struct(...
            'id', {}, ...
            'kalmanFilter', {}, ...
             'bbox', {}, ...
            'age', {}, ...
            'totalVisibleCount', {}, ...
            'consecutiveInvisibleCount', {});
    end

%% Read a Video Frame
% Read the next video frame from the video file.
    function frame = readFrame()
        frame = obj.reader.step();
    end

%% Detect Objects
    function [centroids, bboxes,frame1] = detectObjects(frame)
             gray_IMG = rgb2gray(frame);
            gray_IMG=imgaussfilt( imadjust(gray_IMG));
            [~, threshold] = edge(gray_IMG, 'sobel');
            fudgeFactor = 0.6;
            BWs = edge(gray_IMG,'sobel', threshold * fudgeFactor);

            se90 = strel('line', 2, 90);
            se0 = strel('line', 2, 0);
            BWsdil = imdilate(BWs, [se90 se0]);

            BWnobord = imclearborder(BWsdil, 4);
            BWnobord1 = bwareaopen(BWnobord, 200);
            %imshow(BWnobord1);
           
            BWsdil =BWnobord1;
            BWdfill = imfill(BWsdil, 'holes');

            seD = strel('disk',3);
            BWfinal = imerode(BWdfill,seD);
            BWfinal = imdilate(BWfinal, seD);
            BWnobord = bwareaopen(BWfinal, 100);
            BWfinal = BWnobord;
            BWoutline = bwperim(BWfinal);
       % imshow(BWoutline);
          %%
            [row, col] = find(BWoutline==1);
            for i = 1:length(row)
                frame(row(i),col(i),:) = [0,255,0]; %frame(row(i),col(i),2) = 255; frame(row(i),col(i),3) = 0;
            end

            BWnobord = bwmorph(logical(BWfinal),'thin',Inf);
            [row, col] = find(BWnobord==1);
            for i = 1:length(row)
                frame(row(i),col(i),:) =[ 255,0,0]; %frame(row(i),col(i),2) = 0; frame(row(i),col(i),3) = 0;
            end
         %%
            individual_fish = regionprops(BWfinal,'centroid');
            centroids = cat(1, individual_fish.Centroid);
            bboxes = centroids;
            frame1=frame;
    end

%% Predict New Locations of Existing Tracks
% Use the extended Kalman filter to predict the centroid of each track in the
% current frame, and update its bounding box accordingly.
    function predictNewLocationsOfTracks()
        for i = 1:length(tracks)
            bbox = tracks(i).bbox;
            
            % Predict the current location of the track.
            predictedCentroid = predict(tracks(i).kalmanFilter);
            
            % Shift the bounding box so that its center is at 
            % the predicted location.
            predictedCentroid = int32(predictedCentroid);
            tracks(i).bbox = [predictedCentroid];
        end
    end

%% Assign Detections to Tracks
    function [assignments, unassignedTracks, unassignedDetections] = detectionToTrackAssignment()        
        nTracks = length(tracks);
        nDetections = size(centroids, 1);        
                             % Compute the cost of assigning each detection to each track.
        cost = zeros(nTracks, nDetections);
        for i = 1:nTracks
            cost(i, :) = distance(tracks(i).kalmanFilter, centroids);
        end        
                    % Solve the assignment problem.
        costOfNonAssignment = 20;
        [assignments, unassignedTracks, unassignedDetections] = ...
        assignDetectionsToTracks(cost, costOfNonAssignment);
    end

%% Update Assigned Tracks
    function updateAssignedTracks()
        numAssignedTracks = size(assignments, 1);
        for i = 1:numAssignedTracks
            trackIdx = assignments(i, 1);
            detectionIdx = assignments(i, 2);
            centroid = centroids(detectionIdx, :);
            bbox = bboxes(detectionIdx, :);
            
                       % Correct the estimate of the object's location
                       % using the new detection.
            correct(tracks(trackIdx).kalmanFilter, centroid);            
                            % Replace predicted bounding box with detected
                            % bounding box.
            tracks(trackIdx).bbox = bbox;            
                          % Update track's age.
            tracks(trackIdx).age = tracks(trackIdx).age + 1;
            
                       % Update visibility.
            tracks(trackIdx).totalVisibleCount =  tracks(trackIdx).totalVisibleCount + 1;
            tracks(trackIdx).consecutiveInvisibleCount = 0;
        end
    end

%% Update Unassigned Tracks
% Mark each unassigned track as invisible, and increase its age by 1.
    function updateUnassignedTracks()
        for i = 1:length(unassignedTracks)
            ind = unassignedTracks(i);
            tracks(ind).age = tracks(ind).age + 1;
            tracks(ind).consecutiveInvisibleCount = ...
                tracks(ind).consecutiveInvisibleCount + 1;
        end
    end

%% Delete Lost Tracks
% The |deleteLostTracks| function deletes tracks that have been invisible
% for too many consecutive frames. It also deletes recently created tracks
% that have been invisible for too many frames overall. 

    function deleteLostTracks()
        if isempty(tracks)
            return;
        end
        
        invisibleForTooLong = 20;
        ageThreshold = 8;
        
        % Compute the fraction of the track's age for which it was visible.
        ages = [tracks(:).age];
        totalVisibleCounts = [tracks(:).totalVisibleCount];
        visibility = totalVisibleCounts ./ ages;
        
        % Find the indices of 'lost' tracks.
        lostInds = (ages < ageThreshold & visibility < 0.6) |    [tracks(:).consecutiveInvisibleCount] >= invisibleForTooLong;
        
        % Delete lost tracks.
        tracks = tracks(~lostInds);
    end

%% Create New Tracks
% Create new tracks from unassigned detections. Assume that any unassigned
% detection is a start of a new track. In practice, you can use other cues
% to eliminate noisy detections, such as size, location, or appearance.
    function createNewTracks()
        centroid1 = centroids(unassignedDetections, :);
        bboxes = bboxes(unassignedDetections, :);
        
        for i = 1:size(centroid1, 1)            
            centroid = centroid1(i,:);
            bbox = bboxes(i, :);
            
            % Create a Kalman filter object.
            kalmanFilter = configureKalmanFilter('ConstantVelocity',  centroid, [200, 50], [100, 25], 100);

            % Create a new track.
            newTrack = struct( 'id', nextId,  'kalmanFilter', kalmanFilter,  'bbox', bbox,  'age', 1,  'totalVisibleCount', 1,   'consecutiveInvisibleCount', 0);
            
            % Add it to the array of tracks.
            tracks(end + 1) = newTrack;
            
            % Increment the next id.
            nextId = nextId + 1;
        end
    end

%% Display Tracking Results
% The |displayTrackingResults| function draws a bounding box and label ID for each track on the video frame and the foreground mask. It then displays the frame and the mask in their respective video players. 

    function displayTrackingResults()
        frame = im2uint8(frame);
        %mask = uint8(repmat(mask, [1, 1, 3])) .* 255;
        
        minVisibleCount = 8;
        if ~isempty(tracks)
            reliableTrackInds = [tracks(:).totalVisibleCount] > minVisibleCount;
            reliableTracks = tracks(reliableTrackInds);
             if ~isempty(reliableTracks)
                % Get bounding boxes.
                bboxes = cat(1, reliableTracks.bbox);
                
                % Get ids.
                ids = int32([reliableTracks(:).id]);
                
                % Create labels for objects indicating the ones for which we display the predicted rather than the actual location.
                labels = cellstr(int2str(ids'));
                predictedTrackInds = [reliableTracks(:).consecutiveInvisibleCount] > 0;
                isPredicted = cell(size(labels));
                isPredicted(predictedTrackInds) = {'pre'};
                labels = strcat(labels, isPredicted);
                
                % Draw the objects on the frame.
                region =bboxes;
                region(:, 3) = 5;
                frame = insertObjectAnnotation(frame, 'circle',  region, labels,'Color', 'blue');               
               
            end
        end
        
        % Display the mask and the frame.
        %obj.maskPlayer.step(mask);        
        obj.videoPlayer.step(frame);
    end

displayEndOfDemoMessage(mfilename)
end



