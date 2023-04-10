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
cowf =[];
area_speed = [];

for cnt = 1:l %replace by l to iterate 
    img = imread(fullfile(path,tif_files(cnt).name));
    gray = rgb2gray(img);
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
    area = [area, spray_area(BWfinal)];
    coa = [coa; center_of_area(BWfinal)];
    if cnt>1
        area_speed = [area_speed; (area(cnt)-area(cnt-1))/frame_rate];
    end
end

first_non_NaN_index_of_X = find(~isnan(coa(:,1)), 1, 'first');
spark(1) = coa(first_non_NaN_index_of_X ,1);
spark(2) = coa(first_non_NaN_index_of_X ,2);

disp(spark)
for i = 1:length(coa(:,1))
    if isnan(coa(i,1))
        coa(i,1) = spark(1);     %dhyaan dena lavde 115-135
        coa(i,2) = spark(2);
    end
end

spark(1) = floor(spark(1));
spark(2) = floor(spark(2));
ad = cols-spark(2);
bd = rows-spark(1);
if ad>=bd
    radi = floor(bd);
else
    radi = floor(ad);
end
radius = linspace(0,radi,radi+1);
z1 = [];
for cnt = 1:l %replace by l to iterate 
    img = imread(fullfile(path,tif_files(cnt).name));
    gray = rgb2gray(img);
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
    BWfinal = edge(BWfinal,'sobel');
    imshow(BWfinal)
    for i = 1:360
        x1 = round(radius*cosd(i));
        y1 = round(radius*sind(i));
        pc = floor(spark(1))+x1;
        pr = floor(spark(2))+y1;
        z =[];
        for j = 1:length(pc)
            z = [z;BWfinal(pr(j),pc(j))];
        end
        ch = find(z==1);
        if isempty(ch) 
            z1(i,cnt) = 0;
        end
        if length(ch) == 1
            z1(i,cnt) = ch(1);
        elseif length(ch) == 2
            if i==180
%             z1(360,cnt) = ch(1);
            z1(i,cnt) = ch(2);
            else
%             z1(abs(i-180),cnt) = ch(1);
            z1(i,cnt) = ch(2);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ploting the data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
zog = z1;
z1a = z1(:,1:end-1);
z1b = z1(:,2:end);
z1diff = (z1b-z1a)/0.1;
E = zeros(360,1);
z1 = [z1diff';E'];
z1 = z1';
x = [];
y = [];
z2 = z1(:);

for i = 1:l
    for j = 1:360
        x = [x; i*cosd(j)];
        y = [y; i*sind(j)];
    end
end
N = l;
xvec = linspace(min(x), max(x), N);
yvec = linspace(min(y), max(y), N);
[X, Y] = ndgrid(xvec, yvec);
F = scatteredInterpolant(x, y, z2);
Z = F(X, Y);
figure(1)
surf(X, -Y, Z,'EdgeColor','none');
colormap("hsv");
view(0,90)
colorbar
figure(2)
surf(X, -Y, Z,'EdgeColor','none');
figure(3)
contourf(X, -Y, Z,'EdgeColor','none');
colormap;

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
