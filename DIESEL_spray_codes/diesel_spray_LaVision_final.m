clear all
close all
warning('off')
t=0;
Area_limit=500;
r = [0,0,0,0];
r1 = 0;
%%%%%%%%%%%%%%%%%%%%%%%%% taking input %%%%%%%%%%%%%%%%%%%%%%%%%
prompt = {'Enter length calibration factor (mm/pixel)','Enter frame rate in f.p.s.','Enter threshold senstivity'};
dlgtitle = 'Input';
dims = [1 50];
definput = {'0.1','20000','800'};  %(197/7.5)^-1 as provided
answer = inputdlg(prompt,dlgtitle,dims,definput);
calibration_factor = str2double(answer(1));
frame_rate = str2double(answer(2));
rcor = str2double(answer(3));
area_cal_fac = calibration_factor*calibration_factor;
frame_rate = frame_rate/1000; %frames per milli second
frame_rate = 1/frame_rate;

data_filename = uigetdir; % filename for all folders
topLevelFolder = data_filename;  % Get a list of all files and folders in this folder.
files = dir(topLevelFolder);    % Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];   % Extract only those that are directories.
subFolders = files(dirFlags);   % A structure with extra info. Get only the folder names into a cell array.
subFolderNames = {subFolders(3:end).name}; % Start at 3 to skip . and ..
xcl = strcat(data_filename,'\results2.xlsx'); 
l2 = length(subFolderNames);

name_arr1 = ["time(ms)","area(mm2)","penetration length(mm)","speed pen(mm/ms)","Cone Angle(CA) /2","Cone Angle(CA) /3"];
name_arr_avg = ["Average time(ms)","Average area(mm2)","Average penetration len","Average Speed","Average CA /2","Average CA /3"];
name_arr_std = ["std time(ms)","std area(mm2)","std penet. len","std pen.speed","std CA /2","std CA /3"];
count = 1;

for index = 1:l2
    blsh = '\';
    path = strcat(data_filename,blsh,subFolderNames(index));
    path = string(path);
    tif_files = dir(fullfile(path,'*.tif'));
    l = length(tif_files);

    destdirectory1 = strcat(path,'\processed BW');
    destdirectory3 = strcat(path,'\processed edge');
    destdirectory2 = strcat(path,'\processed contour');
    mkdir(destdirectory1); %create the directory
    mkdir(destdirectory2);
    mkdir(destdirectory3);

    nozz = [];
    area = [];
    coa = [];
    xp = [];
    CA2 = [];
    CA3 = [];
    t = [];
    tc = 0;
    injection_frame = 0;
    bg_img = imread(fullfile(path,tif_files(1).name));
    bg_img1 = bg_img>rcor;
    [rows ,cols ,~] = size(bg_img);
    se = strel('disk',3);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Writing data in excel sheets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    nn = string(subFolderNames(index));
    nn = convertStringsToChars(nn);
    if ((nn(end) == "1") && (index ~= 1))
        matstd = std(matf,0,3);
        matavg = sum(matf,3);
        matavg = matavg/(count-1);
        matavg = array2table(matavg,'VariableNames',name_arr_avg);
        matstd = array2table(matstd,"VariableNames",name_arr_std);
        sheet = string(subFolderNames(index-1));
        sheet = strrep(sheet,'.','_');
        chr = convertStringsToChars(sheet);
        if (length(chr) > 29)
            sheet = string(chr(1:30));
        end
        mattoprin =[];
        lt1 = [];
        for i = 1:count-1
            name_arr = "";
            for j = 1:6
                name_arr(j) = strcat(name_arr1(j)," data ",num2str(i));
            end
            matp = matf(:,:,i);
            ltt = length(matp(:,1));
            matp = array2table(matp,'VariableNames',name_arr);
            lt1 = zeros(ltt,1);
            lt1 = lt1 + 32;
            lt1 = char(lt1);
            lt1 = array2table(lt1,'VariableNames',string(num2str(i)));
            mattoprin = [mattoprin matp lt1];
        end
        lt1 = zeros(ltt,1);
        lt1 = lt1 + 32;
        lt1 = char(lt1);
        lt1 = array2table(lt1,'VariableNames',string(num2str(50)));
        mattoprin = [mattoprin matavg lt1 matstd];
        writetable(mattoprin,xcl,'Sheet',sheet,"WriteMode","overwritesheet");
        count = 1;
        matf = [];
        disp("........................sheet completed........................")
    end
    co = 1;
    for cnt = 2:l
        img = imread(fullfile(path,tif_files(cnt).name));
        img1 = img;
        img = bg_img-img;
        img = img>1000;
        i = find(img, 1);
        if (~isempty(i)) && (co == 1)
            injection_frame = cnt;
%             disp(injection_frame);
            nozz(1) = cord_of_sprayxpos(img);
            nozz(2) = (cord_of_sprayypos(img)+cord_of_sprayyneg(img))/2;
            co = 0;
        end
        img1 = bg_img - img1;
        img1b = img1>rcor;
        area = [area; area_cal_fac*bwarea(img1b)];
        coa = [coa; center_of_area(img1b)];
    end
    for i = 1:length(coa(:,1))
        if isnan(coa(i,1))
            coa(i,1) = nozz(1);
            coa(i,2) = nozz(2);
        end
    end
    x1 = coa(:,1);
    y1 = coa(:,2);
    area = area(injection_frame:end);
    x1 = x1(injection_frame:end-300); %%%%%%%%%%%%% CHECK BEFORE RUNNING %%%%%%%%%%%%%
    y1 = y1(injection_frame:end-300); %%%%%%%%%%%%% CHECK BEFORE RUNNING %%%%%%%%%%%%%
    c = polyfit(x1,y1,1);
    theta = atand(c(1));

    img = imread(fullfile(path,tif_files(injection_frame).name));
    gray3 = bg_img-img; 
    gray3 = medfilt2(gray3);
    gray4 = imclose(gray3,se);
    gray4 = gray4>rcor;
    gray4 = imrotate(gray4,theta);
    nozz(3) = cord_of_sprayxpos(gray4);
    nozz(4) = (cord_of_sprayypos(gray4)+cord_of_sprayyneg(gray4))/2;
    lot1 = gray4(:,nozz(3));
    nozz(5) = find(lot1,1,'last');
    for cnt = injection_frame:l %replace by l to iterate 
        t = [t; (cnt-injection_frame+1)*frame_rate];
        img = imread(fullfile(path,tif_files(cnt).name));
        gray2 = (img);
        gray3 = bg_img-gray2; 
        gray3 = medfilt2(gray3);
        gray4 = imclose(gray3,se);
        bina = gray4>rcor;
        bina = imfill(bina,"holes");
        bina1 = 50000 * uint16(bina);
        bina1 = cat(3,bina1,bina,bina);
        bina = imrotate(bina,theta);
        txp = cord_of_sprayxneg(bina);
        diss = nozz(3)-txp;
        xp = [xp;calibration_factor*diss];
        txp10 = floor(diss/2);
        txp20 = floor(diss/3);
        txp1 = nozz(3)-txp10;
        txp2 = nozz(3)-txp20;
        lin1 = bina(:,txp1);
        lin2 = bina(:,txp2);
        lin1 = find(lin1,1,'last')-nozz(5);
        lin2 = find(lin2,1,'last')-nozz(5);
        CA2 = [CA2;2*rad2deg(atan(lin1/txp10))];
        CA3 = [CA3;2*rad2deg(atan(lin2/txp20))];
        
        thisimage = strcat('processed_BW_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory1, thisimage);  %name file relative to that directory
        imwrite(65535-(20*gray3), fulldestination); 
        
        thisimage = strcat('processed_contour_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory2, thisimage);  %name file relative to that directory
        rgbImage = ind2rgb(gray4/10,turbo);
        imwrite(rgbImage, fulldestination); 

        thisimage = strcat('processed_edger_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory3, thisimage);  %name file relative to that directory
        ttim = imfuse(bina1,img,"blend");
        imwrite(ttim, fulldestination);
%         imshow(ttim);
    end
    area_speed = (area(2:end)-area(1:end-1))/frame_rate;
    speedxp = (xp(2:end)-xp(1:end-1))/frame_rate; 

    matx = NaN(1000,6);
    matx(1:length(t),1) = t;
    matx(1:length(area),2) = area;
    matx(1:length(xp),3) = xp;
    matx(1:length(speedxp),4) = speedxp;
    matx(1:length(CA2),5) = CA2;
    matx(1:length(CA3),6) = CA3;
    matf(:,:,count) = matx;
    count = count +1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reporting ptogress %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    fprintf("%s folder data analysis completed. (%d/%d)\n",string(subFolderNames(index)),index,l2); 

    if index == l2
        matstd = std(matf,0,3);
        matavg = sum(matf,3);
        matavg = matavg/(count-1);
        matavg = array2table(matavg,'VariableNames',name_arr_avg);
        matstd = array2table(matstd,"VariableNames",name_arr_std);
        sheet = string(subFolderNames(index));
        sheet = strrep(sheet,'.','_');
        chr = convertStringsToChars(sheet);
        if (length(chr) > 29)
            sheet = string(chr(1:30));
        end
        mattoprin =[];
        lt1 = [];
        for i = 1:count-1
            name_arr = "";
            for j = 1:6
                name_arr(j) = strcat(name_arr1(j)," data ",num2str(i));
            end
            matp = matf(:,:,i);
            ltt = length(matp(:,1));
            matp = array2table(matp,'VariableNames',name_arr);
            lt1 = zeros(ltt,1);
            lt1 = lt1 + 32;
            lt1 = char(lt1);
            lt1 = array2table(lt1,'VariableNames',string(num2str(i)));
            mattoprin = [mattoprin matp lt1];
        end
        lt1 = zeros(ltt,1);
        lt1 = lt1 + 32;
        lt1 = char(lt1);
        lt1 = array2table(lt1,'VariableNames',string(num2str(50)));
        mattoprin = [mattoprin matavg lt1 matstd];
        writetable(mattoprin,xcl,'Sheet',sheet,"WriteMode","overwritesheet");
        count = 1;
        matf = [];
        disp("........................sheet completed........................")
    end

end
disp("................................................")
disp("Data analysis completed.")
disp("................................................")
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% cord. of spray front function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = cord_of_sprayxpos(img1)
    [~, columns] = find(img1);
    a = max(columns);
end

function a = cord_of_sprayypos(img1)
    [rows, ~] = find(img1);
    a = max(rows);
end

function a = cord_of_sprayxneg(img1)
    [~, columns] = find(img1);
    a = min(columns);
end

function a = cord_of_sprayyneg(img1)
    [rows, ~] = find(img1);
    a = min(rows);
end

function a = center_of_area(img1)
    measurements = regionprops(img1, 'Centroid');
    centroids = [measurements.Centroid];
    xCentroids = mean(centroids(1:2:end));
    yCentroids = mean(centroids(2:2:end));
    a = [xCentroids,yCentroids];
end
