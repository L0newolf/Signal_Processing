clear all

path = 'Summary/packet length/';
numBits = [640,1120,1920,600,1440,2460,3200];
colourVal = [0,5,10,14,18,25,21];

extn = '/*.txt';

ber_1923_1 = [];
ber_1923_2 = [];
ber_753 = [];
ber_2300 = [];

range_1923_1 = [];
range_1923_2 = [];
range_753 = [];
range_2300 = [];

colour_1923_1 = [];
colour_1923_2 = [];
colour_753 = [];
colour_2300 = [];

effDataRate_1923_1 = [];
effDataRate_1923_2 = [];
effDataRate_753 = [];
effDataRate_2300 = [];

pdrVal_1923_1 = [];
pdrVal_1923_2 = [];
pdrVal_753 = [];
pdrVal_2300 = [];

dataRate_1923_1 = [];
dataRate_1923_2 = [];
dataRate_753 = [];
dataRate_2300 = [];

numFiles = 4;

for j=1:length(numBits)
    folder = [path num2str(numBits(j)) extn];
    files  = dir(folder);
    numFiles = length(files);
    
    %colourVal(j) = rand()*100;
    
    for k = 1:numFiles
        curFile = [path num2str(numBits(j)) '/' files(k).name];
        
        switch files(k).name
            case '1923_1.txt'
                
                curData = load(curFile);
                curRange = zeros(1,length(curData));
                curRange(:) = 1923;
                curColour = zeros(1,length(curData));
                curColour(:) = colourVal(j);
                curEffDataRate = zeros(1,length(curData));
                curEffDataRate = getEffDataRate( numBits(j),curData );
                curPdrVal = zeros(1,length(curData));
                curPdrVal = getPDR( curData );
                curDataRate = zeros(1,length(curData));
                curDataRate(:) = numBits(j);
                
                dataRate_1923_1 = [dataRate_1923_1 curDataRate];
                pdrVal_1923_1 = [pdrVal_1923_1 curPdrVal];
                effDataRate_1923_1 = [effDataRate_1923_1 curEffDataRate];
                ber_1923_1 = [ber_1923_1 curData'];
                range_1923_1 = [range_1923_1 curRange];
                colour_1923_1 = [colour_1923_1 curColour];
                
            case '1923_2.txt'
                curData = load(curFile);
                curRange = zeros(1,length(curData));
                curRange(:) = 1923;
                curEffDataRate = zeros(1,length(curData));
                curEffDataRate = getEffDataRate( numBits(j),curData );
                curPdrVal = zeros(1,length(curData));
                curPdrVal = getPDR( curData );
                curDataRate = zeros(1,length(curData));
                curDataRate(:) = numBits(j);
                
                dataRate_1923_2 = [dataRate_1923_2 curDataRate];
                pdrVal_1923_2 = [pdrVal_1923_2 curPdrVal];
                effDataRate_1923_2 = [effDataRate_1923_2 curEffDataRate];
                ber_1923_2 = [ber_1923_2 curData'];
                range_1923_2 = [range_1923_2 curRange];
                curColour = zeros(1,length(curData));
                curColour(:) = colourVal(j);
                colour_1923_2 = [colour_1923_2 curColour];
                
                
            case '753.txt'
                curData = load(curFile);
                curRange = zeros(1,length(curData));
                curRange(:) = 753;
                curEffDataRate = zeros(1,length(curData));
                curEffDataRate = getEffDataRate( numBits(j),curData );
                curPdrVal = zeros(1,length(curData));
                curPdrVal = getPDR( curData );
                curDataRate = zeros(1,length(curData));
                curDataRate(:) = numBits(j);
                
                dataRate_753 = [dataRate_753 curDataRate];
                pdrVal_753 = [pdrVal_753 curPdrVal];
                effDataRate_753 = [effDataRate_753 curEffDataRate];
                ber_753 = [ber_753 curData'];
                range_753 = [range_753 curRange];
                curColour = zeros(1,length(curData));
                curColour(:) = colourVal(j);
                colour_753 = [colour_753 curColour];
                
            case '2300.txt'
                curData = load(curFile);
                curRange = zeros(1,length(curData));
                curRange(:) = 2300;
                curEffDataRate = zeros(1,length(curData));
                curEffDataRate = getEffDataRate( numBits(j),curData );
                curPdrVal = zeros(1,length(curData));
                curPdrVal = getPDR( curData );
                curDataRate = zeros(1,length(curData));
                curDataRate(:) = numBits(j);
                
                dataRate_2300 = [dataRate_2300 curDataRate];
                pdrVal_2300= [pdrVal_2300 curPdrVal];
                effDataRate_2300 = [effDataRate_2300 curEffDataRate];
                ber_2300 = [ber_2300 curData'];
                range_2300 = [range_2300 curRange];
                curColour = zeros(1,length(curData));
                curColour(:) = colourVal(j);
                colour_2300 = [colour_2300 curColour];
                
        end
        
    end
    
end

gap = zeros(1,200);
white  = 0000;

ber = [ber_1923_1 gap ber_753 gap ber_1923_2 gap ber_2300];
range = [range_1923_1 gap range_753 gap range_1923_2 gap range_2300];
colour = [colour_1923_1 gap+white colour_753 gap colour_1923_2 gap colour_2300];
effDataRate = [effDataRate_1923_1 effDataRate_753 effDataRate_1923_2 effDataRate_2300];
pdr = [pdrVal_1923_1 pdrVal_753 pdrVal_1923_2 pdrVal_2300];
dataRate = [dataRate_1923_1 dataRate_753 dataRate_1923_2 dataRate_2300];

vals = 0:(length(ber)-1);
a = 500;
c = linspace(1,10,length(vals));

figure(1);

subplot_tight(2,2,1,[0.06,0.06,0.06]);
stem(1:length(ber_1923_1),ber_1923_1);
grid on;
title('Overall BER variation at 1923 mtrs on Day 1','FontSize',15);
xlabel('Packet Sequence','FontSize',15);
ylabel('BER','FontSize',15);

subplot_tight(2,2,2,[0.06,0.06,0.06]);
stem(1:length(ber_753),ber_753);
grid on;
title('Overall BER variation at 753 mtrs on Day 1','FontSize',15);
xlabel('Packet Sequence','FontSize',15);
ylabel('BER','FontSize',15);

subplot_tight(2,2,3,[0.06,0.06,0.06]);
stem(1:length(ber_1923_2),ber_1923_2);
grid on;
title('Overall BER variation at 1923 mtrs on Day 5','FontSize',15);
xlabel('Packet Sequence','FontSize',15);
ylabel('BER','FontSize',15);

subplot_tight(2,2,4,[0.06,0.06,0.06]);
stem(1:length(ber_2300),ber_2300);
grid on;
title('Overall BER variation at 2300 mtrs on Day 5','FontSize',15);
xlabel('Packet Sequence','FontSize',15);
ylabel('BER','FontSize',15);

figure(2);

subplot_tight(2,2,1,[0.06,0.06,0.06]);
scatter(1:length(ber_1923_1),ber_1923_1,a,colour_1923_1,'Marker','.');
grid on;
title('PktLen-wise BER variation at 1923 mtrs on Day 1','FontSize',15);
str1 = '640 bit pkt';
text(200,0.46,str1,'Color',[0 0 0.4],'FontSize',18);
str1 = '1120 bit pkt';
text(200,0.44,str1,'Color',[0 0 0.4],'FontSize',18);
str1 = '1920 bit pkt';
text(200,0.42,str1,'Color',[0 0 0.4],'FontSize',18);
xlabel('Packet Sequence','FontSize',15);
ylabel('BER','FontSize',15);

subplot_tight(2,2,2,[0.06,0.06,0.06]);
scatter(1:length(ber_753),ber_753,a,colour_753,'Marker','.');
grid on;
title('PktLen-wise BER variation at 753 mtrs on Day 1','FontSize',15);
str1 = '640 bit pkt';
text(150,0.46,str1,'Color',[0 0 0.4],'FontSize',18);
str1 = '1120 bit pkt';
text(150,0.44,str1,'Color',[102/255 51/255 0],'FontSize',18);
xlabel('Packet Sequence','FontSize',15);
ylabel('BER','FontSize',15);

subplot_tight(2,2,3,[0.06,0.06,0.06]);
scatter(1:length(ber_1923_2),ber_1923_2,a,colour_1923_2,'Marker','.');
grid on;
title('PktLen-wise BER variation at 1923 mtrs on Day 5','FontSize',15);
str1 = '640 bit pkt';
text(90,0.24,str1,'Color',[0 0 0.4],'FontSize',18);
str1 = '600 bit pkt';
text(90,0.23,str1,'Color',[102/255 1 102/255],'FontSize',18);
str1 = '1440 bit pkt';
text(90,0.22,str1,'Color',[204/255 204/255 0],'FontSize',18);
str1 = '2460 bit pkt';
text(90,0.21,str1,'Color',[255/255 0/255 0],'FontSize',18);
str1 = '3200 bit pkt';
text(90,0.20,str1,'Color',[102/255 51/255 0],'FontSize',18);
xlabel('Packet Sequence','FontSize',15);
ylabel('BER','FontSize',15);

subplot_tight(2,2,4,[0.06,0.06,0.06]);
scatter(1:length(ber_2300),ber_2300,a,colour_2300,'Marker','.');
grid on;
title('PktLen-wise BER variation at 2300 mtrs on Day 5','FontSize',15);
str1 = '640 bit pkt';
text(35,0.55,str1,'Color',[0 0 0.4],'FontSize',18);
str1 = '3200 bit pkt';
text(35,0.52,str1,'Color',[102/255 51/255 0],'FontSize',18);
xlabel('Packet Sequence','FontSize',15);
ylabel('BER','FontSize',15);

figure(3);
scatter(vals,ber,a,colour,'Marker','.');
set(gca,'Position',[.055 .055 .9 .9]);
title('Overall BER variation at at all ranges on all days','FontSize',18);
str1 = '1923 mtrs,Day 1';
text(50,-0.03,str1,'FontSize',16);
str1 = '753 mtrs,Day 1';
text(450,-0.03,str1,'FontSize',16);
str1 = '1923 mtrs,Day 5';
text(800,-0.03,str1,'FontSize',16);
str1 = '2300 mtrs,Day 5';
text(1100,-0.03,str1,'FontSize',16);

str1 = '640 bit pkt';
text(1050,0.69,str1,'Color',[0 0 0.4],'FontSize',18);
str1 = '1120 bit pkt';
text(1050,0.675,str1,'Color',[153/255 204/255 255/255],'FontSize',18);
str1 = '1920 bit pkt';
text(1050,0.66,str1,'Color',[0/255 255/255 128/255],'FontSize',18);
str1 = '600 bit pkt';
text(1050,0.645,str1,'Color',[178/255 255/255 102/255],'FontSize',18);
str1 = '1440 bit pkt';
text(1050,0.63,str1,'Color',[204/255 204/255 0],'FontSize',18);
str1 = '2460 bit pkt';
text(1050,0.615,str1,'Color',[255/255 0/255 0],'FontSize',18);
str1 = '3200 bit pkt';
text(1050,0.6,str1,'Color',[102/255 51/255 0],'FontSize',18);

xlabel('Packet Sequence','FontSize',18);
ylabel('BER','FontSize',18);



rangeVals = [range_1923_1 range_753 range_1923_2 range_2300];
linkRate = [];
range = [];
count = 1;
for i=1:length(pdr)
    if(pdr(i) > 4)
        linkRate(count) = effDataRate(i);
        range(count) = rangeVals(i);
        count = count +1;
    end
end
colour=zeros(length(linkRate),3);
colour(:,1)=0;
colour(:,2)=0;
colour(:,3)=0.4;

figure(4);
scatter(range,linkRate,a,colour,'Marker','.');
xlim([0 2400]);
ylim([0 10000]);
set(gca,'Position',[.055 .055 .9 .9]);
title('Range-Effective Data Rate plot','FontSize',18);
xlabel('Range','FontSize',18,'FontWeight','bold');
ylabel('Data Rate','FontSize',18,'FontWeight','bold');

colour=zeros(length(effDataRate),3);
colour(:,1)=0;
colour(:,2)=0;
colour(:,3)=0.1*pdr;

figure(5);
scatter(rangeVals,dataRate,a,colour,'Marker','.');
xlim([0 2400]);
ylim([0 10000]);
set(gca,'Position',[.055 .055 .9 .9]);
title('Range-PDR plot','FontSize',18);
