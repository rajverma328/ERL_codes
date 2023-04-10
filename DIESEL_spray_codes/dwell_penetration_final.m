clear all
close all
warning('off')
%%%%%%%%%%%%%%%%%%%%%%%%% taking input %%%%%%%%%%%%%%%%%%%%%%%%%
prompt = {'Enter length calibration factor (mm/pixel)','Enter frame rate in f.p.s.','width of spray in pixels','threshold value of first set'};
dlgtitle = 'Input';
dims = [1 50];
definput = {'0.05543','10000','20','20'};  %(197/7.5)^-1 as provided
answer = inputdlg(prompt,dlgtitle,dims,definput);
calibration_factor = str2double(answer(1));
frame_rate = str2double(answer(2));
widd = str2double(answer(3));
thres1 = str2double(answer(4));
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
%     cola2 = {'J2' 'K2' 'L2' 'M2' 'N2' 'O2' 'P2' 'Q2'};
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
        [rows,cols,~] = size(bg_img);
        nozz = [];
        nozzle = [];
        coa = [];

        %%%%%%%%%%%%%%%%%% for first set of images
        cowfx = 0;
        cowfy = [];   
        %%%%%%%%%%%%%%%%%% for second set of images
        cowfx2 = [];
        cowfy2 = [];

        tt = 1*frame_rate;
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
%             imshow(BWfinal)
            kex = spray_area(BWfinal);
            coa = [coa; center_of_area(BWfinal)];
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
        for i = 1:length(coa(:,1))
            if isnan(coa(i,1))
                coa(i,1) = nozz(1);
                coa(i,2) = nozz(2) + widd;
            end
        end
        x1 = coa(:,1);
        y1 = coa(:,2);
        c = polyfit(x1,y1,1);
        theta = atand(c(1));
        %disp(theta)
        %disp(fi)
        %disp(check)
        %disp(si)
        nozzr = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%% till the end of first injection %%%%%%%%%%%%%%%%%%%%%%%%%
        for cnt = 2 : si-1
            tt = [tt;cnt*frame_rate];
            img2 = imread(fullfile(path,tif_files(cnt).name));
            img1 = imread(fullfile(path,tif_files(cnt-1).name));
            gray1 = rgb2gray(img1);
            gray2 = rgb2gray(img2);
            diff_img = gray1-gray2;
            BW = diff_img>thres1;
            BW = imrotate(BW,theta);
%             imshow(BW)
            if cnt == fi
                nozzr = cord_of_nozzlex(BW);
            end
            if cnt<fi
                cowfx = [cowfx; 0];
            end
            if cnt>=fi
                cowfx = [cowfx; calibration_factor*(-cord_of_sprayx(BW)+nozzr)];
                cowfy = [cowfy; (cord_of_sprayy(BW)+cord_of_sprayy2(BW))/2];
            end
        end
        cowme = round(mean(cowfy));
        for cnt = si : l
            tt2 = [tt2 ;cnt*frame_rate];
            img2 = imread(fullfile(path,tif_files(cnt).name));
            img1 = imread(fullfile(path,tif_files(cnt-1).name));
            gray1 = rgb2gray(img1);
            gray2 = rgb2gray(img2);
            diff_img = gray1-gray2;
            BW = diff_img>thres1;
            BW = imrotate(BW,theta);
            ch1 = BW(cowme,:);
            fls = 0; fls_check = 1;
            fpoint = [];
            for i = 1:length(ch1)
                if ch1(i) == fls_check
                    fls_check = 0;
                    fls = fls+1;
                    fpoint = [fpoint;i];
                end
            end
            if fls > 2
                cowfx2 = [cowfx2; calibration_factor*(-fpoint(3)+nozzr)];
            end
            if fls == 2
                cowfx2 = [cowfx2; calibration_factor*(-fpoint(1)+nozzr)];
            end
        end
        l1 = length(tt);
        l2 = length(tt2);
        l11 = length(cowfx);
        l22 = length(cowfx2);
        cowfx(l11+1:l1) = cowfx(l11);
        cowfx2(l22+1:l2) = cowfx2(l22);
        speedx1 = (cowfx(2:end)-cowfx(1:end-1))*frame_rate;
        speedx2 = (cowfx2(2:end)-cowfx2(1:end-1))*frame_rate;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% writing data to excel file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        Results_Names={'time','distance','speed','time','distance','speed'};
        xlswrite(string(xcl),Results_Names(1),sheet,'A1');
        xlswrite(string(xcl),Results_Names(2),sheet,'B1');
        xlswrite(string(xcl),Results_Names(3),sheet,'C1');
        xlswrite(string(xcl),Results_Names(4),sheet,'E1');
        xlswrite(string(xcl),Results_Names(5),sheet,'F1');
        xlswrite(string(xcl),Results_Names(6),sheet,'G1');
        
        xlswrite(string(xcl),tt,sheet,string(cola(1)));
        xlswrite(string(xcl),cowfx,sheet,string(cola(2)));
        xlswrite(string(xcl),speedx1,sheet,string(cola(3)));
        xlswrite(string(xcl),tt2,sheet,string(cola(5)));
        xlswrite(string(xcl),cowfx2,sheet,string(cola(6)));
        xlswrite(string(xcl),speedx2,sheet,string(cola(7)));

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

function a = cord_of_sprayy2(img1)
    [rows, ~] = find(img1);
    a = max(rows);
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