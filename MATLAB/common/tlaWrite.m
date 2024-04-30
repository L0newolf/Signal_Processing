
[data1,data,Fs] = readDTLA('/Users/anshu/Desktop/DTLA/120512_151712.dat',1:24,0,280);

[row,col] = size(data1);

fp=fopen('data.txt', 'w');

for i=1:row
    for j=1:col
        fprintf(fp,'%d\n',data1(i,j));
    end
    fprintf(fp,'%d\n',999999);
    fprintf(fp,'%d\n',999999);
end

fclose(fp);

data2=load('data.txt');