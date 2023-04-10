clear all
close all
t=0;
Area_limit=500;
data_filename = uigetdir;
path = strcat(data_filename,"\");
tif_files = dir(fullfile(path,'*.tif'));
l = length(tif_files);
frame_rate = 100;   %defining frame rate = 10,000 fps
bg_img = rgb2gray(imread(fullfile(path,tif_files(1).name)));
[rows ,cols ,~] = size(bg_img);
% ref_img = rgb2gray(imread(fullfile(path,tif_files(l).name)));
% [rows, columns, numberOfColorChannels] = size(ref_img);

spark = [];
k = 0;
dim = size(bg_img);
area = [];
spray_speed = [];   
coa = [];
cowfxp = [];
cowfyp = [];
cowfxn = [];
cowfyn = [];
area_speed = [];

for cnt = 1:l %replace by l to iterate 
    img{cnt} = imread(fullfile(path,tif_files(cnt).name));
    gray = rgb2gray(img{cnt});
    diff_img = gray - bg_img;
    diff_img = imfill(diff_img,'holes');
    diff_img = medfilt2(diff_img, [5 5]);
    BW = diff_img > 5;     %try making it user defined
    se90 = strel('line',1,90);
    se0 = strel('line',1,0);
    imgThresh = imdilate(BW,[se90 se0]);
    imgFilled = bwareaopen(imgThresh,30);
    imgFilled = imfill(imgFilled, 'holes');
    seD = strel('diamond',1);
    imgFilled = imerode(imgFilled,seD);
    BWfinal = imerode(imgFilled,seD);
    imshow(BWfinal)
    area = [area, spray_area(BWfinal)];
    cowfxp = [cowfxp; cord_of_sprayxpos(BWfinal)];
    cowfyp = [cowfyp; cord_of_sprayypos(BWfinal)];
    cowfxn = [cowfxn; cord_of_sprayxneg(BWfinal)];
    cowfyn = [cowfyn; cord_of_sprayyneg(BWfinal)];
    coa = [coa; center_of_area(BWfinal)];
    if cnt>1
        area_speed = [area_speed; (area(cnt)-area(cnt-1))/frame_rate];
    end
end
for i = 1:length(coa(:,1))
    if isnan(coa)
        a = spark;     %dhyaan dena lavde 115-135
    end
end
first_non_NaN_index_of_X = find(~isnan(coa(:,1)), 1, 'first');
spark(1) = coa(first_non_NaN_index_of_X ,1);
spark(2) = coa(first_non_NaN_index_of_X ,2);
% disp(spark)

speedxp = (cowfxp(2:end)-cowfxp(1:end-1))/frame_rate;    %- added to compensate negative sign
speedyp = (cowfyp(2:end)-cowfyp(1:end-1))/frame_rate;
speedxn = (cowfxn(2:end)-cowfxn(1:end-1))/frame_rate;    %- added to compensate negative sign
speedyn = (cowfyn(2:end)-cowfyn(1:end-1))/frame_rate;
figure(1)
plot(area)

figure(2)
hold on
subplot(2,2,1)
plot(speedxp)
subplot(2,2,2)
plot(speedyp)
subplot(2,2,3)
plot(speedxn)
subplot(2,2,4)
plot(speedyn)
hold off

figure(3)
plot(coa(:,2),coa(:,1))


figure(4)
plot(area_speed)

figure(5)
hold on
plot(abs(cowfxp-spark(1)))
plot(abs(cowfyp-spark(2)))
plot(abs(cowfxn-spark(1)))
plot(abs(cowfyn-spark(2)))
legend('+ve x','+ve y','-ve x','-ve y')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% area function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = spray_area(img)    
    area_calibration_factor  = 1;   %% dhyan dena lavde
    area = area_calibration_factor*(bwarea(img));  
    a = round(area,2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% center of area function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = center_of_area(img1)
    [y, x] = ndgrid(1:size(img1, 1), 1:size(img1, 2));
    a = mean([x(logical(img1)), y(logical(img1))]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% cord. of spray front function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = cord_of_sprayxpos(img1)
    [~, columns] = find(img1);
    a = max(columns);
end

function a = cord_of_sprayypos(img1)
    [rows, ~] = find(img1);
    a = min(rows);
end

function a = cord_of_sprayxneg(img1)
    [~, columns] = find(img1);
    a = min(columns);
end

function a = cord_of_sprayyneg(img1)
    [rows, ~] = find(img1);
    a = max(rows);
end