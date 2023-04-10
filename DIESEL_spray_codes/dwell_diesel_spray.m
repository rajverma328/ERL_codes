clear all
close all
warning('off')
%%%%%%%%%%%%%%%%%%%%%%%%% taking input %%%%%%%%%%%%%%%%%%%%%%%%%
prompt = {'Enter length calibration factor (mm/pixel)','Enter frame rate in f.p.s.','width of spray in pixels','threshold value of first set','threshold value of second set'};
dlgtitle = 'Input';
dims = [1 50];
definput = {'0.05543','10000','20','40','150'};  %(197/7.5)^-1 as provided
answer = inputdlg(prompt,dlgtitle,dims,definput);
calibration_factor = str2double(answer(1));
frame_rate = str2double(answer(2));
widd = str2double(answer(3));
thres1 = str2double(answer(4));
thres2 = str2double(answer(5));
area_cal_fac = calibration_factor*calibration_factor;
frame_rate = frame_rate/1000; %frames per milli second
frame_rate = 1/frame_rate;
widd = widd/2;

%%%%%%%%%%%%%%%%%%%%%%%%% asking file name %%%%%%%%%%%%%%%%%%%%%%%%%
data_filename = uigetdir; % filename for all folders
topLevelFolder = data_filename;  % Get a list of all files and folders in this folder.
files = dir(topLevelFolder);    % Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];   % Extract only those that are directories.
subFolders = files(dirFlags);   % A structure with extra info. Get only the folder names into a cell array.
subFolderNames = {subFolders(3:end).name}; % Start at 3 to skip .

for index = 1:length(subFolderNames)
    blsh = '\';
    path_in = strcat(data_filename,blsh,subFolderNames(index));
    bottomLevelFolder = string(path_in);
    files_in = dir(bottomLevelFolder);    % Get a logical vector that tells which is a directory.
    dirFlags_in = [files_in.isdir];   % Extract only those that are directories.
    subFolders_in = files_in(dirFlags_in);   % A structure with extra info. Get only the folder names into a cell array.
    subFolderNames_in = {subFolders_in(3:end).name};
    s_1 = subFolderNames(index);
    xcl = strcat(path_in,'\',s_1,'.xlsx');
    cola = {'A2' 'B2' 'C2' 'D2' 'E2' 'F2' 'G2' 'H2'};
    cola2 = {'J2' 'K2' 'L2' 'M2' 'N2' 'O2' 'P2' 'Q2'};
    for in_index = 1 : length(subFolderNames_in)
        sheet = string(subFolderNames_in(in_index));
        sheet = strrep(sheet,'.','_');
        chr = convertStringsToChars(sheet);
        if (length(chr) > 29)
            sheet = string(chr(1:30));
        end
        path = strcat(path_in,blsh,subFolderNames_in(in_index),blsh);
        path = string(path);
        dumy = string(subFolderNames_in(in_index));
        tif_files = dir(fullfile(path,'*.tif'));
        l = length(tif_files);
        bg_img = rgb2gray(imread(fullfile(path,tif_files(1).name)));
        k = 0;
        fi = 0;
        si = 0;
        check = -1;
        dim = size(bg_img);
        nozz = [];
        nozzle = [];
        %%%%%%%%%%%%%%%%%% for first set of images
        area = [];
        spray_speed = [];   
        coa = [];
        cowfx = 0;
        cowfy = 0;
        area_speed = [];
        
        %%%%%%%%%%%%%%%%%% for second set of images
        area2 = [];
        spray_speed2 = [];   
        coa2 = [];
        cowfx2 = 0;
        cowfy2 = 0;
        area_speed2 = [];

        tt = [];
        tt2 = [];
        destdirectory = strcat(path,'result_images');
        mkdir(destdirectory);   %create the directory
        for cnt = 1 : l
            img = imread(fullfile(path,tif_files(cnt).name));
            gray = rgb2gray(img);
            diff_img = bg_img - gray;
            BW = diff_img > 40;   
            se90 = strel('line',1,90);
            se0 = strel('line',1,0);
            imgThresh = imdilate(BW,[se90 se0]);
            imgFilled = bwareaopen(imgThresh,30);
            imgFilled = imfill(imgFilled, 'holes');
            seD = strel('diamond',1);
            imgFilled = imerode(imgFilled,seD);
            BWfinal = imerode(imgFilled,seD);
            kex = spray_area(BWfinal);
            if (kex ~=0)
                if k == 0
                    nozz(2) = cord_of_nozzley(BWfinal)+10;
                    nozz(1) = cord_of_nozzlex(BWfinal)-10;
                    k = cnt;
                    fi = cnt;
                end
                a = BWfinal(nozz(2),nozz(1));
                if a~=1 && check ==-1
                    check =cnt;
                end
            end
            if (si==0) && check > 0
                a = BWfinal(nozz(2),nozz(1));
                if a>0
                    si = cnt;
                end
            end
        end
        %disp(fi)
        %disp(check)
        %disp(si)

        %%%%%%%%%%%%%%%%%%%%%%%%% till the end of first injection %%%%%%%%%%%%%%%%%%%%%%%%%
        for cnt = 1 : si-1
            img = imread(fullfile(path,tif_files(cnt).name));
            gray = rgb2gray(img);
            diff_img = bg_img - gray;
            diff_img = imfill(diff_img,'holes');
            BW = diff_img > thres1;
            se90 = strel('line',1,90);
            se0 = strel('line',1,0);
            imgThresh = imdilate(BW,[se90 se0]);
            imgFilled = bwareaopen(imgThresh,30);
            imgFilled = imfill(imgFilled, 'holes');
            seD = strel('diamond',1);
            imgFilled = imerode(imgFilled,seD);
            BWfinal = imerode(imgFilled,seD);
            area = [area; area_cal_fac*spray_area(BWfinal)];
            coa = [coa; center_of_area(BWfinal)];
            tt = [tt; frame_rate*(cnt-1)];
            if cnt>1
                area_speed = [area_speed; area_cal_fac*(area(cnt)-area(cnt-1))/frame_rate];
            end
            thisimage = strcat('processed_',tif_files(cnt).name);
            fulldestination = fullfile(destdirectory, thisimage);  %name file relative to that directory
            imwrite(255-diff_img, fulldestination);  %save the file there directory
        end
   
        for i = 1:length(coa(:,1))
            if isnan(coa(i,1))
                coa(i,1) = nozz(1);
                coa(i,2) = nozz(2) + widd;
            end
        end

        x1 = coa(:,1);
        y1 = coa(:,2);
        c = polyfit(x1,y1,1);
        x = linspace(0,dim(2));
        y = c(1)*(x) + c(2);
        theta = atand(c(1));
        for cnt = 1:si-1 %replace by l to iterate 
            img = imread(fullfile(path,tif_files(cnt).name));
            gray = rgb2gray(img);
            diff_img = bg_img - gray;
            diff_img = imfill(diff_img,'holes');
            BW = diff_img > thres1;     %try making it user defined
            se90 = strel('line',1,90);
            se0 = strel('line',1,0);
            imgThresh = imdilate(BW,[se90 se0]);
            imgFilled = bwareaopen(imgThresh,30);
            imgFilled = imfill(imgFilled, 'holes');
            BWfinal = imrotate(imgFilled,theta);
            if cnt == k 
                nozzle = cord_of_nozzlex(BWfinal);
            end
            if cnt < k
                ax = 0;
                ay = 0;
            end
            if cnt>=k
                ax = nozzle - cord_of_sprayx(BWfinal);
                ay = cord_of_sprayy(BWfinal);
            end
            cowfx = [cowfx; calibration_factor*(ax)];
            cowfy = [cowfy; calibration_factor*(ay)];
        end
        speedx = (cowfx(2:end)-cowfx(1:end-1))/frame_rate;    %- added to compensate negative sign
        %%%%%%%%%%%%%%%%%%%%%%%%% second pulse %%%%%%%%%%%%%%%%%%%%%%%%%

        for cnt = si:l 
            img = imread(fullfile(path,tif_files(cnt).name));
            gray = rgb2gray(img);
            diff_img = bg_img - gray;
            diff_img = imfill(diff_img,'holes');
            BW = diff_img > thres2;   
            se90 = strel('line',1,90);
            se0 = strel('line',1,0);
            imgThresh = imdilate(BW,[se90 se0]);
            imgFilled = bwareaopen(imgThresh,3000);
            imgFilled = imfill(imgFilled, 'holes');
            seD = strel('diamond',1);
            imgFilled = imerode(imgFilled,seD);
            BWfinal = imerode(imgFilled,seD);
            area2 = [area2; area_cal_fac*spray_area(BWfinal)];
            coa2 = [coa2; center_of_area(BWfinal)];
            tt2 = [tt2; frame_rate*(cnt-1)];
            if cnt>si
                area_speed2 = [area_speed2; area_cal_fac*(area2(cnt-si+1)-area2(cnt-si))/frame_rate];
            end
            thisimage = strcat('processed_',tif_files(cnt).name);
            fulldestination = fullfile(destdirectory, thisimage);  %name file relative to that directory
            imwrite(255-diff_img, fulldestination);  %save the file there directory
        end
   
        for i = 1:length(coa2(:,1))
            if isnan(coa2(i,1))
                coa2(i,1) = nozz(1);
                coa2(i,2) = nozz(2) + widd;
            end
        end

        x1 = coa2(:,1);
        y1 = coa2(:,2);
        c = polyfit(x1,y1,1);
        x = linspace(0,dim(2));
        y = c(1)*(x) + c(2);
        theta = atand(c(1));
        
        for cnt = si:l %replace by l to iterate 
            img = imread(fullfile(path,tif_files(cnt).name));
            gray = rgb2gray(img);
            diff_img = bg_img - gray;
            diff_img = imfill(diff_img,'holes');
            BW = diff_img > thres2;   
            se90 = strel('line',1,90);
            se0 = strel('line',1,0);
            imgThresh = imdilate(BW,[se90 se0]);
            imgFilled = bwareaopen(imgThresh,3000);
            imgFilled = imfill(imgFilled, 'holes');
            seD = strel('diamond',1);
            imgFilled = imerode(imgFilled,seD);
            BWfinal = imerode(imgFilled,seD);
            ax = nozzle - cord_of_sprayx(BWfinal);
            ay = cord_of_sprayy(BWfinal);
            if isempty(ax)
                ax = 0;
            end
            if isempty(ay)
                ay = 0;
            end
            cowfx2 = [cowfx2; calibration_factor*(ax)];
            cowfy2 = [cowfy2; calibration_factor*(ay)];
        end
        speedx2 = (cowfx2(2:end)-cowfx2(1:end-1))/frame_rate;

        %%%%%%%%%%%%%%%%%%%%%%%%% writing data in excel file %%%%%%%%%%%%%%%%%%%%%%%%%
        Results_Names={'Area','Center of Area(x)','Center of Area(y)','area speed','wave front displacement(along axis)','radial displacemet(wave front)','axial speed','time(milliseconds)'};
        xlswrite(string(xcl),Results_Names(8),sheet,'A1');
        xlswrite(string(xcl),Results_Names(1),sheet,'B1');
        xlswrite(string(xcl),Results_Names(2),sheet,'C1');
        xlswrite(string(xcl),Results_Names(3),sheet,'D1');
        xlswrite(string(xcl),Results_Names(4),sheet,'E1');
        xlswrite(string(xcl),Results_Names(5),sheet,'F1');
        xlswrite(string(xcl),Results_Names(6),sheet,'G1');
        xlswrite(string(xcl),Results_Names(7),sheet,'H1');
        
        xlswrite(string(xcl),tt,sheet,string(cola(1)));
        xlswrite(string(xcl),area,sheet,string(cola(2)));
        xlswrite(string(xcl),coa(:,1),sheet,string(cola(3)));
        xlswrite(string(xcl),coa(:,2),sheet,string(cola(4)));
        xlswrite(string(xcl),area_speed,sheet,string(cola(5)));
        xlswrite(string(xcl),cowfx,sheet,string(cola(6)));
        xlswrite(string(xcl),cowfy,sheet,string(cola(7)));
        xlswrite(string(xcl),speedx,sheet,string(cola(8)));

        xlswrite(string(xcl),Results_Names(8),sheet,'J1');
        xlswrite(string(xcl),Results_Names(1),sheet,'K1');
        xlswrite(string(xcl),Results_Names(2),sheet,'L1');
        xlswrite(string(xcl),Results_Names(3),sheet,'M1');
        xlswrite(string(xcl),Results_Names(4),sheet,'N1');
        xlswrite(string(xcl),Results_Names(5),sheet,'O1');
        xlswrite(string(xcl),Results_Names(6),sheet,'P1');
        xlswrite(string(xcl),Results_Names(7),sheet,'Q1');
        
        xlswrite(string(xcl),tt2,sheet,string(cola2(1)));
        xlswrite(string(xcl),area2,sheet,string(cola2(2)));
        xlswrite(string(xcl),coa2(:,1),sheet,string(cola2(3)));
        xlswrite(string(xcl),coa2(:,2),sheet,string(cola2(4)));
        xlswrite(string(xcl),area_speed2,sheet,string(cola2(5)));
        xlswrite(string(xcl),cowfx2,sheet,string(cola2(6)));
        xlswrite(string(xcl),cowfy2,sheet,string(cola2(7)));
        xlswrite(string(xcl),speedx2,sheet,string(cola2(8)));
       
        fprintf("%s data analaysis completed\n",string(subFolderNames_in(in_index)))
    end
    disp('...................................................')
    fprintf("%s data analaysis completed\n",string(subFolderNames(index)))
    disp('...................................................')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% area function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = spray_area(img)    
    area = (bwarea(img));  
    a = round(area,3);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% center of area function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = center_of_area(img1)
    [y, x] = ndgrid(1:size(img1, 1), 1:size(img1, 2));
    a = mean([x(logical(img1)), y(logical(img1))]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% cord. of spray front function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = cord_of_sprayx(img1)
    [~, columns] = find(img1);
    a = min(columns);
end

function a = cord_of_sprayy(img1)
    [rows, ~] = find(img1);
    a = min(rows);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% cord. of nozzle function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = cord_of_nozzlex(img1)
    [~, columns] = find(img1);
    a = max(columns);
end

function a = cord_of_nozzley(img1)
    [rows, ~] = find(img1);
    a = min(rows);
end