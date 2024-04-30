noise1 = load('data/noise_data/rec-51_20150917084358.txt');
%noise2 = load('data/noise_data/rec-51_20150917070220.txt');
% noise3 = load('data/noise_data/rec-51_20150917070246.txt');
% noise4 = load('data/noise_data/rec-51_20150917045837.txt');
% noise5 = load('data/noise_data/rec-51_20150917045711.txt');

noise1 = complex(noise1(:,1),noise1(:,2));
%noise2 = complex(noise2(:,1),noise2(:,2));
% noise3 = complex(noise3(:,1),noise3(:,2));
% noise4 = complex(noise4(:,1),noise4(:,2));
% noise5 = complex(noise5(:,1),noise5(:,2));

noise = noise1;%+noise2+noise3+noise4+noise5;
