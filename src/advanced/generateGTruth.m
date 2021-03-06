% Script to generate ground truth from the MSRA dataset
% Adding the paths
addpaths;

% Visualizing the results
visualize = false;

% Reading the images in the training folder
trainImgPath = '../../MSRA-TD500/train/%s';
trainImgs = dir(sprintf(trainImgPath, '*.JPG'));

noImgs = length(trainImgs);
%count = 1; % number of lines used for training

% Parfor cannot save/write independently
posData = cell(noImgs, 1);
negData = cell(noImgs, 1);
textline = cell(noImgs, 1);
posCount = ones(noImgs, 1);
negCount = ones(noImgs, 1);

parfor i = 1:noImgs
    % Reading each image
    imagePath = sprintf(trainImgPath, trainImgs(i).name);
    image = imread(imagePath);

    % Reading the ground truth for the image
    trainLabelPath = strrep(imagePath, '.JPG', '.gt');

    % Checking if the file is empty and skipping it if it is
    fileData = dir(trainLabelPath);

    if(fileData.bytes ~= 0)
        labels = dlmread(trainLabelPath);

        % Visualizing the bounding boxes 
        ptMarker = vision.MarkerInserter('Shape','Circle','Fill', true, 'Size', 5, ...
                        'FillColor', 'Custom', 'CustomFillColor', uint8([255 0 0]));

        centerMarker = vision.MarkerInserter('Shape','Circle','Fill', true, 'Size', 5, ...
                        'FillColor', 'Custom', 'CustomFillColor', uint8([0 0 255]));
        
        drawImage = image;

        % Trasforming the points
        centerPts = labels(:, 3:4)  + labels(:, 5:6) * 0.5;

        drawPts = [];
        tic;
        for j = 1:size(centerPts, 1)
            % Angle of rotation
            angle =  -1 * labels(j, 7);
            % Rotation matrix
            R = [cos(angle), sin(angle); -sin(angle), cos(angle)];

            centerPt = centerPts(j, :);
            shifts = 0.5 * labels(j, 5:6);
            % Getting four corners of the cannonical box
            corners = [[1, 1] .* shifts; [-1, 1] .* shifts; ...
                       [-1 -1] .* shifts; [1 -1].*shifts];  
            
            % Rotating the corners and translate to the center
            corners = bsxfun(@plus, (R * corners')',  centerPt);
            
            if(visualize)
                % Drawing the points
                drawPts = [drawPts; corners];
            end

            % Bounding box for the component (minRow, maxRow, minCol, maxCol) format
            box = floor([min(corners(:,2)), max(corners(:,2)), min(corners(:,1)), max(corners(:, 1))]);

            % Clipping the bounding box co-ordinates
            box = [max(1, box(1)), min(box(2), size(image, 1)), ...
                    max(1, box(3)), min(box(4), size(image, 2))];

            % Extracting the subimage
            subImg = image(box(1):box(2), box(3):box(4), :);

            % Get swt image, components and component features
            swtImg = swtransform(subImg, true);
            rawComponents = connectedComponents(swtImg, 3.2);
            [components, bboxes] = filterComponents(swtImg, rawComponents);
            compFeat = evaluateComponentFeatures(subImg, swtImg, components, bboxes);

            % Saving the component and its features for a text
            % Identifier
            textline{i}.imageName = trainImgs(i).name;
            textline{i}.id = i;

            textline{i}.swtImg = swtImg;
            textline{i}.rawComponents = uint8(rawComponents);
            textline{i}.components = uint8(components); 
            textline{i}.bboxes = bboxes;
            textline{i}.compFeat = compFeat;
            textline{i}.range = box;

            % Saving the component features
            posData{i}{posCount(i)} = textline{i};
            posCount(i) = posCount(i) + 1;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Other direction of the gradient
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Get swt image, components and component features
            swtImg = swtransform(subImg, false);
            rawComponents = connectedComponents(swtImg, 3.2);
            [components, bboxes] = filterComponents(swtImg, rawComponents);
            compFeat = evaluateComponentFeatures(subImg, swtImg, components, bboxes);

            % Saving the component and its features for a text
            % Identifier
            textline{i}.imageName = trainImgs(i).name;
            textline{i}.id = i;

            textline{i}.swtImg = swtImg;
            textline{i}.rawComponents = uint8(rawComponents);
            textline{i}.components = uint8(components); 
            textline{i}.bboxes = bboxes;
            textline{i}.compFeat = compFeat;
            textline{i}.range = box;

            % Saving the component features
            posData{i}{posCount(i)} = textline{i};
            posCount(i) = posCount(i) + 1;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Generating negative training examples
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % randomly taking a sub image
            %[1, size(image,1) - (box(2) - box(1) + 1)]
            %[1, size(image,2) - (box(4) - box(3) + 1)]
            minRow = randi([1, size(image,1) - (box(2) - box(1))]);
            minCol = randi([1, size(image,2) - (box(4) - box(3))]);
            
            subImg = image(minRow:(minRow + box(2) - box(1)), ...
                    minCol:(minCol + box(4) - box(3)), :);
            
            swtImg = swtransform(subImg, true);
            rawComponents = connectedComponents(swtImg, 3.2);
            [components, bboxes] = filterComponents(swtImg, rawComponents);
            compFeat = evaluateComponentFeatures(subImg, swtImg, components, bboxes);

            % Saving the component and its features for a text
            % Identifier
            textline{i}.imageName = trainImgs(i).name;
            textline{i}.id = i;

            textline{i}.swtImg = swtImg;
            textline{i}.rawComponents = uint8(rawComponents);
            textline{i}.components = uint8(components); 
            textline{i}.bboxes = bboxes;
            textline{i}.compFeat = compFeat;
            textline{i}.range = [minRow, minRow + box(2) - box(1), ...
                    minCol, minCol + box(4) - box(3)];

            % Saving the component features
            negData{i}{negCount(i)} = textline{i};
            negCount(i) = negCount(i) + 1;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            minRow = randi([1, size(image,1) - (box(2) - box(1))]);
            minCol = randi([1, size(image,2) - (box(4) - box(3))]);
            
            subImg = image(minRow:(minRow + box(2) - box(1)), ...
                    minCol:(minCol + box(4) - box(3)), :);
            
            swtImg = swtransform(subImg, false);
            rawComponents = connectedComponents(swtImg, 3.2);
            [components, bboxes] = filterComponents(swtImg, rawComponents);
            compFeat = evaluateComponentFeatures(subImg, swtImg, components, bboxes);

            % Saving the component and its features for a text
            % Identifier
            textline{i}.imageName = trainImgs(i).name;
            textline{i}.id = i;

            textline{i}.swtImg = swtImg;
            textline{i}.rawComponents = uint8(rawComponents);
            textline{i}.components = uint8(components); 
            textline{i}.bboxes = bboxes;
            textline{i}.compFeat = compFeat;
            textline{i}.range = [minRow, minRow + box(2) - box(1), ...
                    minCol, minCol + box(4) - box(3)];

            % Saving the component features
            negData{i}{negCount(i)} = textline{i};
            negCount(i) = negCount(i) + 1;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %figure(1); imagesc(components)
            %figure(2); imagesc(rawComponents)
            %pause(1)
        end

        time= toc;
        fprintf('Training : %d / %d in %f sec\n', i, noImgs, time);

        if visualize
            drawImage = step(centerMarker, drawImage, uint32(centerPts));
            drawImage = step(ptMarker, drawImage, uint32(drawPts));

            figure(2); imshow(drawImage)
            pause(3);
        end
    end
end

% Merging the training data
mergedTrainingData = {};
for i = 1:noImgs
    mergedTrainingData = [mergedTrainingData, posData{i}];
end
posData = mergedTrainingData;

mergedTrainingData = {};
for i = 1:noImgs
    mergedTrainingData = [mergedTrainingData, negData{i}];
end
negData = mergedTrainingData;

save('trainingDataAll.mat', 'posData', 'negData');
