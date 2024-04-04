% Code to Process Water Level of TG near Earthquake Location
% made by Zulfikar A. Nadzir
% last update on 03.04.2024

%% Showing Location of Earthquake w.r.t. TG Data
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 18)
load('D:\Itera\9_SMT Ganjil 2223\Selesaikan Papers\Check TG ketika Gempa\data_tg_fixed_after_search_with_cors_s3_jales_jxa_jcmems_trend_h0tg.mat')
loc_eq_1=[121.562; 23.819];
loc_eq_2=[121.672; 24.064];
loc_eq_3=[121.710; 24.161];
loc_eq_4=[121.595; 23.960];
loc_eq_5=[121.743; 24.147];
loc_eq_6=[121.804; 23.856];
loc_eq_7=[121.932; 24.195];
ans_1=data_tg(:,10);
lon_tg_big=[121.7561; 121.6236; 124.16; 127.67; 121.5062];
lat_tg_big=[24.3031; 23.9806; 24.33; 26.21; 23.4947];
name_tg_big=["Heping Port","Hualien","Ishigakijima","Naha","Shihti"];
% lon_tg=vertcat(ans_1{:});
ans_2=data_tg(:,9);
% lat_tg=vertcat(ans_2{:});
ans_3=data_tg(:,1);
% name_tg=vertcat(ans_3{:});
% ind_dekat=find(lon_tg>loc_eq_1(1)-5 & lon_tg<loc_eq_1(1)+5 & lat_tg>loc_eq_1(2)-5 & lat_tg<loc_eq_1(2)+5);
pat3='D:\Itera\9_SMT Ganjil 2223\Selesaikan Papers\Check TG ketika Gempa\gshhg-bin-2.3.7'; cd (pat3);
S=gshhs("gshhs_i.b",[loc_eq_1(2)-5,loc_eq_1(2)+5],[loc_eq_1(1)-5, loc_eq_1(1)+5]);

figure('Position',get(0,'Screensize'));
plot ([S.Lon],[S.Lat],'DisplayName','Coastline')
hold on
% scatter(lon_tg,lat_tg,125,'filled','diamond','DisplayName','TG Station IOC/UHSLC')
scatter(loc_eq_1(1),loc_eq_1(2),300,'filled','square','DisplayName','Earthquake Epicenter #1')
scatter(loc_eq_2(1),loc_eq_2(2),300,'filled','square','DisplayName','Earthquake Epicenter #2')
scatter(loc_eq_3(1),loc_eq_3(2),300,'filled','square','DisplayName','Earthquake Epicenter #3')
scatter(loc_eq_4(1),loc_eq_4(2),300,'filled','square','DisplayName','Earthquake Epicenter #4')
scatter(loc_eq_5(1),loc_eq_5(2),300,'filled','square','DisplayName','Earthquake Epicenter #5')
scatter(loc_eq_6(1),loc_eq_6(2),300,'filled','square','DisplayName','Earthquake Epicenter #6')
scatter(loc_eq_7(1),loc_eq_7(2),300,'filled','square','DisplayName','Earthquake Epicenter #7')
scatter(lon_tg_big,lat_tg_big,125,'filled','diamond','DisplayName','TG Station IOC')
axis('equal')
title('Map of Earthquake Epicenter and surrounding TG station','FontSize',24,'FontWeight','bold')
axis tight
grid on
xlabel('Longitude [degree]')
ylabel("Latitude [degree]")
legend ('Location','best')
legend('boxoff')
xlim ([loc_eq_1(1)-2 loc_eq_1(1)+2])
ylim ([loc_eq_1(2)-2 loc_eq_1(2)+2])
% text(lon_tg+0.15, lat_tg+0.05, name_tg,'FontSize',18);
text(lon_tg_big+0.02, lat_tg_big+0.04, name_tg_big,'FontSize',18);
% text(lon_tg_big(6)-3, lat_tg_big(6)-0.15, name_tg_big(6),'FontSize',18);
% text(loc_eq_1(1)+0.03, loc_eq_1(2)-0.14, 'Earthquake Epicenter #1 6.2 Mw','FontSize',18,'FontWeight','bold');
% text(loc_eq_2(1)+0.03, loc_eq_2(2)+0.14, 'Earthquake Epicenter #2 5.7 Mw','FontSize',18,'FontWeight','bold');
% text(loc_eq_2(1)+0.05, loc_eq_2(2)+0.05, 'Earthquake#2 Epicenter','FontSize',18,'FontWeight','bold');
% text(loc_eq_3(1)+0.05, loc_eq_3(2)+0.05, 'Earthquake#3 Epicenter','FontSize',18,'FontWeight','bold');