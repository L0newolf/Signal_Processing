function [data Fs]=readDTLA(filename,Channels,tStart,dur)
%   Function to read the data from DTLA daq data.
%   
%   tStart  : Start time from the begining of the recording
%   dur     : Duations of the data section
%   Channles: The data channels to be loaded
%   
%   Usage [data Fs]=readDTLA('100511_131817.dat',[1 2 3],10,40);
%
%   Author: Unnikrishnan K.C. (ARL)
%   Last Modified: Oct 13, 2011
%

%% Initial parameters

Fs=1/(1.6e-6*26); % sampling frequency

if nargin<4
    dur=1;
elseif nargin<3
    tStart=0;
end

%% Open the file

try
    
fp=fopen(filename, 'r'); %'100511_131817.dat'

catch err
    data=[];
    error('unable to open the file');
    
end
%% Estimate the size of the file
fseek(fp,0,'eof');
temp=ftell(fp);
tTotal=((temp/2/26)-2)/Fs; % subtraction of 2 is to make sure the read data
                            % has meanigfull values


if tStart>tTotal
    data=[];
    error('tStart greater than total recording');
    
elseif tTotal<tStart+dur
    dur=tTotal-tStart;
end
KK=floor(tStart*Fs);
NN=length(Channels);
MM=floor(Fs*dur);
data=zeros(MM,NN);
frewind(fp);

for jj=1:NN
    temp=fseek(fp,KK*26*2+4+(Channels(jj)-1)*2,'bof');
    data(:,jj)=fread(fp,MM,'uint16',25*2);
    frewind(fp);
end
fclose(fp);

data=(5*data./(2^16))-2.5;