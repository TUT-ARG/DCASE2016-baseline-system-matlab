function feature_data = feature_extraction(y, fs, varargin) 
    % Feature extraction, MFCC based features
    % 
    % Outputs features in dict, format:
    % 
    %     struct(
    %         'feat', feature_matrix [shape=(frame count, feature vector size)],
    %         'stat', struct(
    %             'mean', mean(feature_matrix,2),...
    %             'std',std(feature_matrix,0,2),...
    %             'N',size(feature_matrix,2),...
    %             'S1',sum(feature_matrix,2),...
    %             'S2',sum(feature_matrix.^2,2)
    %         )
    %     )
    % 
    % Parameters
    % ----------
    % y: array [shape=(signal_length, )]
    %     Audio
    % 
    % fs: int > 0 [scalar]
    %     Sample rate
    %     (Default value=44100) 
    % 
    % Optional parameters as 'name' value pairs  
    % ----------------------------------------   
    % statistics: bool
    %     Calculate feature statistics for extracted matrix
    %     (Default value=true)
    % 
    % include_mfcc0: bool
    %     Include 0th MFCC coefficient into static coefficients.
    %     (Default value=true)
    % 
    % include_delta: bool
    %     Include delta MFCC coefficients.
    %     (Default value=true)
    % 
    % include_acceleration: bool
    %     Include acceleration MFCC coefficients.
    %     (Default value=true)
    % 
    % mfcc_params: struct
    %     Parameters for extraction of static MFCC coefficients.
    %     (Default values: n_mels=20,fmin=0,fmax=22050,win_length_seconds=0.04,hop_length_seconds=0.02)
    % 
    % delta_params: struct or None
    %     Parameters for extraction of delta MFCC coefficients.
    %     (Defualt values: width=9)
    % 
    % acceleration_params: struct
    %     Parameters for extraction of acceleration MFCC coefficients.
    %     (Defualt values: width=9)
    % 
    % Returns
    % -------
    % result: struct
    %     Feature struct
    % 
 
    % Parse the optional arguments
    [statistics, ...
     include_mfcc0, ...
     include_delta, ...
     include_acceleration, ...
     mfcc_params, ...
     delta_params, ...
     acceleration_params, ...
     unused] = process_options(varargin, ...
        'statistics', true, ...
        'include_mfcc0', true, ...
        'include_delta', true, ...
        'include_acceleration', true, ...        
        'mfcc_params', struct('n_mels',20,'fmin',0,'fmax',22050,'win_length_seconds',0.04,'hop_length_seconds',0.02), ...
        'delta_params', struct('width', 9), ...
        'acceleration_params', struct('width', 9));

        
    eps = 2.2204460492503131e-16; % equals to numpy.spacing(1) in python 
    
    % Parameters aligned with librosa mfcc when possible.
    mfcc = melfcc((y+eps),fs,... %/32768
                 'nbands',    mfcc_params.n_mels,...
                 'minfreq',   mfcc_params.fmin,...
                 'maxfreq',   mfcc_params.fmax,...
                 'numcep',    mfcc_params.n_mfcc,...        
                 'wintime',   mfcc_params.win_length_seconds,...
                 'hoptime',   mfcc_params.hop_length_seconds,...        
                 'preemph',   0,...
                 'lifterexp', 0,...
                 'dcttype',   3,...
                 'fbtype',    'mel',...
                 'sumpower',  0,...
                 'useenergy', 0);	

    feature_matrix = mfcc;
    if or(include_delta,include_acceleration)
        mfcc_delta   = deltas(mfcc,delta_params.width);  
    end
    if include_delta        
        feature_matrix = [feature_matrix; mfcc_delta];
    end
    
    if include_acceleration
        mfcc_delta2   = deltas(mfcc_delta,acceleration_params.width);  
        feature_matrix = [feature_matrix; mfcc_delta2];
    end
    
    if ~include_mfcc0
        feature_matrix = feature_matrix(2:end,:);
    end
    if statistics
        stat = struct('mean', mean(feature_matrix,2),'std',std(feature_matrix,0,2),'N',size(feature_matrix,2),'S1',sum(feature_matrix,2),'S2',sum(feature_matrix.^2,2));
        feature_data = struct('feat',feature_matrix,'stat',stat);
    else
        feature_data = struct('feat',feature_matrix);
    end    
end
