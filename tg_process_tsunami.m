% Pengolah data TG ketika ada Gempa berpotensi Tsunami
% made by Zulfikar A. Nadzir
% last update on 03.04.24

clc; dbstop if error; addpath(genpath(pwd));
set(groot,'DefaultTextFontSize', 24,...
    'DefaultAxesFontSize', 24,...
    'DefaultAxesTitleFontWeight', 'bold',...
    'DefaultAxesTitleFontSizeMultiplier', 1,...
    'DefaultAxesXMinorTick', 'on', 'DefaultAxesYMinorTick', 'on',...
    'DefaultAxesZMinorTick', 'on',...
    'DefaultTextFontName', 'Arial', ...
    'DefaultLineLineWidth', 2, ...
    'DefaultLineMarkerSize', 10)
%% Data Reading
load('D:\Itera\9_SMT Ganjil 2223\Selesaikan Papers\Check TG ketika Gempa\Hualien (03.04.24)\Data_Hualien.mat');
t_gempa_1=datetime(2024,04,02,23,58,11);
t_gempa_2=datetime(2024,04,03,00,11,25);
t_gempa_3=datetime(2024,04,03,00,35,36);
t_gempa_4=datetime(2024,04,03,00,43,55);
t_gempa_5=datetime(2024,04,03,00,46,44);
t_gempa_6=datetime(2024,04,03,01,39,35);
t_gempa_7=datetime(2024,04,03,02,14,35);
t_dekat_sta1=find(Datasta1.TimeStamp>t_gempa_1-days(2) & Datasta1.TimeStamp<t_gempa_1+days(2));
t_dekat_sta2=find(Datasta2.TimeStamp>t_gempa_1-days(2) & Datasta2.TimeStamp<t_gempa_1+days(2));
t_dekat_sta3=find(Datasta3.TimeStamp>t_gempa_1-days(2) & Datasta3.TimeStamp<t_gempa_1+days(2));
t_dekat_sta4=find(Datasta4.TimeStamp>t_gempa_1-days(2) & Datasta4.TimeStamp<t_gempa_1+days(2));
t_dekat_sta5=find(Datasta5.TimeStamp>t_gempa_1-days(2) & Datasta5.TimeStamp<t_gempa_1+days(2));

% Sta#1
figure('Position',get(0,'Screensize'));
scatter(Datasta1.TimeStamp(t_dekat_sta1),Datasta1.radm(t_dekat_sta1),'filled')
hold on
xline(t_gempa_1,'LineWidth',0.5,'Label','EQ#1','FontSize',15)
xline(t_gempa_2,'LineWidth',0.5,'Label','EQ#2','FontSize',15)
xline(t_gempa_3,'LineWidth',0.5,'Label','EQ#3','FontSize',15)
xline(t_gempa_4,'LineWidth',0.5,'Label','EQ#4','FontSize',15)
xline(t_gempa_5,'LineWidth',0.5,'Label','EQ#5','FontSize',15)
xline(t_gempa_6,'LineWidth',0.5,'Label','EQ#6','FontSize',15)
xline(t_gempa_7,'LineWidth',0.5,'Label','EQ#7','FontSize',15)
title ('Observed Water Level Data at Heping Port','FontSize',25,'FontWeight','bold')
xlabel('time')
ylabel('observed water level [m]')
grid on

% Sta#2
figure('Position',get(0,'Screensize'));
scatter(Datasta2.TimeStamp(t_dekat_sta2),Datasta2.radm(t_dekat_sta2),'filled')
hold on
xline(t_gempa_1,'LineWidth',0.5,'Label','EQ#1','FontSize',15)
xline(t_gempa_2,'LineWidth',0.5,'Label','EQ#2','FontSize',15)
xline(t_gempa_3,'LineWidth',0.5,'Label','EQ#3','FontSize',15)
xline(t_gempa_4,'LineWidth',0.5,'Label','EQ#4','FontSize',15)
xline(t_gempa_5,'LineWidth',0.5,'Label','EQ#5','FontSize',15)
xline(t_gempa_6,'LineWidth',0.5,'Label','EQ#6','FontSize',15)
xline(t_gempa_7,'LineWidth',0.5,'Label','EQ#7','FontSize',15)
title ('Observed Water Level Data at Hualien','FontSize',25,'FontWeight','bold')
xlabel('time')
ylabel('observed water level [m]')
grid on

% Sta#3
figure('Position',get(0,'Screensize'));
scatter(Datasta3.TimeStamp(t_dekat_sta3),Datasta3.radm(t_dekat_sta3),'filled')
hold on
xline(t_gempa_1,'LineWidth',0.5,'Label','EQ#1','FontSize',15)
xline(t_gempa_2,'LineWidth',0.5,'Label','EQ#2','FontSize',15)
xline(t_gempa_3,'LineWidth',0.5,'Label','EQ#3','FontSize',15)
xline(t_gempa_4,'LineWidth',0.5,'Label','EQ#4','FontSize',15)
xline(t_gempa_5,'LineWidth',0.5,'Label','EQ#5','FontSize',15)
xline(t_gempa_6,'LineWidth',0.5,'Label','EQ#6','FontSize',15)
xline(t_gempa_7,'LineWidth',0.5,'Label','EQ#7','FontSize',15)
title ('Observed Water Level Data at Ishigakijima','FontSize',25,'FontWeight','bold')
xlabel('time')
ylabel('observed water level [m]')
grid on

% Sta#4
figure('Position',get(0,'Screensize'));
scatter(Datasta4.TimeStamp(t_dekat_sta4),Datasta4.radm(t_dekat_sta4),'filled')
hold on
xline(t_gempa_1,'LineWidth',0.5,'Label','EQ#1','FontSize',15)
xline(t_gempa_2,'LineWidth',0.5,'Label','EQ#2','FontSize',15)
xline(t_gempa_3,'LineWidth',0.5,'Label','EQ#3','FontSize',15)
xline(t_gempa_4,'LineWidth',0.5,'Label','EQ#4','FontSize',15)
xline(t_gempa_5,'LineWidth',0.5,'Label','EQ#5','FontSize',15)
xline(t_gempa_6,'LineWidth',0.5,'Label','EQ#6','FontSize',15)
xline(t_gempa_7,'LineWidth',0.5,'Label','EQ#7','FontSize',15)
title ('Observed Water Level Data at Naha','FontSize',25,'FontWeight','bold')
xlabel('time')
ylabel('observed water level [m]')
grid on

% Sta#5
figure('Position',get(0,'Screensize'));
scatter(Datasta5.TimeStamp(t_dekat_sta5),Datasta5.radm(t_dekat_sta5),'filled')
hold on
xline(t_gempa_1,'LineWidth',0.5,'Label','EQ#1','FontSize',15)
xline(t_gempa_2,'LineWidth',0.5,'Label','EQ#2','FontSize',15)
xline(t_gempa_3,'LineWidth',0.5,'Label','EQ#3','FontSize',15)
xline(t_gempa_4,'LineWidth',0.5,'Label','EQ#4','FontSize',15)
xline(t_gempa_5,'LineWidth',0.5,'Label','EQ#5','FontSize',15)
xline(t_gempa_6,'LineWidth',0.5,'Label','EQ#6','FontSize',15)
xline(t_gempa_7,'LineWidth',0.5,'Label','EQ#7','FontSize',15)
title ('Observed Water Level Data at Shihti','FontSize',25,'FontWeight','bold')
xlabel('time')
ylabel('observed water level [m]')
grid on