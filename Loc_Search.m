% Newest Computation for PhD
% made by Zulfikar A. Nadzir
% last update on 23.03.2023

dbstop if error
close all
clearvars;
clc
addpath(genpath('lib/matlab/'));
addpath '/home/g21zunadz/Downloads/MWCC_Exercises/calval_MGS05/lib/matlab/lib_nadzir'

%% TG Data Processing --> Definite Search 14.03.23
addpath '/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG';
path2='/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined'; 
cd(path2)
filename1=dir('*');
for i=3:length(filename1)
    cd(path2)
    file(i-2,:)=struct2cell(filename1(i,1));
    fprintf(1,'processing data of station ');
    fprintf (1,'\b %s',extractAfter (file{i-2,1},"_"));
    fprintf ('\n');
    nama{i-2,1}=extractAfter (file{i-2,1},"_");
    % folder_path='/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG/0012KPNG02_Kupang'
    [datetimes,lvl,year] = TGprocess(file{i-2,1});
    fname=sprintf('data_%s.mat', extractAfter (file{i-2,1},"_"));
    nama{i-2,2}=year;
    % cd (path2)
    save(fname,'datetimes','lvl','year');
    data_tg{i-2,1}=string(nama{i-2,1});
    data_tg{i-2,2}=datetimes;
    data_tg{i-2,3}=lvl;
    data_tg{i-2,4}=year;
end

for j=1:97
    % station(j)=string(nama{j,1});
    % panjang(j)=length(nama{j,2});
    % data_tg{j,5}=panjang(j);
    
    % Completeness Index Processing#1 - in decimals (1 means complete in hourly manner)
    [date_tg,id_un]=unique(vertcat(data_tg{j,2}{:}),'stable');
    lvl_tg=vertcat(data_tg{j,3}{:});
    lvl_tg_un=lvl_tg(id_un);
    med_dat=median(diff(date_tg));
    data_tg{j,15}=med_dat;
    date_expect=date_tg(1):med_dat:date_tg(end);
    data_tg{j,6}=length(date_tg)/length(date_expect);
    % figure('Position',get(0,'Screensize'));
    % plot(date_tg,lvl_tg_un)
    % title(['Original Time Series of ', data_tg{j,1}],'FontSize',28,'FontWeight','bold')
    %xlabel('Year')
    % ylabel('observed water level [cm]')
    % saveas(gcf,('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/Figures_all/Original Plot of ' + data_tg{j,1} + '.png'))

    % Completeness Index Processing#2 - based on number of years
    year_const=24*365.2425;
    data_tg{j,21}=length(date_tg)/(year_const*data_tg{j,5});
    
    % Gap Detection - 60 days as threshold
    thres=duration(days(180));
    difdate=diff(date_tg);
    max_dif(j)=days(max(difdate));
    idx = find(difdate > thres);
    data_tg{j,7}=length(idx);
    % figure
    % plot(date_tg,lvl_tg_un,date_tg([idx,idx+1]),lvl_tg_un([idx,idx+1]),'x','MarkerSize',20,'LineWidth',3)
    
    % Outlier Detection#1 - outlier using 6 data/hours moving-mean
    diflvl=diff(lvl_tg_un);
    TF=isoutlier(lvl_tg_un,'movmedian',hours(6),"SamplePoints",date_tg);
    % [TF_rm,id_rm]=rmoutliers(lvl_tg_un,'movmedian',hours(6),"SamplePoints",date_tg);
    ind_TF=find(TF==1);
    data_tg{j,8}=length(ind_TF);
    data_tg{j,11}=(length(date_tg)-length(ind_TF))./length(date_tg);
    % figure
    % hold on
    % plot(date_tg,lvl_tg_un,date_tg(ind_TF),lvl_tg_un(ind_TF),'x','MarkerSize',20,'LineWidth',3)
    % plot(date_tg(~id_rm),TF_rm,'LineWidth',3)

    % Outlier Detection#2 - outlier using modified Hampel (6sigma-MAD)
    [aft_outl, TF2]=hampel(lvl_tg_un,3,3);
    ind_TF2=find(TF2==1);
    data_tg{j,18}=length(ind_TF2);
    data_tg{j,19}=(length(date_tg)-length(ind_TF2))./length(date_tg);
    % figure
    % hold on
    % plot(date_tg,lvl_tg_un,date_tg(ind_TF2),lvl_tg_un(ind_TF2),'x','MarkerSize',20,'LineWidth',3)

    % Jump Detection#1 - Grubbs outlier from 30-days moving mean
    mov60=movmean(lvl_tg_un,days(30),"SamplePoints",date_tg);
    diff60=diff(mov60);
    TF1=isoutlier(diff60,'grubbs');
    ind_TF1=find(TF1==1);
    data_tg{j,12}=length(ind_TF1);
    % figure
    % hold on
    % plot(date_tg,lvl_tg_un,date_tg(ind_TF1),lvl_tg_un(ind_TF1),'x','MarkerSize',20,'LineWidth',3)

    % Jump Detection#2 - findchangepts
    id_ptsch=findchangepts(lvl_tg_un,'Statistic','linear','MinThreshold',10000000);
    data_tg{j,20}=length(id_ptsch);
    % figure('Position',get(0,'Screensize'));
    % findchangepts(lvl_tg_un,'Statistic','linear','MinThreshold',10000000);
    % saveas(gcf,('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/Figures_all/Jump_Detection Plot of ' + data_tg{j,1} + '.png'))

    % Precision Calculation --> using mean and minimum difference
    data_tg{j,13}=mean(lvl_tg_un);
    data_tg{j,14}=min(diflvl);

    % Typical standard deviation --> median of 60-days moving std
    data_tg{j,16}=median(movstd(lvl_tg_un,days(60),"SamplePoints",date_tg));

    % Stuck Instrument Test --> 5 or more consecutive zero differences
    mov_dif=movmean(diflvl,5);
    props = regionprops(logical(mov_dif==0), 'Area', 'PixelIdxList');
    data_tg{j,17}=length(find([props.Area] >= 5));

    % Correcting for Outlier(from Method#1) and Jump (from Method#2)
    % adjusting data jump
    % if data_tg{j,20} ~= 0
    if data_tg{j,20} == 1
            m(1)=mean(lvl_tg_un(1:id_ptsch(1)));
            m(2)=mean(lvl_tg_un(id_ptsch(1)+1:end));
            difm1=m(1)-m(2);
            lvl_tg_un=[lvl_tg_un(1:id_ptsch(1)); lvl_tg_un(id_ptsch(1)+1:end)+difm1];
    elseif data_tg{j,20} == 2
            m(1)=mean(lvl_tg_un(1:id_ptsch(1)));
            m(2)=mean(lvl_tg_un(id_ptsch(1)+1:id_ptsch(2)));
            m(3)=mean(lvl_tg_un(id_ptsch(2)+1:end));
            difm2=m(2)-m(3);
            lvl_tg_un=[lvl_tg_un(1:id_ptsch(1)); lvl_tg_un(id_ptsch(1)+1:id_ptsch(2))-difm2; lvl_tg_un(id_ptsch(2)+1:end)];
    elseif data_tg{j,20} == 3
            m(1)=mean(lvl_tg_un(1:id_ptsch(1)));
            m(2)=mean(lvl_tg_un(id_ptsch(1)+1:id_ptsch(2)));
            m(3)=mean(lvl_tg_un(id_ptsch(2)+1:id_ptsch(3)));
            m(4)=mean(lvl_tg_un(id_ptsch(3)+1:end));
            difm1=m(1)-m(2);
            difm3=m(3)-m(4);
            lvl_tg_un=[lvl_tg_un(1:id_ptsch(1))-difm1; lvl_tg_un(id_ptsch(1)+1:id_ptsch(2));lvl_tg_un(id_ptsch(2)+1:id_ptsch(3))-difm3; lvl_tg_un(id_ptsch(3)+1:end)];
    end
    % deleting outlier index
    aft_out_lvl=lvl_tg_un(~TF);
    aft_out_time=date_tg(~TF);
    data_tg{j,22}=aft_out_lvl;
    data_tg{j,23}=aft_out_time;
    % figure('Position',get(0,'Screensize'));
    % plot(aft_out_time,aft_out_lvl,'LineWidth',3)
    % title(['Step-Adjusted Time Series of ', data_tg{j,1}],'FontSize',28,'FontWeight','bold')
    % xlabel('Year')
    % ylabel('observed water level [cm]')
    % saveas(gcf,('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/Figures_all/Step-Adjusted Plot of ' + data_tg{j,1} + '.png'))
    % close all

    % Nearest CORS Stations Search
    load('/home/g21zunadz/Downloads/CORS/CORs_List.mat');
    [data_tg{j,25}, distan]=dsearchn([CORSList.Longitude CORSList.Latitude],[data_tg{j,10} data_tg{j,9}]);
    data_tg{j,26}=distan.*111.11;
    data_tg{j,24}=CORSList.ID_CORS(data_tg{j,25});
    data_tg{j,28}=CORSList.Longitude(data_tg{j,25});
    data_tg{j,27}=CORSList.Latitude(data_tg{j,25});
end

% Trend Computation for the data
dbstop if error
close all
clearvars;
clc
addpath(genpath('lib/matlab/'));
addpath '/home/g21zunadz/Downloads/MWCC_Exercises/calval_MGS05/lib/matlab'
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems.mat')

for i=1:97
    TGtime=decyear(datevec(data_tg{i,23}));
    fitann_tg{i}=fitann([TGtime data_tg{i,22}]);
    trnd_tg(:,i)=[fitann_tg{i}.trend fitann_tg{i}.trend_sig];
    an_tg(:,i)=[fitann_tg{i}.an_AM fitann_tg{i}.an_AM_sig];
    san_tg(:,i)=[fitann_tg{i}.san_AM fitann_tg{i}.san_AM_sig];
    res_tg{i}=fitann_tg{i}.res;
    data_tg{i,44}=[trnd_tg(:,i) an_tg(:,i) san_tg(:,i)];
    data_tg{i,45}=res_tg{i};
end

% Plotting the Trend + Annual + Semi-Annual Signal
plot_errorbar(trnd_tg,an_tg,san_tg)

%% Plot for Several Recaps on Obtained TG Data
% Figure Showing Completeness Index
cindex=[data_tg{:,6}; data_tg{:,21}]';
station=vertcat(data_tg{:,1});
figure
barh(max(cindex,[],2))
xlim ([0 1.2])
yticks(1:97)
ax=gca;
ax.YAxis.FontSize = 7;
title('Completeness Index of 97 Tide Gauges in Indonesia','FontSize',18,'FontWeight','bold')
xlabel('Completeness Ratio','FontSize',17,'FontWeight','bold')
ylabel('Station Index','FontSize',17,'FontWeight','bold')
hold on
line([0.7, 0.7], ylim, 'Color', 'r', 'LineWidth', 4);

% Figure Showing Gap Recap
figure
barh(max_dif)
xlim ([0 300])
yticks(1:97)
ax=gca;
ax.YAxis.FontSize = 7;
title('Maximum Data Gap Duration of 97 Tide Gauges in Indonesia','FontSize',18,'FontWeight','bold')
xlabel('Data Gap Duration [days]','FontSize',17,'FontWeight','bold')
ylabel('Station Index','FontSize',17,'FontWeight','bold')
hold on
line([180, 180], ylim, 'Color', 'r', 'LineWidth', 4);
line([112, 112], ylim, 'Color', 'green', 'LineWidth', 4);
line([48, 48], ylim, 'Color', 'black', 'LineWidth', 4);
% line(xlim, [5, 5], 'Color', 'r', 'LineWidth', 2);
% line(xlim, [20, 20], 'Color', 'r', 'LineWidth', 2);

% Figure showing length of Years
panjang=vertcat(data_tg{:,5});
figure
barh([1:97],panjang)
yticks(1:1:97)
ax=gca;
ax.YAxis.FontSize = 7;
title('Length of Selected Indonesian Tide Gauges Data in Years','FontSize',18,'FontWeight','bold')
xlabel('Number of Years','FontSize',17,'FontWeight','bold')
ylabel('Station Index','FontSize',17,'FontWeight','bold')
hold on
line([6, 6], ylim, 'Color', 'r', 'LineWidth', 4);

% Figure showing Location of Data with Legends for Gap, Step and Complete
pat3='/home/g21zunadz/Downloads/gshhg-bin-2.3.7/'; cd (pat3);
S=gshhs("gshhs_f.b",[-11, 11],[90 145]);
figure
plot ([S.Lon],[S.Lat],'DisplayName','Coastline')
xlim ([93 143])
ylim ([-13 7])
hold on
title ('Network of Obtained BIG Tide Gauges in Indonesia','FontSize',18,'FontWeight','bold')
xlabel('Longitude [°]','FontSize',17,'FontWeight','bold')
ylabel('Latitude [°]','FontSize',17,'FontWeight','bold')
grid on
scatter ([data_tg{:,10}],[data_tg{:,9}],120,'green','^','filled','DisplayName','Tide Gauges')
% scatter ([data_tg{:,9}],[data_tg{:,8}],50,[data_tg{:,10}],'^','filled','DisplayName','Tide Gauges')
% colorbar;
% colormap("autumn")
legend;
test1=find([data_tg{:,7}]>0);
scatter ([data_tg{test1,10}],[data_tg{test1,9}],140,'black','o','filled','DisplayName','Tide Gauges')
test2=find([data_tg{:,20}]>0);
scatter ([data_tg{test2,10}],[data_tg{test2,9}],140,'red','s','filled','DisplayName','Tide Gauges')
legend ('Indonesian Coastline','Tide Gauge Stations','Tide Gauge with Gap','Tide Gauge with Jump','FontSize',12)

% Figure showing year-to-year coverage of TG data
figure
hold on
for k=1:97
    plot(str2num(cell2mat(data_tg{k,4}')),ones(size(cell2mat(data_tg{k,4}')))*k,'LineWidth',6,'Color',[0 0.4470 0.7410])
end
yticks(1:97)
% yticklabels(station)
xticks(2009:1:2021)
xlim ([2009 2022])
ylim([0 98])
ax=gca;
ax.YAxis.FontSize = 7;
title ('Time Availability of Obtained BIG Tide Gauges','FontSize',18,'FontWeight','bold')
xlabel('Year','FontSize',17,'FontWeight','bold')
ylabel('Station Index','FontSize',17,'FontWeight','bold')
grid on
line([2019, 2019], ylim, 'Color', 'r', 'LineWidth', 4);

%% Station Near ALT Search from Real Data --> 23.03.23
dbstop if error
close all
clearvars;
clc
addpath(genpath('lib/matlab/'));
addpath '/home/g21zunadz/Downloads/MWCC_Exercises/calval_MGS05/lib/matlab/lib_nadzir'
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa.mat')

% S3 Data
load('/home/g21zunadz/Downloads/SAR_Alt/CMEMS/s3a/s3a_cmems.mat') % S3A
% load('/home/g21zunadz/Downloads/SAR_Alt/CMEMS/s3b/s3b_cmems.mat') % S3B
for i=1:length(vertcat(data_tg{:,9}))
    sprintf('Processing TG Number %d',i)
    latt=vertcat(lat{:});
    lonn=vertcat(lon{:});
    jarak=sqrt(((latt-data_tg{(i),9}).^2)+((lonn-data_tg{(i),10}).^2));
    % searching for data with euclidean distance to TG < 20 km
    indnear{i}=find(jarak<(20/111.11));
    % searching for nearest point with its distance from the TG
    data_tg{i,32}=length(indnear{i});
    [indnearest{i},dist{i}] = dsearchn([lonn latt],[data_tg{(i),10} data_tg{(i),9}]);
    data_tg{i,33}=[dist{i}*111.11 latt(indnearest{i}) lonn(indnearest{i})];
    data_tg{i,34}=[latt(indnear{i}) lonn(indnear{i})];
end

% J123 Data
% ALES
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/Raw_Alt_AL.mat') % ALES
for i=1:length(vertcat(data_tg{:,9}))
    sprintf('Processing TG Number %d',i)
    jarak=sqrt(((lat_al-data_tg{(i),9}).^2)+((lon_al-data_tg{(i),10}).^2));
    % searching for data with euclidean distance to TG < 20 km
    indnear{i}=find(jarak<(20/111.11));
    % searching for nearest point with its distance from the TG
    data_tg{i,35}=length(indnear{i});
    [indnearest{i},dist{i}] = dsearchn([lon_al lat_al],[data_tg{(i),10} data_tg{(i),9}]);
    data_tg{i,36}=[dist{i}*111.11 lat_al(indnearest{i}) lon_al(indnearest{i})];
    data_tg{i,37}=[lat_al(indnear{i}) lon_al(indnear{i})];
end

% X-TRACK/ALES
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/Raw_Alt_XA.mat') % X-TRACK/ALES
for i=1:length(vertcat(data_tg{:,9}))
    sprintf('Processing TG Number %d',i)
    latt=vertcat(lat_xa{:});
    lonn=vertcat(lon_xa{:});
    jarak=sqrt(((latt-data_tg{(i),9}).^2)+((lonn-data_tg{(i),10}).^2));
    % searching for data with euclidean distance to TG < 20 km
    indnear{i}=find(jarak<(20/111.11));
    % searching for nearest point with its distance from the TG
    data_tg{i,38}=length(indnear{i});
    [indnearest{i},dist{i}] = dsearchn([lonn latt],[data_tg{(i),10} data_tg{(i),9}]);
    data_tg{i,39}=[dist{i}*111.11 latt(indnearest{i}) lonn(indnearest{i})];
    data_tg{i,40}=[latt(indnear{i}) lonn(indnear{i})];
end

% CMEMS
% load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/NM_J1.mat', 'lat_nm_1', 'lon_nm_1') % J1_CMEMS
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/NM_J2.mat', 'lat_nm_2', 'lon_nm_2') % J2_CMEMS
% load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/NM_J3.mat', 'lat_nm_3', 'lon_nm_3') % J3_CMEMS
latt=vertcat(lat_nm_2{:}); 
lonn=vertcat(lon_nm_2{:});
for i=1:length(vertcat(data_tg{:,9}))
    sprintf('Processing TG Number %d',i)
    jarak=sqrt(((latt-data_tg{(i),9}).^2)+((lonn-data_tg{(i),10}).^2));
    % searching for data with euclidean distance to TG < 20 km
    indnear{i}=find(jarak<(20/111.11));
    % searching for nearest point with its distance from the TG
    data_cmems{i,4}=length(indnear{i});
    % [indnearest{i},dist{i}] = dsearchn([lonn(indnear{i}) latt(indnear{i})],[data_tg{(i),10} data_tg{(i),9}]);
    % data_cmems{i,5}=[dist{i}*111.11 latt(indnear{i}(indnearest{i})) lonn(indnear{i}(indnearest{i}))];
    data_cmems{i,6}=[latt(indnear{i}) lonn(indnear{i})];
end
for i=1:97
    data_tg{i,41}=data_cmems{i,1}+data_cmems{i,4}+data_cmems{i,7};
    data_tg{i,42}=[data_cmems{i,2} data_cmems{i,5} data_cmems{i,8}];
    data_tg{i,43}=[data_cmems{i,3}; data_cmems{i,6}; data_cmems{i,9}];
end

%% Plotting for Specifically 19 Stations That Will be Used
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 10)

slct_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];
for i=1:length(slct_def)
    % Plotting Gap + Jump
    [date_tg,id_un]=unique(vertcat(data_tg{slct_def(i),2}{:}),'stable');
    lvl_tg=vertcat(data_tg{slct_def(i),3}{:});
    lvl_tg_un=lvl_tg(id_un);
    
    % Jump Plot
    figure('Position',get(0,'Screensize'));
    findchangepts(lvl_tg_un,'Statistic','linear','MinThreshold',10000000);
    saveas(gcf,('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/Figures/Jump Search Plot of ' + data_tg{slct_def(i),1} + '.png'))

    % Gap Plot
    thres=duration(days(60));
    difdate=diff(date_tg);
    idx = find(difdate > thres);
    figure('Position',get(0,'Screensize'));
    plot(date_tg,lvl_tg_un,date_tg([idx idx+1]),lvl_tg_un([idx idx+1]),'x','MarkerSize',20,'LineWidth',3)
    legend({'Water Level Data','Gap Locations'})
    title(['Gap Detection of ', data_tg{slct_def(i),1}],'FontSize',28,'FontWeight','bold')
    xlabel('Date')
    ylabel('Water Level [cm]')
    axis tight
    grid on
    saveas(gcf,('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/Figures/Gap Search Plot of ' + data_tg{slct_def(i),1} + '.png'))
end
  

%% KML and TG Coordinate Load
load('/home/g21zunadz/Downloads/GNSS-IR/Newest_CORS+TG_GNSS_IR.mat');
s3a_track = readTimeSeries('/r_S3A_tracks.xy');
s3b_track = readTimeSeries('/r_S3B_tracks.xy');
J_track = readTimeSeries('/Visu_TP_Tracks_HiRes_GE_V2.asc');
% plot_ground_track([s3a_track.Var1,s3a_track.Var2],[vertcat(data_tg{:,9}),vertcat(data_tg{:,8})],'Indonesia')
figure('Position',get(0,'Screensize'));
geoscatter(s3a_track.Var2,s3a_track.Var1,'filled','MarkerFaceColor',[0 .7 .7])
hold on
geoscatter(s3b_track.Var2,s3b_track.Var1,'filled','MarkerFaceColor',[0 .7 .7])
geoscatter(J_track.Var2,J_track.Var1,'filled')
geoscatter(vertcat(data_tg{:,8}),vertcat(data_tg{:,9}),100,'filled','^')
geolimits([-10.5 9.5],[90 145])

%% TG Coordinate 2nd Dataset Load
tg_2nd = readTimeSeries('/2nd_TG_Dataset.txt');


%% Location Search
for i=1:length(vertcat(data_tg{:,8}))
    sprintf('Processing TG Number %d',i)
    jarak_s3a=sqrt(((s3a_track.Var1-data_tg{(i),9}).^2)+((s3a_track.Var2-data_tg{(i),8}).^2));
    jarak_s3b=sqrt(((s3b_track.Var1-data_tg{(i),9}).^2)+((s3b_track.Var2-data_tg{(i),8}).^2));
    jarak_j=sqrt(((J_track.Var1-data_tg{(i),9}).^2)+((J_track.Var2-data_tg{(i),8}).^2));
    % searching for data with euclidean distance to TG < 20 km
    indnear_s3a{i}=find(jarak_s3a<(30/111.11));
    indnear_s3b{i}=find(jarak_s3b<(30/111.11));
    indnear_j{i}=find(jarak_j<(30/111.11));
    % searching for nearest point with its distance from the TG
    [indnearest_s3a{i},dist_s3a{i}] = dsearchn([s3a_track.Var1 s3a_track.Var2],[data_tg{(i),9} data_tg{(i),8}]);
    dist_s3a{i}=dist_s3a{i}*111.11;
    [indnearest_s3b{i},dist_s3b{i}] = dsearchn([s3b_track.Var1 s3b_track.Var2],[data_tg{(i),9} data_tg{(i),8}]);
    dist_s3b{i}=dist_s3b{i}*111.11;
    [indnearest_j{i},dist_j{i}] = dsearchn([J_track.Var1 J_track.Var2],[data_tg{(i),9} data_tg{(i),8}]);
    dist_j{i}=dist_j{i}*111.11;
end
% Plotting the result of < 30 km
figure('Position',get(0,'Screensize'));
geoscatter(s3a_track.Var2(vertcat(indnear_s3a{:})),s3a_track.Var1(vertcat(indnear_s3a{:})),'filled','MarkerFaceColor',[0 .7 .7])
hold on
geoscatter(s3b_track.Var2(vertcat(indnear_s3b{:})),s3b_track.Var1(vertcat(indnear_s3b{:})),'filled','MarkerFaceColor',[0 .7 .7])
geoscatter(J_track.Var2(vertcat(indnear_j{:})),J_track.Var1(vertcat(indnear_j{:})),'filled')
geoscatter(vertcat(data_tg{:,8}),vertcat(data_tg{:,9}),100,'filled','^')
geolimits([-10.5 9.5],[90 145])
% Plotting the result of nearest point
figure('Position',get(0,'Screensize'));
geoscatter(s3a_track.Var2(vertcat(indnearest_s3a{:})),s3a_track.Var1(vertcat(indnearest_s3a{:})),'filled','MarkerFaceColor',[0 .7 .7])
hold on
geoscatter(s3b_track.Var2(vertcat(indnearest_s3b{:})),s3b_track.Var1(vertcat(indnearest_s3b{:})),'filled','MarkerFaceColor',[0 .7 .7])
geoscatter(J_track.Var2(vertcat(indnearest_j{:})),J_track.Var1(vertcat(indnearest_j{:})),'filled')
geoscatter(vertcat(data_tg{:,8}),vertcat(data_tg{:,9}),100,'filled','^')
geolimits([-10.5 9.5],[90 145])

%% Plotting S3+J123 near 1st TG Dataset
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 10)
load('/home/g21zunadz/Downloads/Computation_Datasets/Definite_Loc_Search/near_j123.mat');
load('/home/g21zunadz/Downloads/Computation_Datasets/Definite_Loc_Search/near_s3.mat');
load('/home/g21zunadz/Downloads/GNSS-IR/Newest_CORS+TG_GNSS_IR.mat');
slctd=(1:46);
pat3='/home/g21zunadz/Downloads/gshhg-bin-2.3.7/'; cd (pat3);
S=gshhs("gshhs_f.b",[-11, 11],[90 145]);
figure
plot ([S.Lon],[S.Lat])
xlim ([90 145])
ylim ([-11 11])
title ('Proximity Map of Altimetry Track near 1^s^t Set Tide Gauges in Indonesia')
xlabel('Longitude [°]')
ylabel('Latitude [°]')
grid on
hold on
scatter(vertcat(data_tg{:,10}),vertcat(data_tg{:,9}),100,'filled','diamond')
scatter(vertcat(lon_near_j123{:}),vertcat(lat_near_j123{:}),75,'filled','^');
scatter(vertcat(lon_near_s3{:}),vertcat(lat_near_s3{:}),75,'filled','hexagram');
legend('Coastline','TG','J123','S3')
% slct_all=[3 5 6 7 11 15 17 18 19 21 22 26 27 30 32 37 39 40 42 43 45];
text(vertcat(data_tg{:,10})-2.7, vertcat(data_tg{:,9})+0.005, vertcat(data_tg{:,1}),'fontsize',15);

%% Plotting S3+J123 near 2nd TG Dataset
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 10)
load('/home/g21zunadz/Downloads/Computation_Datasets/Definite_Loc_Search/near_j123_2nd.mat');
load('/home/g21zunadz/Downloads/Computation_Datasets/Definite_Loc_Search/near_s3_2nd.mat');
tg_2nd = readTimeSeries('/2nd_TG_Dataset.txt');
slctd=(1:70);
pat3='/home/g21zunadz/Downloads/gshhg-bin-2.3.7/'; cd (pat3);
S=gshhs("gshhs_f.b",[-11, 11],[90 145]);
figure
plot ([S.Lon],[S.Lat])
xlim ([90 145])
ylim ([-11 11])
title ('Proximity Map of Altimetry Track near 2^n^d Set of Tide Gauges in Indonesia')
xlabel('Longitude [°]')
ylabel('Latitude [°]')
grid on
hold on
scatter(tg_2nd.Var3,tg_2nd.Var2,100,'filled','diamond')
scatter(vertcat(lon_near_j123{:}),vertcat(lat_near_j123{:}),75,'filled','^');
scatter(vertcat(lon_near_s3{:}),vertcat(lat_near_s3{:}),75,'filled','hexagram');
legend('Coastline','TG','J123','S3')
% slct_all=[3 5 6 7 11 15 17 18 19 21 22 26 27 30 32 37 39 40 42 43 45];
% text(vertcat(data_tg{slctd,9})-2.7, vertcat(data_tg{slctd,8})+0.005, vertcat(data_tg{slctd,1}),'fontsize',15);

%% Data Selection out of 19 Stations
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend.mat')
slctd_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];

% ALES Data
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/Raw_Alt_AL.mat') % ALES
% Data Selection
for i=1:length(slctd_def)
    sprintf('Processing TG of %s',data_tg{slctd_def(i),1})
    %for AL
    jarak=sqrt(((lon_al-data_tg{slctd_def(i),10}).^2)+((lat_al-data_tg{slctd_def(i),9}).^2));
    % searching for data with euclidean distance to TG < 20 km
    indnear=find(jarak<(20/111.11));
    lon_near_al{i}=lon_al(indnear);
    lat_near_al{i}=lat_al(indnear);
    time_near_al{i}=time_al(indnear);
    ssh_near_al{i}=ssh_al(indnear);
    otide_near_al{i}=otide_al(indnear);
    ltide_near_al{i}=ltide_al(indnear);
    mss_near_al{i}=mss_al(indnear);
    dist_near_al{i}=dist_al(indnear);
    swh_near_al{i}=swh_al(indnear);
    stdalt_near_al{i}=stdalt_al(indnear);
    % searching for data with distance to the coast < 20 km
    ind_flag=find(dist_near_al{i}<=20);
    slct_lon_near_al{i}=lon_near_al{i}(ind_flag);
    slct_lat_near_al{i}=lat_near_al{i}(ind_flag);
    slct_time_near_al{i}=time_near_al{i}(ind_flag);
    slct_ssh_near_al{i}=ssh_near_al{i}(ind_flag);
    slct_otide_near_al{i}=otide_near_al{i}(ind_flag);
    slct_ltide_near_al{i}=ltide_near_al{i}(ind_flag);
    slct_mss_near_al{i}=mss_near_al{i}(ind_flag);
    slct_dist_near_al{i}=dist_near_al{i}(ind_flag);
    slct_swh_near_al{i}=swh_near_al{i}(ind_flag);
    slct_stdalt_near_al{i}=stdalt_near_al{i}(ind_flag);
    % searching for data according to recommended params --> located > 3 km from coast, SSH-MSS < 2.5 m; SWH < 11 m, stdalt < 0.2
    ind_dist=find(slct_dist_near_al{i}>3 & (abs(slct_ssh_near_al{i}-slct_mss_near_al{i})<2.5) & slct_swh_near_al{i} < 11 & slct_stdalt_near_al{i} < 0.2);
    slct_dist_lon_near_al{i}=slct_lon_near_al{i}(ind_dist);
    slct_dist_lat_near_al{i}=slct_lat_near_al{i}(ind_dist);
    slct_dist_time_near_al{i}=slct_time_near_al{i}(ind_dist);
    slct_dist_ssh_near_al{i}=slct_ssh_near_al{i}(ind_dist);
    slct_dist_otide_near_al{i}=slct_otide_near_al{i}(ind_dist);
    slct_dist_ltide_near_al{i}=slct_ltide_near_al{i}(ind_dist);
    slct_dist_mss_near_al{i}=slct_mss_near_al{i}(ind_dist);
    slct_dist_dist_near_al{i}=slct_dist_near_al{i}(ind_dist);
    slct_dist_swh_near_al{i}=slct_swh_near_al{i}(ind_dist);
    slct_dist_stdalt_near_al{i}=slct_stdalt_near_al{i}(ind_dist);
    % scatter(slct_dist_lon_near{i,j},slct_dist_lat_near{i,j},'d','filled')
    % sprintf('Processing Point Number %d',j)
%     hold on
    num_tim_orig(i)=length(vertcat(time_near_al{i})); %number of data near (<20 km) TGs
    num_tim_dist(i)=length(vertcat(slct_time_near_al{i})); %number of data near coast (<20 km)
    num_tim_dist_flag(i)=length(vertcat(slct_dist_time_near_al{i})); %number of data flagged 'OK'
%     scatter(vertcat(lon_near_al{i}),vertcat(lat_near_al{i}),'black','d','filled')
%     scatter(vertcat(slct_lon_near_al{i}),vertcat(slct_lat_near_al{i}),'red','^','filled')
%     scatter(vertcat(slct_dist_lon_near_al{i}),vertcat(slct_dist_lat_near_al{i}),'green','pentagram','filled')
%     scatter(data_tg{slctd(i),9},data_tg{slctd(i),8},'hexagram','filled')
end

% X-TRACK/ALES Data
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/Raw_Alt_XA.mat') % X-TRACK/ALES
tic
for i=1:19 % changed to number that we wanted to split the computation
    sprintf(['Processing TG  %s'],data_tg{slctd_def(i),1})
    for j=1:length(lat_xa)
        lons=lon_xa{j};
        lats=lat_xa{j};
        timess=times_xa{j};
        slas=sla_xa{j};
        tides=tide_xa{j};
        dacs=dac_xa{j};
        msss=mss_xa{j};
        dists=dist_xa{j};
        flags=flag_xa{j};
        jarak=sqrt(((lons-data_tg{slctd_def(i),10}).^2)+((lats-data_tg{slctd_def(i),9}).^2));
        % searching for data with euclidean distance to TG < 20 km
        indnear=find(jarak<(20/111.11));
        lon_near_xa{i,j}=lons(indnear);
        lat_near_xa{i,j}=lats(indnear);
        time_near_xa{i,j}=timess(:,indnear); %nbcycles, (:,indnear)
        sla_near_xa{i,j}=slas(:,indnear); %nbcycles, (:,indnear) 
        tide_near_xa{i,j}=tides(:,indnear); %nbcycles, (:,indnear)
        dac_near_xa{i,j}=dacs(:,indnear); %nbcycles, (:,indnear)
        mss_near_xa{i,j}=msss(indnear);
        dist_near_xa{i,j}=dists(indnear);
        flag_near_xa{i,j}=flags(indnear);
        dist_tg_near_xa{i,j}=jarak(indnear);
        % scatter(lon_near{i,j},lat_near{i,j},'d','filled')
        % searching for data with distance to the coast < 20 km
        ind_flag=find(dist_near_xa{i,j}<=20000);
        slct_lon_near_xa{i,j}=lon_near_xa{i,j}(ind_flag);
        slct_lat_near_xa{i,j}=lat_near_xa{i,j}(ind_flag);
        slct_time_near_xa{i,j}=time_near_xa{i,j}(:,ind_flag); %2D
        slct_sla_near_xa{i,j}=sla_near_xa{i,j}(:,ind_flag); %2D
        slct_tide_near_xa{i,j}=tide_near_xa{i,j}(:,ind_flag); %2D
        slct_dac_near_xa{i,j}=dac_near_xa{i,j}(:,ind_flag); %2D
        slct_mss_near_xa{i,j}=mss_near_xa{i,j}(ind_flag);
        slct_dist_near_xa{i,j}=dist_near_xa{i,j}(ind_flag);
        slct_flag_near_xa{i,j}=flag_near_xa{i,j}(ind_flag);
        % scatter(slct_lon_near{i,j},slct_lat_near{i,j},'d','filled')
        % searching for data flagged 'OK' --> located > 4 km from coast
        ind_dist=find(slct_flag_near_xa{i,j}==0);
        slct_dist_lon_near_xa{i,j}=slct_lon_near_xa{i,j}(ind_dist);
        slct_dist_lat_near_xa{i,j}=slct_lat_near_xa{i,j}(ind_dist);
        slct_dist_time_near_xa{i,j}=slct_time_near_xa{i,j}(:,ind_dist);
        slct_dist_sla_near_xa{i,j}=slct_sla_near_xa{i,j}(:,ind_dist);
        slct_dist_tide_near_xa{i,j}=slct_tide_near_xa{i,j}(:,ind_dist);
        slct_dist_dac_near_xa{i,j}=slct_dac_near_xa{i,j}(:,ind_dist);
        slct_dist_mss_near_xa{i,j}=slct_mss_near_xa{i,j}(ind_dist);
        slct_dist_dist_near_xa{i,j}=slct_dist_near_xa{i,j}(ind_dist);
        slct_dist_flag_near_xa{i,j}=slct_flag_near_xa{i,j}(ind_dist);
        % scatter(slct_dist_lon_near{i,j},slct_dist_lat_near{i,j},'d','filled')
        % sprintf('Processing Point Number %d',j)
    end
    % hold on
    tim_orig=horzcat(time_near_xa{i,:});
    num_tim_orig(i)=length(tim_orig(:));
    tim_dist=horzcat(slct_time_near_xa{i,:});
    num_tim_dist(i)=length(tim_dist(:));
    tim_dist_flag=horzcat(slct_dist_time_near_xa{i,:});
    num_tim_dist_flag(i)=length(tim_dist_flag(:));
    num_orig(i)=length(vertcat(lon_near_xa{i,:})); %number of data near (<20 km) TGs
    num_dist(i)=length(vertcat(slct_lon_near_xa{i,:})); %number of data near coast (<20 km)
    num_dist_flag(i)=length(vertcat(slct_dist_lon_near_xa{i,:})); %number of data flagged 'OK'
% end
%     scatter(vertcat(lon_near_xa{i,:}),vertcat(lat_near_xa{i,:}),'black','d','filled')
%     scatter(vertcat(slct_lon_near_xa{i,:}),vertcat(slct_lat_near_xa{i,:}),'red','^','filled')
%     scatter(vertcat(slct_dist_lon_near_xa{i,:}),vertcat(slct_dist_lat_near_xa{i,:}),'green','pentagram','filled')
%     scatter(data_tg{slctd(i),9},data_tg{slctd(i),8},'hexagram','filled')
    % storing data into a compact matrices for all three data
    % 'Near' Data <=20 km from TG
    lon_orig{i}=vertcat(lon_near_xa{i,:});
    lat_orig{i}=vertcat(lat_near_xa{i,:});
    time_orig{i}=horzcat(time_near_xa{i,:}) + datetime(1950,1,1,00,00,00);
    sla_orig{i}=horzcat(sla_near_xa{i,:});
    tide_orig{i}=horzcat(tide_near_xa{i,:});
    dac_orig{i}=horzcat(dac_near_xa{i,:});
    mss_orig{i}=vertcat(mss_near_xa{i,:});
    dist_orig{i}=vertcat(dist_near_xa{i,:});
    flag_orig{i}=vertcat(flag_near_xa{i,:});
    % 'Near' Data <=20 km from Coast
    lon_dist{i}=vertcat(slct_lon_near_xa{i,:});
    lat_dist{i}=vertcat(slct_lat_near_xa{i,:});
    time_dist{i}=horzcat(slct_time_near_xa{i,:}) + datetime(1950,1,1,00,00,00);
    sla_dist{i}=horzcat(slct_sla_near_xa{i,:});
    tide_dist{i}=horzcat(slct_tide_near_xa{i,:});
    dac_dist{i}=horzcat(slct_dac_near_xa{i,:});
    mss_dist{i}=vertcat(slct_mss_near_xa{i,:});
    dist_dist{i}=vertcat(slct_dist_near_xa{i,:});
    flag_dist{i}=vertcat(slct_flag_near_xa{i,:});
    % Data Flagged 'OK'
    lon_dist_flag{i}=vertcat(slct_dist_lon_near_xa{i,:});
    lat_dist_flag{i}=vertcat(slct_dist_lat_near_xa{i,:});
    time_dist_flag{i}=horzcat(slct_dist_time_near_xa{i,:}) + datetime(1950,1,1,00,00,00);
    sla_dist_flag{i}=horzcat(slct_dist_sla_near_xa{i,:}); %option#3 for Alt
    tide_dist_flag{i}=horzcat(slct_dist_tide_near_xa{i,:});
    dac_dist_flag{i}=horzcat(slct_dist_dac_near_xa{i,:});
    mss_dist_flag{i}=vertcat(slct_dist_mss_near_xa{i,:});
    dist_dist_flag{i}=vertcat(slct_dist_dist_near_xa{i,:});
    flag_dist_flag{i}=vertcat(slct_dist_flag_near_xa{i,:});
    twle_dist_flag{i}=sla_dist_flag{i}+dac_dist_flag{i}+tide_dist_flag{i}+repmat(mss_dist_flag{i}',length(sla_dist_flag{i}),1); 
    %option#1 for Alt
end
% save('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Mar_2023/XA.mat',"v7.3");
toc

% CMEMS Data
% Data Selection --> needs to be used each time before combination

% load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/NM_J1.mat') %J1
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/NM_J2.mat') %J2
% load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Jan_2023/NM_J3.mat') %J3
for i=1:length(slctd_def)
    sprintf('Processing TG Number %d',i)
    %for NM
    for j=1:length(lat_nm_2)
        %for XA
        lons=lon_nm_2{j};
        lats=lat_nm_2{j};
        timess=times_nm_2{j};
        slau=sla_unf_nm_2{j};
        slaf=sla_fil_nm_2{j};
        otides=oc_tide_nm_2{j};
        itides=in_tide_nm_2{j};
        dacs=dac_nm_2{j};
        lwes=lwe_nm_2{j};
        % jarak=sqrt(((lons-tg_2nd.Var3(i)).^2)+((lats-tg_2nd.Var2(i)).^2));
        jarak=sqrt(((lons-data_tg{slctd_def(i),10}).^2)+((lats-data_tg{slctd_def(i),9}).^2));
        % searching for data with euclidean distance to TG < 20 km
        indnear=find(jarak<(20/111.11));
        lon_near_nm_2{i,j}=lons(indnear);
        lat_near_nm_2{i,j}=lats(indnear);
        time_near_nm_2{i,j}=timess(indnear); %nbcycles, (:,indnear)
        slau_near_nm_2{i,j}=slau(indnear); %nbcycles, (:,indnear) 
        slaf_near_nm_2{i,j}=slaf(indnear);
        otide_near_nm_2{i,j}=otides(indnear); %nbcycles, (:,indnear)
        itide_near_nm_2{i,j}=itides(indnear);
        dac_near_nm_2{i,j}=dacs(indnear); %nbcycles, (:,indnear)
        lwe_near_nm_2{i,j}=lwes(indnear); %nbcycles, (:,indnear)
        dist_tg_near_nm_2{i,j}=jarak(indnear);
    end
%     hold on
%     scatter(vertcat(lon_near_nm_3{i,:}),vertcat(lat_near_nm_3{i,:}),'d','filled')
% test{i}=vertcat(lon_near_nm_3{i,:});
% lon_near_nm{i}=vertcat(lon_near_nm_3{i,:});
% uniq_lon_nm{i}=unique(lon_near_nm{i},'stable');
% num_lon_near(i)=length(lon_near_nm{i});
% lat_near_nm{i}=vertcat(lat_near_nm_3{i,:});
% uniq_lat_nm{i}=unique(lat_near_nm{i},'stable');
% time_near_nm{i}=vertcat(time_near_nm_3{i,:});
% num_lat_near(i)=length(lat_near_nm{i});
% dist_near{i}=vertcat(dist_tg_near_nm_3{i,:});
end

% Data Aggregation
figure
for k=1:length(slctd_def)
    lon_near_nm{k}=[vertcat(lon_near_nm_1{k,:}); vertcat(lon_near_nm_2{k,:}); vertcat(lon_near_nm_3{k,:})];
    lat_near_nm{k}=[vertcat(lat_near_nm_1{k,:}); vertcat(lat_near_nm_2{k,:}); vertcat(lat_near_nm_3{k,:})];
    time_near_nm{k}=[vertcat(time_near_nm_1{k,:}); vertcat(time_near_nm_2{k,:}); vertcat(time_near_nm_3{k,:})];
    slau_near_nm{k}=[vertcat(slau_near_nm_1{k,:}); vertcat(slau_near_nm_2{k,:}); vertcat(slau_near_nm_3{k,:})];
    slaf_near_nm{k}=[vertcat(slaf_near_nm_1{k,:}); vertcat(slaf_near_nm_2{k,:}); vertcat(slaf_near_nm_3{k,:})];
    otide_near_nm{k}=[vertcat(otide_near_nm_1{k,:}); vertcat(otide_near_nm_2{k,:}); vertcat(otide_near_nm_3{k,:})];
    itide_near_nm{k}=[vertcat(itide_near_nm_1{k,:}); vertcat(itide_near_nm_2{k,:}); vertcat(itide_near_nm_3{k,:})];
    dac_near_nm{k}=[vertcat(dac_near_nm_1{k,:}); vertcat(dac_near_nm_2{k,:}); vertcat(dac_near_nm_3{k,:})];
    lwe_near_nm{k}=[vertcat(lwe_near_nm_1{k,:}); vertcat(lwe_near_nm_2{k,:}); vertcat(lwe_near_nm_3{k,:})];
    dist_tg_near_nm{k}=[vertcat(dist_tg_near_nm_1{k,:}); vertcat(dist_tg_near_nm_2{k,:}); vertcat(dist_tg_near_nm_3{k,:})];
    hold on
    scatter(vertcat(time_near_nm{k}),vertcat(slaf_near_nm{k})+k,'d','filled');
    count_nm(k)=length(lon_near_nm{k});
    count_unique_nm(k)=length(unique(lon_near_nm{k},'stable'));
    lon_unique_nm{k}=unique(lon_near_nm{k},'stable');
    lat_unique_nm{k}=unique(lat_near_nm{k},'stable');
end
figure
bar(count_nm)

% Checking
figure
for k=1:length(slctd_def)
    hold on
    scatter(vertcat(time_near_nm{k}),vertcat(slaf_near_nm{k})+k,'d','filled');
    count_nm(k)=length(lon_near_nm{k});
end

figure
bar(count_nm)

%% DAC computation for ALES

cd('/home/g21zunadz/Downloads/DAC');
load('dac_all_mar_2023.mat');
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend.mat')
slctd_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];
ans_1=data_tg(slctd_def(:),10);
lon_tg=vertcat(ans_1{:});
ans_2=data_tg(slctd_def(:),9);
lat_tg=vertcat(ans_2{:});

% Selecting lat and lon index for each TG stations
ind_lon=dsearchn(lon_slct{1},lon_tg);
ind_lat=dsearchn(lat_slct{1},lat_tg);

% Interpolation to ALES timestamp
load('dac_2008_2022_19TG.mat')
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Mar_2023/Workspace_selected_ALES.mat', 'slct_dist_time_near_al')
for i=1:19
    tim_dac=horzcat(dt_dac{1,:});
    dat_dac=horzcat(dt_dac{i+1,:});
    dacc=interp1(tim_dac,dat_dac,slct_dist_time_near_al{i},'linear');
    dacc(isnan(dacc))=0;
    interp_dac{i}=dacc;
end

%% Interpolation for each dataset according to TG Data

% ALES
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Mar_2023/Workspace_selected_ALES.mat')
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend_h0tg.mat')
slctd_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];
% Computing Edited SLA
for i=1:19
    slct_dist_sla_near_al{i}=slct_dist_ssh_near_al{i}-slct_dist_mss_near_al{i}+slct_dist_otide_near_al{i}+slct_dist_ltide_near_al{i}+interp_dac{i};
    slct_dist_sla_no_dac_near_al{i}=slct_dist_ssh_near_al{i}-slct_dist_mss_near_al{i}+slct_dist_otide_near_al{i}+slct_dist_ltide_near_al{i};
end
% Starting to compute the location
for i=1:length(slctd_def)
    time_tg{i}=(data_tg{slctd_def(i),23});
    wat_lvl_tg{i}=(data_tg{slctd_def(i),22})./100+data_tg{slctd_def(i),46}; %option#1 for TG
    mss_tg(i)=mean(wat_lvl_tg{i},'omitnan');
    sla_tg{i}=wat_lvl_tg{i}-mss_tg(i); %option#2 and #3 for TG USED
    mean_sla_tg(i)=mean(sla_tg{i},'omitnan');
    % sla_edited_dist_flag{i}=slct_dist_ssh_near_al{i}-slct_dist_mss_near_al{i}+slct_dist_otide_near_al{i}+slct_dist_ltide_near_al{i}; %option#2 for Alt USED
end

% Computing data near unique location of NM
for i=1:length(slctd_def)
    for j=1:length(lon_unique_nm{i})
        jarak_titik=sqrt(((slct_dist_lon_near_al{i}-lon_unique_nm{i}(j)).^2)+((slct_dist_lat_near_al{i}-lat_unique_nm{i}(j)).^2));
        ind_dekat=find(jarak_titik<(3/111.11));
        slct_dist_src_lon_near_al{i,j}=slct_dist_lon_near_al{i}(ind_dekat);
        slct_dist_src_lat_near_al{i,j}=slct_dist_lat_near_al{i}(ind_dekat);
        slct_dist_src_time_near_al{i,j}=slct_dist_time_near_al{i}(ind_dekat);
        slct_dist_src_ssh_near_al{i,j}=slct_dist_ssh_near_al{i}(ind_dekat);
        slct_dist_src_otide_near_al{i,j}=slct_dist_otide_near_al{i}(ind_dekat);
        slct_dist_src_ltide_near_al{i,j}=slct_dist_ltide_near_al{i}(ind_dekat);
        slct_dist_src_mss_near_al{i,j}=slct_dist_mss_near_al{i}(ind_dekat);
        slct_dist_src_dist_near_al{i,j}=slct_dist_dist_near_al{i}(ind_dekat);
        slct_dist_src_swh_near_al{i,j}=slct_dist_swh_near_al{i}(ind_dekat);
        slct_dist_src_stdalt_near_al{i,j}=slct_dist_stdalt_near_al{i}(ind_dekat);
        slct_dist_src_sla_near_al{i,j}=slct_dist_sla_near_al{i}(ind_dekat);
        slct_dist_src_sla_no_dac_near_al{i,j}=slct_dist_sla_no_dac_near_al{i}(ind_dekat);
        num_tim_dist_flag_src(i)=length(vertcat(slct_dist_src_time_near_al{i})); %number of data flagged 'OK'

        % sorting data according to the time
        [slct_dist_src_time_near_al{i,j},ind_urut_time]=sort(slct_dist_src_time_near_al{i,j});
        slct_dist_src_lon_near_al{i,j}=slct_dist_src_lon_near_al{i,j}(ind_urut_time);
        slct_dist_src_lat_near_al{i,j}=slct_dist_src_lat_near_al{i,j}(ind_urut_time);
        slct_dist_src_ssh_near_al{i,j}=slct_dist_src_ssh_near_al{i,j}(ind_urut_time);
        slct_dist_src_otide_near_al{i,j}=slct_dist_src_otide_near_al{i,j}(ind_urut_time);
        slct_dist_src_ltide_near_al{i,j}=slct_dist_src_ltide_near_al{i,j}(ind_urut_time);
        slct_dist_src_mss_near_al{i,j}=slct_dist_src_mss_near_al{i,j}(ind_urut_time);
        slct_dist_src_dist_near_al{i,j}=slct_dist_src_dist_near_al{i,j}(ind_urut_time);
        slct_dist_src_swh_near_al{i,j}=slct_dist_src_swh_near_al{i,j}(ind_urut_time);
        slct_dist_src_stdalt_near_al{i,j}=slct_dist_src_stdalt_near_al{i,j}(ind_urut_time);
        slct_dist_src_sla_near_al{i,j}=slct_dist_src_sla_near_al{i,j}(ind_urut_time);
        slct_dist_src_sla_no_dac_near_al{i,j}=slct_dist_src_sla_no_dac_near_al{i,j}(ind_urut_time);
    end
end

% Plotting for each location on each TG
for i=1:19
    figure
    hold on
    for j=1:length(lon_unique_nm{i})
        % scatter(vertcat(slct_dist_src_lon_near_al{i,j}),vertcat(slct_dist_src_lat_near_al{i,j}));
        plot(vertcat(slct_dist_src_time_near_al{i,j}),vertcat(slct_dist_src_sla_near_al{i,j})+j)
        plot(vertcat(slct_dist_src_time_near_al{i,j}),vertcat(slct_dist_src_sla_no_dac_near_al{i,j})+j)
        legend({'SLA with DAC','SLA without DAC'})
    end
end

for i=3:19 %index 2 is bad
    [time_tg_unique{i},ia]=unique(time_tg{i},'stable');
    sprintf('Processing TG Number %d',i)
    for j=1:length(lon_unique_nm{i})
        % figure
        ind_inc=find(slct_dist_src_time_near_al{i,j}>=time_tg{i}(1));
    
        % Option#2 --> SLA_Edited v SLA on TG USED
        time_dist_flag_tg{i,j}=slct_dist_src_time_near_al{i,j}(ind_inc);
        sla_edit_dist_flag_tg{i,j}=slct_dist_src_sla_near_al{i,j}(ind_inc);
        sla_edit_nodac_dist_flag_tg{i,j}=slct_dist_src_sla_no_dac_near_al{i,j}(ind_inc);
        interp_sla_tg_4{i,j}=interp1(time_tg_unique{i},sla_tg{i}(ia),time_dist_flag_tg{i,j},'linear');
        % for one with DAC applied
        d=corrcoef(sla_edit_dist_flag_tg{i,j}(~isnan(interp_sla_tg_4{i,j})),interp_sla_tg_4{i,j}(~isnan(interp_sla_tg_4{i,j})));
        corr2_4_al{i,j}=d(2,1);
        dssh2_4_al{i,j}=(sla_edit_dist_flag_tg{i,j}(~isnan(interp_sla_tg_4{i,j}))-mean(sla_edit_dist_flag_tg{i,j}(~isnan(interp_sla_tg_4{i,j})),'omitnan'))-(interp_sla_tg_4{i,j}(~isnan(interp_sla_tg_4{i,j}))-mean(interp_sla_tg_4{i,j}(~isnan(interp_sla_tg_4{i,j})),'omitnan'));
        std_dssh2_4_al{i,j}=std(dssh2_4_al{i,j});
        bias_dssh2_4_al{i,j}=median(dssh2_4_al{i,j});
        mad_dssh2_4_al{i,j}=mad(dssh2_4_al{i,j},1);
        unc_point_al{i,j}=median(slct_dist_src_stdalt_near_al{i,j}(ind_inc));
        num_each_point_al{i,j}=length(sla_edit_dist_flag_tg{i,j});
        avg_corr(i)=mean(vertcat(corr2_4_al{i,:}),'omitnan');
        std_corr(i)=std(vertcat(corr2_4_al{i,:}),'omitnan');
        avg_num_data(i)=mean(vertcat(num_each_point_al{i,:}));
        tot_num_data(i)=sum(vertcat(num_each_point_al{i,:}));
        num_of_point(i)=length(vertcat(num_each_point_al{i,:}));
        avg_std(i)=mean(vertcat(std_dssh2_4_al{i,:}),'omitnan');
        avg_mad(i)=mean(vertcat(mad_dssh2_4_al{i,:}),'omitnan');
        std_std(i)=std(vertcat(std_dssh2_4_al{i,:}),'omitnan');
        std_mad(i)=std(vertcat(mad_dssh2_4_al{i,:}),'omitnan');
        avg_dist{i,j}=mean(slct_dist_src_dist_near_al{i,j});

        % for one without DAC applied
        d=corrcoef(sla_edit_nodac_dist_flag_tg{i,j}(~isnan(interp_sla_tg_4{i,j})),interp_sla_tg_4{i,j}(~isnan(interp_sla_tg_4{i,j})));
        corr2_4_nodac_al{i,j}=d(2,1);
        dssh2_4_nodac_al{i,j}=(sla_edit_nodac_dist_flag_tg{i,j}(~isnan(interp_sla_tg_4{i,j}))-mean(sla_edit_nodac_dist_flag_tg{i,j}(~isnan(interp_sla_tg_4{i,j})),'omitnan'))-(interp_sla_tg_4{i,j}(~isnan(interp_sla_tg_4{i,j}))-mean(interp_sla_tg_4{i,j}(~isnan(interp_sla_tg_4{i,j})),'omitnan'));
        std_dssh2_nodac_4_al{i,j}=std(dssh2_4_al{i,j});
        bias_dssh2_nodac_4_al{i,j}=median(dssh2_4_al{i,j});
        mad_dssh2_nodac_4_al{i,j}=mad(dssh2_4_al{i,j},1);
        num_each_point_nodac_al{i,j}=length(sla_edit_nodac_dist_flag_tg{i,j});
        avg_nodac_corr(i)=mean(vertcat(corr2_4_al{i,:}),'omitnan');
        std_nodac_corr(i)=std(vertcat(corr2_4_al{i,:}),'omitnan');
        avg_num_nodac_data(i)=mean(vertcat(num_each_point_al{i,:}));
        tot_num_nodac_data(i)=sum(vertcat(num_each_point_al{i,:}));
        num_of_point_nodac(i)=length(vertcat(num_each_point_al{i,:}));
        avg_nodac_std(i)=mean(vertcat(std_dssh2_4_al{i,:}),'omitnan');
        avg_nodac_mad(i)=mean(vertcat(mad_dssh2_4_al{i,:}),'omitnan');
        std_nodac_std(i)=std(vertcat(std_dssh2_4_al{i,:}),'omitnan');
        std_nodac_mad(i)=std(vertcat(mad_dssh2_4_al{i,:}),'omitnan');
        avg_nodac_dist{i,j}=mean(slct_dist_src_dist_near_al{i,j});
        % Graph of each Point
%         figure
%         hold on
%         plot(time_dist_flag_tg{i,j},sla_edit_dist_flag_tg{i,j})
%         plot(time_dist_flag_tg{i,j},interp_sla_tg_4{i,j})
    end

%     %Options#2
%     figure
%     hold on
%     scatter(dist_tg_sort_unique_nm{:,i}.*111.11,vertcat(corr2_4{i,:}))
%     title('Graph of Corr Coef of SLA Edited from X-TRACK/ALES versus SLA from TG','FontSize',15,'FontWeight','bold')
%     xlabel('Distance [km]','FontSize',15,'FontWeight','bold')
%     ylabel('SLA Edited [m]','FontSize',15,'FontWeight','bold')
%     % legend('Spline','Makima','Nearest','Linear','FontSize',13)
%     ax = gca;
%     ax.FontSize = 17;
end

% Plotting the result
% Scatter Plot for Value v Distance from the Coast
addpath(genpath('/home/g21zunadz/Downloads/MWCC_Exercises/calval_MGS05/lib/matlab/'));
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 18)

ans1=vertcat(avg_dist(:));
dist=vertcat(ans1{:});

% corr
ans=vertcat(corr2_4_al(:));
corr_dac=vertcat(ans{:});
ans=vertcat(corr2_4_nodac_al(:));
corr_nodac=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist,corr_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist,corr_nodac,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
title('Plot between Pearsons Correlation Value and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Pearsons' Correlation Value")
legend ({'with DAC', 'without DAC'})
ylim ([0.4 1])

% std
ans=vertcat(std_dssh2_4_al(:));
std_dac=vertcat(ans{:}).*100;
ans=vertcat(std_dssh2_nodac_4_al(:));
std_nodac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,std_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist,std_nodac,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
title('Plot between Standard Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Standard Deviation [cm]")
legend ({'with DAC', 'without DAC'})
ylim ([0 60])
xlim ([2 18])

% Bias
ans=vertcat(bias_dssh2_4_al(:));
bias_dac=vertcat(ans{:}).*100;
ans=vertcat(bias_dssh2_nodac_4_al(:));
bias_nodac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,bias_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist,bias_nodac,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
title('Plot between Bias and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Bias [cm]")
legend ({'with DAC', 'without DAC'})
ylim ([-8 20])
xlim ([2 18])

% mad
ans=vertcat(mad_dssh2_4_al(:));
mad_dac=vertcat(ans{:}).*100;
ans=vertcat(mad_dssh2_nodac_4_al(:));
mad_nodac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,mad_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist,mad_nodac,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
title('Plot between Median Absolute Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("MAD [cm]")
legend ({'with DAC', 'without DAC'})
ylim ([2 16])
xlim ([2 18])

% uncertainty level
ans=vertcat(unc_point_al(:));
unc_dac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,unc_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
title('Plot between Altimetry Data Uncertainty and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Data Uncertainty [cm]")
% legend ({'with DAC', 'without DAC'})
ylim ([6 15])
xlim ([2 18])

% Num of Obs
ans=vertcat(num_each_point_al(:));
num_dac=vertcat(ans{:});
ans=vertcat(num_each_point_nodac_al(:));
num_nodac=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist,num_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist,num_nodac,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
title('Plot between Number of Observation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Number of Observation")
legend ({'with DAC', 'without DAC'})
ylim ([-10 320])
xlim ([2 18])

% X-TRACK/ALES
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Mar_2023/Workspace_selected_XA.mat')
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend_h0tg.mat')
slctd_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];

% Starting to compute the location
for i=1:length(slctd_def)
    time_tg{i}=(data_tg{slctd_def(i),23});
    wat_lvl_tg{i}=(data_tg{slctd_def(i),22})./100+data_tg{slctd_def(i),46}; %option#1 for TG
    mss_tg(i)=mean(wat_lvl_tg{i},'omitnan');
    sla_tg{i}=wat_lvl_tg{i}-mss_tg(i); %option#2 and #3 for TG USED
    mean_sla_tg(i)=mean(sla_tg{i},'omitnan');
    sla_edited_dist_flag{i}=sla_dist_flag{i}+dac_dist_flag{i}+tide_dist_flag{i}; %option#2 for Alt USED
end

for i=1:19
    [time_tg_unique{i},ia]=unique(time_tg{i},'stable');
    sprintf('Processing TG Number %d',i)
    for j=1:length(time_dist_flag{i}(1,:)) %--> j used to pick every point on each cell (cycle number x point indices)
    % Sorting Data according to time
    [time_dist_flag{i}(:,j),ind_urut_time]=sort(time_dist_flag{i}(:,j));
    % lon_dist_flag{i}(:,j)=lon_dist_flag{i}(ind_urut_time,j);
    % lat_dist_flag{i}(:,j)=lat_dist_flag{i}(ind_urut_time,j);
    sla_dist_flag{i}(:,j)=sla_dist_flag{i}(ind_urut_time,j); %option#3 for Alt
    tide_dist_flag{i}(:,j)=tide_dist_flag{i}(ind_urut_time,j);
    dac_dist_flag{i}(:,j)=dac_dist_flag{i}(ind_urut_time,j);
    % mss_dist_flag{i}(:,j)=mss_dist_flag{i}(ind_urut_time,j);
    % dist_dist_flag{i}(:,j)=dist_dist_flag{i}(ind_urut_time,j);
    % flag_dist_flag{i}(:,j)=flag_dist_flag{i}(ind_urut_time,j);
    sla_edited_dist_flag{i}(:,j)=sla_edited_dist_flag{i}(ind_urut_time,j);

    % Option#2 --> SLA_Edited v SLA on TG USED
    ind_inc=find(time_dist_flag{i}(:,j)>=time_tg{i}(1));
    time_dist_flag_tg{i,j}=time_dist_flag{i}(ind_inc,j);
    sla_edit_dist_flag_tg{i,j}=sla_edited_dist_flag{i}(ind_inc,j);
    interp_sla_tg_4{i,j}=interp1(time_tg_unique{i},sla_tg{i}(ia),time_dist_flag_tg{i,j},'linear');
    d=corrcoef(sla_edit_dist_flag_tg{i,j}(~isnan(sla_edit_dist_flag_tg{i,j})),interp_sla_tg_4{i,j}(~isnan(sla_edit_dist_flag_tg{i,j})));
    corr2_4{i,j}=d(2,1);
    dssh2_4{i,j}=(sla_edit_dist_flag_tg{i,j}(~isnan(sla_edit_dist_flag_tg{i,j}))-mean(sla_edit_dist_flag_tg{i,j}(~isnan(sla_edit_dist_flag_tg{i,j})),'omitnan'))-(interp_sla_tg_4{i,j}(~isnan(sla_edit_dist_flag_tg{i,j}))-mean(interp_sla_tg_4{i,j}(~isnan(sla_edit_dist_flag_tg{i,j})),'omitnan'));
    std_dssh2_4{i,j}=std(dssh2_4{i,j});
    bias_dssh2_4{i,j}=median(dssh2_4{i,j});
    mad_dssh2_4{i,j}=mad(dssh2_4{i,j},1);
    count_point_xa{i,j}=length(sla_edit_dist_flag_tg{i,j});
    end
end

% Plotting the result
% Scatter Plot for Value v Distance from the Coast
addpath(genpath('/home/g21zunadz/Downloads/MWCC_Exercises/calval_MGS05/lib/matlab/'));
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 18)

ans1=vertcat(dist_dist_flag(:));
dist=vertcat(ans1{:})./1000;

% corr
ans=vertcat(corr2_4(:));
corr_dac=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist,corr_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Pearsons Correlation Value and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Pearsons' Correlation Value")
ylim ([0.65 1.02])
xlim ([3.5 18])

% std
ans=vertcat(std_dssh2_4(:));
std_dac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,std_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Standard Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Standard Deviation [cm]")
ylim ([5 40])
xlim ([3.5 18])

% Bias
ans=vertcat(bias_dssh2_4(:));
bias_dac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,bias_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Bias and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Bias [cm]")
ylim ([-8 9])
xlim ([3.5 18])

% mad
ans=vertcat(mad_dssh2_4(:));
mad_dac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,mad_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Median Absolute Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("MAD [cm]")
ylim ([2.5 14])
xlim ([3.5 18])

% Num of Obs
ans=vertcat(count_point_xa(:));
num_dac=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist,num_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Number of Observation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Number of Observation")
ylim ([-10 290])
xlim ([3.5 18])


% CMEMS
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Mar_2023/Workspace_selected_CMEMS_withlwe.mat')
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend_h0tg.mat')
slctd_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];

% Data Selection Process
for i=1:19
    for j=1:length(lon_unique_nm{i})
        ind_find=find(lat_near_nm{i} == lat_unique_nm{i}(j) & lon_near_nm{i} == lon_unique_nm{i}(j));
        lon_sort_nm{i,j}=lon_near_nm{i}(ind_find);
        lat_sort_nm{i,j}=lat_near_nm{i}(ind_find);
        time_sort_nm{i,j}=time_near_nm{i}(ind_find);
        slau_sort_nm{i,j}=slau_near_nm{i}(ind_find);
        slaf_sort_nm{i,j}=slaf_near_nm{i}(ind_find);
        otide_sort_nm{i,j}=otide_near_nm{i}(ind_find);
        itide_sort_nm{i,j}=itide_near_nm{i}(ind_find);
        dac_sort_nm{i,j}=dac_near_nm{i}(ind_find);
        lwe_sort_nm{i,j}=lwe_near_nm{i}(ind_find);
        dist_tg_sort_nm{i,j}=dist_tg_near_nm{i}(ind_find);
        count_unique_point_nm{i,j}=length(dist_tg_near_nm{i}(ind_find));
        sla_edited_dist_nm{i,j}=slaf_sort_nm{i,j}+dac_sort_nm{i,j}+otide_sort_nm{i,j}+itide_sort_nm{i,j}-lwe_sort_nm{i,j};
        diff_filt_nm{i,j}=slaf_sort_nm{i,j}-slau_sort_nm{i,j};
    end
end

% Starting to compute the location
for i=1:length(slctd_def)
    time_tg{i}=(data_tg{slctd_def(i),23});
    wat_lvl_tg{i}=(data_tg{slctd_def(i),22})./100+data_tg{slctd_def(i),46}; %option#1 for TG
    mss_tg(i)=mean(wat_lvl_tg{i},'omitnan');
    sla_tg{i}=wat_lvl_tg{i}-mss_tg(i); %option#2 and #3 for TG USED
    mean_sla_tg(i)=mean(sla_tg{i},'omitnan');
end

for i=1:19 % index 16 is 'bad'
    [time_tg_unique{i},ia]=unique(time_tg{i},'stable');
    sprintf('Processing TG Number %d',i)
    for j=1:length(lon_unique_nm{i})
        ind_inc=find(time_sort_nm{i,j}>=time_tg{i}(1));
    
        % Option#2 --> SLA_Edited v SLA on TG USED
        time_dist_flag_tg{i,j}=time_sort_nm{i,j}(ind_inc);
        sla_edit_dist_flag_tg{i,j}=sla_edited_dist_nm{i,j}(ind_inc);
        interp_sla_tg_4{i,j}=interp1(time_tg_unique{i},sla_tg{i}(ia),time_dist_flag_tg{i,j},'linear');
        d=corrcoef(sla_edit_dist_flag_tg{i,j}(~isnan(interp_sla_tg_4{i,j})),interp_sla_tg_4{i,j}(~isnan(interp_sla_tg_4{i,j})));
        corr2_4_nm{i,j}=d(2,1);
        dssh2_4_nm{i,j}=(sla_edit_dist_flag_tg{i,j}(~isnan(interp_sla_tg_4{i,j}))-mean(sla_edit_dist_flag_tg{i,j}(~isnan(interp_sla_tg_4{i,j})),'omitnan'))-(interp_sla_tg_4{i,j}(~isnan(interp_sla_tg_4{i,j}))-mean(interp_sla_tg_4{i,j}(~isnan(interp_sla_tg_4{i,j})),'omitnan'));
        std_dssh2_4_nm{i,j}=std(dssh2_4_nm{i,j});
        bias_dssh2_4_nm{i,j}=median(dssh2_4_nm{i,j});
        mad_dssh2_4_nm{i,j}=mad(dssh2_4_nm{i,j},1);
        stdalt_nm{i,j}=median(diff_filt_nm{i,j});
        num_each_point_nm{i,j}=length(sla_edit_dist_flag_tg{i,j});
        dist_nm{i,j}=median(dist_tg_sort_nm{i,j});
        lon_nm{i,j}=median(lon_sort_nm{i,j});
        lat_nm{i,j}=median(lat_sort_nm{i,j});
    end
end

% Plotting the result
% Scatter Plot for Value v Distance from the Coast
addpath(genpath('/home/g21zunadz/Downloads/MWCC_Exercises/calval_MGS05/lib/matlab/'));
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 18)
ans1=vertcat(lon_nm(:));
lonn=vertcat(ans1{:});
ans1=vertcat(lat_nm(:));
latt=vertcat(ans1{:});
dist = betterDist2Coast_lola(lonn,latt)./1000;

% corr
ans=vertcat(corr2_4_nm(:));
corr_dac=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist,corr_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Pearsons Correlation Value and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Pearsons' Correlation Value")
ylim ([0.62 1.03])
xlim ([0 18])

% std
ans=vertcat(std_dssh2_4_nm(:));
std_dac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,std_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Standard Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Standard Deviation [cm]")
ylim ([0 40])
xlim ([0 18])

% Bias
ans=vertcat(bias_dssh2_4_nm(:));
bias_dac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,bias_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Bias and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Bias [cm]")
ylim ([-6 12.5])
xlim ([0 18])

% mad
ans=vertcat(mad_dssh2_4_nm(:));
mad_dac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,mad_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Median Absolute Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("MAD [cm]")
ylim ([0 18])
xlim ([0 18])

% uncertainty level
ans=vertcat(stdalt_nm(:));
unc_dac=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist,unc_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Altimetry Data Uncertainty and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Data Uncertainty [cm]")
ylim ([-2 1])
xlim ([0 18])

% Num of Obs
ans=vertcat(num_each_point_nm(:));
num_dac=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist,num_dac,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
title('Plot between Number of Observation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Number of Observation")
ylim ([-5 300])
xlim ([0 18])

%% Computing the final result using various plot

% Computing data near unique location of NM for XA
for i=1:length(slctd_def) %3, 6, 13, 16, 18 are a bad index
    for j=1:length(lon_unique_nm{i})
        jarak_titik=sqrt(((lon_dist_flag{i}-lon_unique_nm{i}(j)).^2)+((lat_dist_flag{i}-lat_unique_nm{i}(j)).^2));
        ind_dekat=find(jarak_titik<(3/111.11));
        % dssh
        dssh2_4_xa{i,j}=dssh2_4(i,ind_dekat(:));
        % time
        time_dist_flag_tg_x{i,j}=time_dist_flag_tg(i,ind_dekat(:));
        time_int=(vertcat(time_dist_flag_tg_x{i,j}(:)));
        time_int2=reshape(vertcat(time_int{:}),[length(vertcat(time_int{1})),length(ind_dekat)]);
        time_dist_flag_tg_xa{i,j}=mean(time_int2,2);
        %sla edit
        sla_edit_dist_flag_tg_x{i,j}=sla_edit_dist_flag_tg(i,ind_dekat(:));
        sla_int=(vertcat(sla_edit_dist_flag_tg_x{i,j}(:)));
        sla_int2=reshape(vertcat(sla_int{:}),[length(vertcat(sla_int{1})),length(ind_dekat)]);
        sla_edit_dist_flag_tg_xa{i,j}=mean(sla_int2,2);
        % num of point
        num_int=(vertcat(dssh2_4_xa{i,j}(:)));
        num_each_point_xa{i,j}=length(vertcat(num_int{:}));
        % distance
        dist_xa_int{i,j}=dist_dist_flag{i}(ind_dekat);
        distt{i,j}=median(dist_xa_int{i,j});
        % corr coeff
        corr_xa_int{i,j}=corr2_4(i,ind_dekat(:));
        corr_int=(vertcat(corr_xa_int{i,j}(:)));
        corr2_4_xa{i,j}=median(vertcat(corr_int{:}));
        % st deviation
        stdd_xa_int{i,j}=std_dssh2_4(i,ind_dekat(:));
        stdd_int=(vertcat(stdd_xa_int{i,j}(:)));
        std_dssh2_4_xa{i,j}=median(vertcat(stdd_int{:}));
        % bias
        bias_xa_int{i,j}=bias_dssh2_4(i,ind_dekat(:));
        bias_int=(vertcat(bias_xa_int{i,j}(:)));
        bias_dssh2_4_xa{i,j}=median(vertcat(bias_int{:}));
        % mad
        mad_xa_int{i,j}=mad_dssh2_4(i,ind_dekat(:));
        mad_int=(vertcat(mad_xa_int{i,j}(:)));
        mad_dssh2_4_xa{i,j}=median(vertcat(mad_int{:}));
    end
end
ans1=vertcat(distt(:));
dist_xa=vertcat(ans1{:});

% Scatter with distance from coast as component
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend_h0tg.mat')
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Mar_2023/Copy_of_Performance_Metrics_All.mat')
slctd_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];
ans1=vertcat(dist_al(:));
dist_al=vertcat(ans1{:});
dist_xa=dist_xa./1000;

% corr
ans=vertcat(corr2_4_al(:));
corr_al=vertcat(ans{:});
ans=vertcat(corr2_4_xa(:));
corr_xa=vertcat(ans{:});
ans=vertcat(corr2_4_nm(:));
corr_nm=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist_al,corr_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,corr_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,corr_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Pearsons Correlation Value and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Pearsons' Correlation Value")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
ylim ([0.4 1.03])

% std
ans=vertcat(std_dssh2_4_al(:));
std_al=vertcat(ans{:}).*100;
ans=vertcat(std_dssh2_4_xa(:));
std_xa=vertcat(ans{:}).*100;
ans=vertcat(std_dssh2_4_nm(:));
std_nm=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist_al,std_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,std_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,std_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Standard Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Standard Deviation [cm]")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
ylim ([0 60])
xlim ([0 18])

% Bias
ans=vertcat(bias_dssh2_4_al(:));
bias_al=vertcat(ans{:}).*100;
ans=vertcat(bias_dssh2_4_xa(:));
bias_xa=vertcat(ans{:}).*100;
ans=vertcat(bias_dssh2_4_nm(:));
bias_nm=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist_al,bias_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,bias_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,bias_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Bias and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Bias [cm]")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
ylim ([-8 20])
xlim ([0 18])

% mad
ans=vertcat(mad_dssh2_4_al(:));
mad_al=vertcat(ans{:}).*100;
ans=vertcat(mad_dssh2_4_xa(:));
mad_xa=vertcat(ans{:}).*100;
ans=vertcat(mad_dssh2_4_nm(:));
mad_nm=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist_al,mad_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,mad_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,mad_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Median Absolute Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("MAD [cm]")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
ylim ([0 18])
xlim ([0 18])

% uncertainty level
ans=vertcat(stdalt_al(:));
unc_al=vertcat(ans{:}).*100;
ans=vertcat(stdalt_nm(:));
unc_nm=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist_al,unc_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_nm,abs(unc_nm),120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Altimetry Data Uncertainty and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Data Uncertainty [cm]")
legend ({'ALES', 'CMEMS'})
ylim ([-1 19])
xlim ([0 18])

% Num of Obs
ans=vertcat(num_each_point_al(:));
num_al=vertcat(ans{:});
ans=vertcat(num_each_point_xa(:));
num_xa=vertcat(ans{:});
ans=vertcat(num_each_point_nm(:));
num_nm=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist_al,num_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,num_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,num_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Number of Observation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Number of Observation")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
set(gca, 'YScale', 'log')
ylim ([-10 320])
xlim ([-1 18])

% Boxplots
addpath(genpath('/home/g21zunadz/Downloads/MWCC_Exercises/calval_MGS05/lib/matlab/'));
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 18)
figure
boxplot([corr_al,corr_xa(1:59),corr_nm],'Labels',{'ALES','X-TRACK/ALES','CMEMS'})
title('Compare Correlation Value from 3 Altimetry Datasets with In-Situ TG')
ylabel("Pearsons' Correlation Value")
figure
boxplot([std_al,std_xa(1:59),std_nm],'Labels',{'ALES','X-TRACK/ALES','CMEMS'})
title('Compare Standard Deviation Value from 3 Altimetry Datasets with In-Situ TG')
ylabel("Standard Deviation [cm]")
figure
boxplot([bias_al,bias_xa(1:59),bias_nm],'Labels',{'ALES','X-TRACK/ALES','CMEMS'})
title('Compare Bias Value from 3 Altimetry Datasets with In-Situ TG')
ylabel("Bias [cm]")
figure
boxplot([mad_al,mad_xa(1:59),mad_nm],'Labels',{'ALES','X-TRACK/ALES','CMEMS'})
title('Compare Median Absolute Deviation Value from 3 Altimetry Datasets with In-Situ TG')
ylabel("Median Absolute Deviation [cm]")
figure
boxplot([num_al,num_xa(1:59),num_nm],'Labels',{'ALES','X-TRACK/ALES','CMEMS'})
title('Compare Number of Observation Value from 3 Altimetry Datasets with In-Situ TG')
ylabel("Number of Observation")

% Time Series of each point
addpath(genpath('/home/g21zunadz/Downloads/MWCC_Exercises/calval_MGS05/lib/matlab/'));
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Mar_2023/Copy_of_Performance_Metrics_All.mat')
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend_h0tg.mat')
slctd_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 18)
    k=1;
for i=12:length(slctd_def) %3, 10, 11 has problem
    for j=1:length(lon_unique_nm{i})
        time_tg{i}=(data_tg{slctd_def(i),23});
        wat_lvl_tg{i}=(data_tg{slctd_def(i),22})./100+data_tg{slctd_def(i),46}; %option#1 for TG
        mss_tg(i)=mean(wat_lvl_tg{i},'omitnan');
        sla_tg{i}=wat_lvl_tg{i}-mss_tg(i); %option#2 and #3 for TG USED
        figure('Position',get(0,'Screensize'));
        hold on
        tgg=timetable(time_tg{i},sla_tg{i});
        time_all=sort([time_dist_flag_tg_al{i,j};time_dist_flag_tg_xa{i,j};time_dist_flag_tg_nm{i,j}]);
        interp_sla_tg{i,j}=interp1(tgg.Time,tgg.Var1,time_all,'linear');
        % month_tgg=retime(tgg, 'weekly', 'linear'); 
        plot(time_all,interp_sla_tg{i,j},"--k")
        scatter(time_dist_flag_tg_al{i,j},sla_edit_dist_flag_tg_al{i,j},100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
        scatter(time_dist_flag_tg_xa{i,j},sla_edit_dist_flag_tg_xa{i,j},100,'filled','square','MarkerFaceColor',[.5 .5 .1])
        scatter(time_dist_flag_tg_nm{i,j},sla_edit_dist_flag_tg_nm{i,j},100,'filled','o','MarkerFaceColor',[.2 .2 .2])
        title(['Water Level Series of Point '; j;  'from '; data_tg{slctd_def(i),1}; ' Tide Gauge'],'FontSize',24,'FontWeight','bold')
        axis tight
        grid on
        xlabel('Time [year]')
        ylabel('Water Level Anomaly [m]')
        legend ({'In-Situ','ALES', 'X-TRACK/ALES', 'CMEMS'},'Location','best')
        legend('boxoff')
        last_xa=datetime(2018,5,20);
        xlim([time_all(1) last_xa])
        outputfile= "#" + k + " Water Level Series of Point " + j + " from " + data_tg{slctd_def(i),1} + " Tide Gauge.png";
        saveas(gcf,outputfile);
        k=k+1;
    end
end

% Barchart for Average Distance to the Coast
addpath(genpath('/home/g21zunadz/Downloads/MWCC_Exercises/calval_MGS05/lib/matlab/'));
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Mar_2023/Copy_of_Performance_Metrics_All.mat')
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend_h0tg.mat')
slctd_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];
ans1=vertcat(dist_al(:));
dist_al=vertcat(ans1{:});
dist_al=round(dist_al * 4)/4;
dist_xa=dist_xa./1000;
dist_xa=round(dist_xa * 4)/4;
dist_nm=round(dist_nm * 4)/4;
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 18)

% Recomputing the scatter plot again --> not necessary
% corr
ans=vertcat(corr2_4_al(:));
corr_al=vertcat(ans{:});
ans=vertcat(corr2_4_xa(:));
corr_xa=vertcat(ans{:});
ans=vertcat(corr2_4_nm(:));
corr_nm=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist_al,corr_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,corr_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,corr_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Pearsons Correlation Value and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Pearsons' Correlation Value")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
ylim ([0.4 1.03])

% std
ans=vertcat(std_dssh2_4_al(:));
std_al=vertcat(ans{:}).*100;
ans=vertcat(std_dssh2_4_xa(:));
std_xa=vertcat(ans{:}).*100;
ans=vertcat(std_dssh2_4_nm(:));
std_nm=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist_al,std_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,std_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,std_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Standard Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Standard Deviation [cm]")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
ylim ([0 60])
xlim ([0 18])

% Bias
ans=vertcat(bias_dssh2_4_al(:));
bias_al=vertcat(ans{:}).*100;
ans=vertcat(bias_dssh2_4_xa(:));
bias_xa=vertcat(ans{:}).*100;
ans=vertcat(bias_dssh2_4_nm(:));
bias_nm=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist_al,bias_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,bias_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,bias_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Bias and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Bias [cm]")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
ylim ([-8 20])
xlim ([0 18])

% mad
ans=vertcat(mad_dssh2_4_al(:));
mad_al=vertcat(ans{:}).*100;
ans=vertcat(mad_dssh2_4_xa(:));
mad_xa=vertcat(ans{:}).*100;
ans=vertcat(mad_dssh2_4_nm(:));
mad_nm=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist_al,mad_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,mad_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,mad_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Median Absolute Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("MAD [cm]")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
ylim ([0 18])
xlim ([0 18])

% uncertainty level
ans=vertcat(stdalt_al(:));
unc_al=vertcat(ans{:}).*100;
ans=vertcat(stdalt_nm(:));
unc_nm=vertcat(ans{:}).*100;
figure('Position',get(0,'Screensize'));
scatter(dist_al,unc_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_nm,abs(unc_nm),120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Altimetry Data Uncertainty and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Data Uncertainty [cm]")
legend ({'ALES', 'CMEMS'})
ylim ([-1 19])
xlim ([0 18])

% Num of Obs
ans=vertcat(num_each_point_al(:));
num_al=vertcat(ans{:});
ans=vertcat(num_each_point_xa(:));
num_xa=vertcat(ans{:});
ans=vertcat(num_each_point_nm(:));
num_nm=vertcat(ans{:});
figure('Position',get(0,'Screensize'));
scatter(dist_al,num_al,100,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(dist_xa,num_xa,100,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(dist_nm,num_nm,120,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Number of Observation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Number of Observation")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'})
set(gca, 'YScale', 'log')
ylim ([-10 320])
xlim ([-1 18])

% Computing barchart
% ALES
per_al=table(dist_al,corr_al,std_al,bias_al,mad_al,num_al,unc_al);
per_al=sortrows(per_al);
proc_al(:,1)=unique(per_al(:,1));
proc_al(32,:) = [];
proc_al(end,:) = [];
proc_al(:,2)=table(splitapply(@mean,per_al(:,2),findgroups(per_al(:,1))));
proc_al(:,3)=table(splitapply(@mean,per_al(:,3),findgroups(per_al(:,1))));
proc_al(:,4)=table(splitapply(@mean,per_al(:,4),findgroups(per_al(:,1))));
proc_al(:,5)=table(splitapply(@mean,per_al(:,5),findgroups(per_al(:,1))));
proc_al(:,6)=table(splitapply(@mean,per_al(:,6),findgroups(per_al(:,1))));
proc_al(:,7)=table(splitapply(@mean,per_al(:,7),findgroups(per_al(:,1))));

% X-TRACK/ALES
per_xa=table(dist_xa,corr_xa,std_xa,bias_xa,mad_xa,num_xa);
per_xa=sortrows(per_xa);
proc_xa(:,1)=unique(per_xa(:,1));
proc_xa(35:end,:) = [];
proc_xa(:,2)=table(splitapply(@mean,per_xa(:,2),findgroups(per_xa(:,1))));
proc_xa(:,3)=table(splitapply(@mean,per_xa(:,3),findgroups(per_xa(:,1))));
proc_xa(:,4)=table(splitapply(@mean,per_xa(:,4),findgroups(per_xa(:,1))));
proc_xa(:,5)=table(splitapply(@mean,per_xa(:,5),findgroups(per_xa(:,1))));
proc_xa(:,6)=table(splitapply(@mean,per_xa(:,6),findgroups(per_xa(:,1))));

% CMEMS
per_nm=table(dist_nm,corr_nm,std_nm,bias_nm,mad_nm,num_nm,unc_nm);
per_nm=sortrows(per_nm);
proc_nm(:,1)=unique(per_nm(:,1));
proc_nm(:,2)=table(splitapply(@mean,per_nm(:,2),findgroups(per_nm(:,1))));
proc_nm(:,3)=table(splitapply(@mean,per_nm(:,3),findgroups(per_nm(:,1))));
proc_nm(:,4)=table(splitapply(@mean,per_nm(:,4),findgroups(per_nm(:,1))));
proc_nm(:,5)=table(splitapply(@mean,per_nm(:,5),findgroups(per_nm(:,1))));
proc_nm(:,6)=table(splitapply(@mean,per_nm(:,6),findgroups(per_nm(:,1))));
proc_nm(:,7)=table(splitapply(@mean,per_nm(:,7),findgroups(per_nm(:,1))));

set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 18)

% Corr
figure
bar(proc_nm.dist_nm,proc_nm.Var2,'FaceColor',[.2 .2 .2])
title ('Pearson Coefficient Value Barchart for 3 Datasets')
hold on
bar(proc_xa.dist_xa,proc_xa.Var2,'FaceColor',[.5 .5 .1])
bar(proc_al.dist_al,proc_al.Var2,'FaceColor',[0 .7 .7])
legend ({'CMEMS','X-TRACK/ALES', 'ALES'},'Location','best')
legend('boxoff')
xlabel('distance from the coast [km]')
ylabel("Correlation Value")
ylim([0.4 1.1])

% STD
figure
bar(proc_nm.dist_nm,proc_nm.Var3,'FaceColor',[.2 .2 .2])
title ('STD Barchart for 3 Datasets')
hold on
bar(proc_al.dist_al,proc_al.Var3,'FaceColor',[0 .7 .7])
bar(proc_xa.dist_xa,proc_xa.Var3,'FaceColor',[.5 .5 .1])
legend ({'CMEMS','ALES', 'X-TRACK/ALES'},'Location','best')
legend('boxoff')
xlabel('distance from the coast [km]')
ylabel("STD of Difference [cm]")

% Median Bias
figure
bar(proc_nm.dist_nm,proc_nm.Var4,'FaceColor',[.2 .2 .2])
title ('Bias Barchart for 3 Datasets')
hold on
bar(proc_al.dist_al,proc_al.Var4,'FaceColor',[0 .7 .7])
bar(proc_xa.dist_xa,proc_xa.Var4,'FaceColor',[.5 .5 .1])
legend ({'CMEMS','ALES', 'X-TRACK/ALES'},'Location','best')
legend('boxoff')
xlabel('distance from the coast [km]')
ylabel("Median Bias [cm]")

% MAD
figure
bar(proc_nm.dist_nm,proc_nm.Var5,'FaceColor',[.2 .2 .2])
title ('MAD Barchart for 3 Datasets')
hold on
bar(proc_al.dist_al,proc_al.Var5,'FaceColor',[0 .7 .7])
bar(abs(proc_xa.dist_xa),abs(proc_xa.Var5),'FaceColor',[.5 .5 .1])
legend ({'CMEMS','ALES', 'X-TRACK/ALES'},'Location','best')
legend('boxoff')
xlabel('distance from the coast [km]')
ylabel("MAD of Difference [cm]")

% Num Obs
figure
bar(proc_xa.dist_xa,proc_xa.Var6,'FaceColor',[.5 .5 .1])
title ('Number of Observation Barchart for 3 Datasets')
hold on
bar(proc_al.dist_al,proc_al.Var6,'FaceColor',[0 .7 .7])
bar(proc_nm.dist_nm,proc_nm.Var6,'FaceColor',[.2 .2 .2])
legend ({ 'X-TRACK/ALES','ALES','CMEMS'},'Location','best')
legend('boxoff')
xlabel('distance from the coast [km]')
ylabel("Number of Observation") 

% Scatter for binned distance to the coast
load('/home/g21zunadz/Downloads/Data Pasang Surut/Data_BIG_Combined/data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend_h0tg.mat')
load('/home/g21zunadz/Downloads/Computation_Datasets/Newer_Processing_Mar_2023/Workspace for Barchart_withlwe.mat')
slctd_def=[7 15 17 18 33 41 47 49 51 53 56 62 67 74 79 81 85 86 88];

% corr
figure('Position',get(0,'Screensize'));
scatter(proc_al.dist_al,proc_al.Var2,150,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(proc_xa.dist_xa,proc_xa.Var2,150,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(proc_nm.dist_nm,proc_nm.Var2,150,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Pearsons Correlation Value and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Pearsons' Correlation Value")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'},'Location','best')
legend('boxoff')
ylim ([0.5 1.03])
xlim ([0 18])

% std
figure('Position',get(0,'Screensize'));
scatter(proc_al.dist_al,proc_al.Var3,150,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(proc_xa.dist_xa,proc_xa.Var3,150,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(proc_nm.dist_nm,proc_nm.Var3,150,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Standard Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Standard Deviation [cm]")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'},'Location','best')
legend('boxoff')
ylim ([0 60])
xlim ([0 18])

% Bias
figure('Position',get(0,'Screensize'));
scatter(proc_al.dist_al,proc_al.Var4,150,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(proc_xa.dist_xa,proc_xa.Var4,150,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(proc_nm.dist_nm,proc_nm.Var4,150,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Bias and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Bias [cm]")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'},'Location','best')
legend('boxoff')
ylim ([-2 10.5])
xlim ([0 18])

% mad
figure('Position',get(0,'Screensize'));
scatter(proc_al.dist_al,proc_al.Var5,150,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(proc_xa.dist_xa,proc_xa.Var5,150,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(proc_nm.dist_nm,proc_nm.Var5,150,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Median Absolute Deviation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("MAD [cm]")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'},'Location','best')
legend('boxoff')
ylim ([0 18])
xlim ([0 18])

% uncertainty level
figure('Position',get(0,'Screensize'));
scatter(proc_al.dist_al,proc_al.Var7,150,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(proc_nm.dist_nm,abs(proc_nm.Var5),150,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Altimetry Data Uncertainty and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Data Uncertainty [cm]")
legend ({'ALES', 'CMEMS'},'Location','best')
legend('boxoff')
ylim ([0 16.6])
xlim ([0 18])

% Num of Obs
figure('Position',get(0,'Screensize'));
scatter(proc_al.dist_al,proc_al.Var6,150,'filled','diamond','MarkerFaceColor',[0 .7 .7])
hold on
scatter(proc_xa.dist_xa,proc_xa.Var6,150,'filled','square','MarkerFaceColor',[.5 .5 .1])
scatter(proc_nm.dist_nm,proc_nm.Var6,150,'filled','o','MarkerFaceColor',[.2 .2 .2])
title('Plot between Number of Observation and Distance from the Coast','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('average distance from the coast [km]')
ylabel("Number of Observation")
legend ({'ALES', 'X-TRACK/ALES', 'CMEMS'},'Location','best')
legend('boxoff')
set(gca, 'YScale', 'log')
% ylim ([-10 320])
xlim ([-1 18])