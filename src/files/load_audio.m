function [y, fs] = load_audio(filename, varargin)
    % Load audio file 
    % 
    % Parameters
    % ----------
    % filename:  str
    %     Path to audio file
    %
    % Optional parameters as 'name' value pairs  
    % ----------------------------------------   
    % mono : bool
    %     In case of multi-channel audio, channels are averaged into single channel.
    %     (Default value=true)
    % 
    % fs : int > 0 [scalar]
    %     Target sample rate, if input audio does not fulfil this, audio is resampled.
    %     (Default value=44100)
    % 
    % Returns
    % -------
    % audio_data : matrix [shape=(signal_length, channel)]
    %     Audio
    % 
    % sample_rate : integer
    %     Sample rate
    % 
    
    % Parse the optional arguments
    [mono, ...
     fs, ...
     unused] = process_options(varargin, ...
        'mono', true, ...
        'fs', 44100);

    [y,sample_rate] = audioread(filename);    
    if(mono && size(y,2) > 1)
        y = mean(y')';
    end
    if(sample_rate ~= fs)
        y = resample(y, fs, sample_rate);		
        sample_rate = fs;
    end   
end