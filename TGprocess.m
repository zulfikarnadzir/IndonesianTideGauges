function [datetimes,lvl,year] = TGprocess(folder_path)
% TGprocess Processing of BIG Tide Gauges data
% made by Zulfikar A. Nadzir, February 2022
% INPUT  :
%   folder_path = complete path of individual stations (string)
% OUTPUT :
%   datetime = date and time in datetime format (UTC)
%   lvl = sea level measurements form tide gauge station (in cm)
%   lat = latitude of station (decimal degree)
%   lon = longitude of station (decimal degree)
%   name = Station Name
%   year = Data Years
% It removes no wrong, NULL and NaN data (assumed that data are already filtered by provider)

% Defining data path
cd (folder_path);
filename=dir('*.txt');
headerlength=14;
% Importing Data
for p=1:length(filename)
    file(p,:)=struct2cell(filename(p,1));
    fprintf(1,'processing data of year ');
    fprintf (1,'\b %s',cell2mat(extractBetween (file{p,1},"_",".")));
    fprintf ('\n');
    A=importdata((file{p,1}),' ',headerlength);
    % Exporting date and time
    date=datetime(A.textdata(headerlength+1:end,1),'InputFormat','dd/MM/yyyy');
    hour=datetime(A.textdata(headerlength+1:end,2),'InputFormat','HH:mm:ss');
    datetimes{p}=date+timeofday(hour);
    % Sea Level Records Export
    lvl{p}=A.data(:,1);
    % Year Record
    year{p}=cell2mat(extractBetween (file{p,1},"_","."));
end
% Read Lat, Lon and Name of Station  
% Saving the Workspace
end