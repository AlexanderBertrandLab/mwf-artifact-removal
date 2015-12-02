% Remove artifacts from the data using the marked data segments to train
% the MWF covariance matrices

function [eeg_filtered_MWF,SER,ARR] = remove_artifacts(eeg_data,Fs)

cleanup

% Load eeg_data, Fs, duration
% load(['EEG_data_readout' filesep 'eye_blink_lorenz.mat'])

% Select first x seconds as training data
training_duration = 30;
training_data = eeg_data(:,1:Fs*training_duration);

% Create .mat file to be loaded by EyeBallGUI
FileEEGdata = training_data;
FileEEGsrate = Fs;
save(['TRAINING_DATA.mat'],'FileEEGdata','FileEEGsrate')

% Launch EyeBallGUI
EyeBallGUI

% Wait until the "Bad" file exists with markings in the directory. If one
% exists already, delete it
if(exist('TRAINING_DATABad.mat','file'))
    delete('TRAINING_DATABad.mat');
end
while(~exist('TRAINING_DATABad.mat','file'))
    pause(1);
end

% Close GUI after markings are saved and clean up backup files
close all force
rmdir('EyeBallGUI_BackUp','s')
delete('EyeBallGUIini.mat')

% Extract marked eye blinks from markings .mat file
load('TRAINING_DATABad.mat');
mask = isnan(EEGmask);  % 1's where artifacts are marked
training_mask = sum(mask,1);
training_mask(training_mask>0) = 1;

% when saving testing data for script
% save('training_blinks\training_blinks_steven.mat','eeg_data','training_data','training_mask')
% save('training_muscle\training_muscle_steven.mat','eeg_data','training_data','training_mask')

% Perform MWF filtering
[eeg_filtered_MWF,SER_MWF,ARR_MWF] = filter_MWF(training_data,training_mask,eeg_data);
[eeg_filtered_MWF_lags,SER_MWF_lags,ARR_MWF_lags] = filter_MWF_lags(training_data,training_mask,eeg_data);
[eeg_filtered_GEVD,SER_GEVD,ARR_GEVD] = filter_MWF_GEVD(training_data,training_mask,eeg_data);
[eeg_filtered_GEVD_lags,SER_GEVD_lags,ARR_GEVD_lags] = filter_MWF_GEVD_lags(training_data,training_mask,eeg_data);

% Collect performance parameters
SER = [SER_MWF , SER_MWF_lags , SER_GEVD , SER_GEVD_lags]; %MWF, MWF+lags, MWF+GEVD, MWF+GEVD+lags
ARR = [ARR_MWF , ARR_MWF_lags , ARR_GEVD , ARR_GEVD_lags];

% EEG plot of the original data and the filtered data on top in red
eegplot(eeg_data,'data2',eeg_filtered_GEVD_lags,'srate',Fs,'winlength',10,'dispchans',3,...
    'spacing',200,'title','Original EEG data (blue) + Filtered EEG data (GEVD+lags) (red)')

% EEG plot of the original data and the filtered data on top in red
eegplot(eeg_filtered_MWF,'data2',eeg_filtered_GEVD_lags,'srate',Fs,'winlength',10,'dispchans',3,...
    'spacing',200,'title','MWF (blue) + MWF_GEVD_lags (red)')

% Clean up directory
cleanup

end
