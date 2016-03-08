function task3_real_life_audio_sound_event_detection(varargin)
    % DCASE 2016
    %  Task 3: Sound Event Detection in Real-life Audio
    %  Baseline System
    %  ---------------------------------------------
    %  Tampere University of Technology / Audio Research Group
    %  Author:  Toni Heittola ( toni.heittola@tut.fi )
    % 
    %  System description
    %     This is an baseline implementation for the D-CASE 2016, task 3 - Sound event detection in real-life audio.
    %     The system has binary classifier for each included sound event class. The GMM classifier is trained with
    %     the positive and negative examples from the mixture signals, and classification is done between these
    %     two models as likelihood ratio. Acoustic features are MFCC+Delta+Acceleration (MFCC0 omitted).
    %
    %
    
    download_external_libraries % Download external libraries
    add_paths;   % Add file paths
    
    rng(123456); % let's make randomization predictable
    
    parser = inputParser;
    parser.addOptional('mode','development',@isstr);
    parse(parser,varargin{:});

    params = load_parameters('task3_sound_event_detection_in_real_life_audio.yaml');
    params = process_parameters(params);

    title('DCASE 2016::Sound Event Detection in Real-life Audio / Baseline System');

    % Check if mode is defined
    if(strcmp(parser.Results.mode,'development')),
        args.development = true;
        args.challenge = false;
    elseif(strcmp(parser.Results.mode,'challenge')),
        args.development = false;
        args.challenge = true;
    end

    dataset_evaluation_mode = 'folds';
    if(args.development && ~args.challenge),
        disp('Running system in development mode');
        dataset_evaluation_mode = 'folds';
    elseif(~args.development && args.challenge),
        disp('Running system in challenge mode');
        dataset_evaluation_mode = 'full';
    end
    
    % Get dataset container class
    if strcmp(params.general.development_dataset,'TUTSoundEvents_2016_DevelopmentSet')
        dataset = TUTSoundEvents_2016_DevelopmentSet(params.path.data);    
    else
        error(['Unknown development dataset [', params.general.development_dataset, ']']);
    end

    % Fetch data over internet and setup the data
    % ==================================================
    if params.flow.initialize
        dataset.fetch();    
    end

    % Extract features for all audio files in the dataset
    % ==================================================
    if params.flow.extract_features
        section_header('Feature extraction');

        % Collect files from evalaution sets
        files = [];
        for fold=dataset.folds(dataset_evaluation_mode)
            train_items = dataset.train(fold);
            for item_id=1:length(train_items)
                item = train_items(item_id);
                if sum(strcmp(item.file,files)) == 0
                    files = [files, {item.file}];
                end
            end                    
            test_items = dataset.test(fold);
            for item_id=1:length(test_items)
                item = test_items(item_id);
                if sum(strcmp(item.file,files)) == 0
                    files = [files, {item.file}];
                end
            end            
        end        
        files = sort(files);

        % Go through files and make sure all features are extracted
        do_feature_extraction(files, ...
                              dataset, ...
                              params.path.features, ...
                              params.features, ...
                              params.general.overwrite);

        foot();   
    end
    % Prepare feature normalizers
    % ================================================== 
    if params.flow.feature_normalizer
        section_header('Feature normalizer');
        do_feature_normalization(dataset,...                         
                                 params.path.feature_normalizers,...
                                 params.path.features,...
                                 dataset_evaluation_mode,...
                                 params.general.overwrite);
        foot();
    end
    % System training
    % ==================================================
    if params.flow.train_system
        section_header('System training');

        do_system_training(dataset,...                           
                           params.path.models,...
                           params.path.feature_normalizers,...
                           params.path.features,...
                           params.features.hop_length_seconds,...
                           params.classifier.parameters,...
                           dataset_evaluation_mode,...
                           params.classifier.method,...
                           params.general.overwrite);

        foot();
    end
    
    % System evaluation in development mode
    if(args.development && ~args.challenge)
        % System testing
        % ==================================================
        if params.flow.test_system
            section_header('System testing     [Development data]');

            do_system_testing(dataset,...                              
                              params.path.features,...
                              params.path.results,...
                              params.path.models,...
                              params.features,...
                              params.detector,...
                              dataset_evaluation_mode,...
                              params.classifier.method,...
                              params.general.overwrite);
            foot();
        end
        
        % System evaluation
        % ==================================================
        if params.flow.evaluate_system
            section_header('System evaluation');

            do_system_evaluation(dataset,...
                                 dataset_evaluation_mode,...
                                 params.path.results);

            foot();
        end
    % System evaluation with challenge data
    elseif(~args.development && args.challenge)
        % Get dataset container class
        if strcmp(params.general.challenge_dataset, 'TUTSoundEvents_2016_EvaluationSet')
            challenge_dataset = TUTSoundEvents_2016_EvaluationSet(params.path.data);
        else
            error(['Unknown development dataset [', params.general.evaluation_dataset, ']']);
        end

        if params.flow.initialize
            challenge_dataset.fetch();
        end

        % System testing
        if params.flow.test_system
            section_header('System testing     [Challenge data]');

            do_system_testing(challenge_dataset,...                            
                              params.path.features,...
                              params.path.results,...
                              params.path.models,...
                              params.features,...
                              params.detector,...
                              dataset_evaluation_mode,...
                              params.classifier.method,...                              
                              1);
            foot();

            disp(' ');
            disp(['Your results for the challenge data are stored at [',params.path.challenge_results,']']);
            disp(' ');
        end

    end
end
    
function params = process_parameters(params)
    % Parameter post-processing.
    %
    % Parameters
    % ----------
    % params : struct
    %    parameters in struct
    %
    % Returns
    % -------
    % params : struct
    %    processed parameters
    % 

    params.features.mfcc.win_length_seconds = params.features.win_length_seconds;
    params.features.mfcc.hop_length_seconds = params.features.hop_length_seconds;
    params.features.mfcc.win_length = round(params.features.win_length_seconds * params.features.fs);
    params.features.mfcc.hop_length = round(params.features.hop_length_seconds * params.features.fs);

    params.classifier.parameters = getfield(params.classifier_parameters,params.classifier.method);

    params.features.hash = get_parameter_hash(params.features);
    params.classifier.hash = get_parameter_hash(params.classifier);
    params.detector.hash = get_parameter_hash(params.detector);

    params.path.features = fullfile(params.path.base, params.path.features,params.features.hash);
    params.path.feature_normalizers = fullfile(params.path.base, params.path.feature_normalizers,params.features.hash);
    params.path.models = fullfile(params.path.base, params.path.models,params.features.hash, params.classifier.hash);
    params.path.results = fullfile(params.path.base, params.path.results, params.features.hash, params.classifier.hash, params.detector.hash);
end
    
function filename = get_feature_filename(audio_file, path, extension)
    % Get feature filename
    %
    % Parameters
    % ----------
    % audio_file : str
    %     audio file name from which the features are extracted
    % 
    % path :  str
    %     feature path
    % 
    % extension : str
    %     file extension
    %     (Default value='mat')
    %
    % Returns
    % -------
    % feature_filename : str
    %     full feature filename
    %
    %

    if nargin < 3
        extension = 'mat';
    end
    [~, raw_filename, ext] = fileparts(audio_file);    
    filename = fullfile(path, ['sequence_',raw_filename,'.',extension]);
end

function filename = get_feature_normalizer_filename(fold, scene_label, path, extension)
    % Get normalizer filename
    %
    % Parameters
    % ----------
    % fold : int >= 0
    %     evaluation fold number
    % 
    % path :  str
    %     normalizer path
    % 
    % extension : str
    %     file extension
    %     (Default value='mat')
    %
    % Returns
    % -------
    % normalizer_filename : str
    %     full normalizer filename
    %
    %  

    if nargin < 4
        extension = 'mat';
    end    
    filename = fullfile(path, ['scale_fold',num2str(fold),'_',scene_label,'.',extension]);
end

function filename = get_model_filename(fold, scene_label, path, extension)
    % Get model filename
    % 
    % Parameters
    % ----------
    % fold : int >= 0
    %     evaluation fold number
    % 
    % path :  str
    %     model path
    % 
    % extension : str
    %     file extension
    %     (Default value='mat')
    % 
    % Returns
    % -------
    % model_filename : str
    %     full model filename
    % 
    %   

    if nargin < 4
        extension = 'mat';
    end
    filename = fullfile(path, ['model_fold',num2str(fold),'_',scene_label,'.',extension]);
end

function filename = get_result_filename(fold, scene_label, path, extension)
    % Get result filename
    %
    % Parameters
    % ----------
    % fold : int >= 0
    %     evaluation fold number
    % 
    % path :  str
    %     result path
    % 
    % extension : str
    %     file extension
    %     (Default value='mat')
    % 
    % Returns
    % -------
    % result_filename : str
    %     full result filename
    %

    if nargin < 4
        extension = 'txt';
    end
    if(fold == 0)
        filename = fullfile(path, ['results_',scene_label,'.',extension]);
    else    
        filename = fullfile(path, ['results_fold',num2str(fold),'_',scene_label,'.',extension]);
    end
end

function do_feature_extraction(files, dataset, feature_path, params, overwrite)
    % Feature extraction
    % 
    % Parameters
    % ----------
    % files : cell array
    %     file list
    % 
    % dataset : class
    %     dataset class
    % 
    % feature_path : str
    %     path where the features are saved
    % 
    % params : struct
    %     parameter dict
    % 
    % overwrite : bool
    %     overwrite existing feature files
    % 
    % Returns
    % -------
    % nothing
    % 
    % Raises
    % -------
    % error
    %     Audio file not found.
    % 
    %    
    
    % Check that target path exists, create if not
    check_path(feature_path);

    progress(1,'Extracting [sequences]',(0 / length(files)),'');
    for file_id = 1:length(files)
        audio_filename = files{file_id};
        [raw_path, raw_filename, ext] = fileparts(audio_filename);
        current_feature_file = get_feature_filename(audio_filename,feature_path);
        
        progress(0,'Extracting [sequences]', (file_id / length(files)), raw_filename)
        
        if or(~exist(current_feature_file,'file'),overwrite)
            % Load audio data
            if exist(dataset.relative_to_absolute_path(audio_filename),'file')
                [y, fs] = load_audio(dataset.relative_to_absolute_path(audio_filename), 'mono', true, 'fs', params.fs);
            else
                error(['Audio file not found [',audio_filename,']']);                
            end
            
            % Extract features
            feature_data = feature_extraction(y,fs,...
                                              'statistics',true,...
                                              'include_mfcc0',params.include_mfcc0,...
                                              'include_delta',params.include_delta,...
                                              'include_acceleration',params.include_acceleration,...
                                              'mfcc_params',params.mfcc,...
                                              'delta_params',params.mfcc_delta,...
                                              'acceleration_params', params.mfcc_acceleration);
            
            % Save
            save_data(current_feature_file, feature_data)
        end
    end
    disp('  ');
end

function do_feature_normalization(dataset, feature_normalizer_path, feature_path, dataset_evaluation_mode, overwrite)
    % Feature normalization
    %
    % Calculated normalization factors for each evaluation fold based on the training material available.
    % 
    % Parameters
    % ----------
    % dataset : class
    %     dataset class
    %
    % feature_normalizer_path : str
    %     path where the feature normalizers are saved.
    % 
    % feature_path : str
    %     path where the features are saved.
    %
    % dataset_evaluation_mode : str ['folds', 'full']
    %     evaluation mode, 'full' all material available is considered to belong to one fold.
    %
    % overwrite : bool
    %     overwrite existing normalizers
    % 
    % Returns
    % -------
    % nothing
    % 
    % Raises
    % -------
    % error
    %     Features not found.
    %
    
    % Check that target path exists, create if not
    check_path(feature_normalizer_path);
    progress(1,'Collecting data',0,'');
    for fold=dataset.folds(dataset_evaluation_mode)
        scene_labels = dataset.scene_labels();
        for scene_id=1:length(scene_labels)
            scene_label = scene_labels{scene_id};
            current_normalizer_file = get_feature_normalizer_filename(fold, scene_label, feature_normalizer_path);
            if or(~exist(current_normalizer_file,'file'),overwrite)
                % Collect sequence files from scene class
                files = [];
                train_items = dataset.train(fold, 'scene_label',scene_label);
                for item_id=1:length(train_items)
                    files = [files; {train_items(item_id).file}];
                end
                files = unique(files);
                file_count = length(files);

                % Initialize statistics            
                normalizer = FeatureNormalizer();
                for file_id=1:length(files)
                    audio_filename = files{file_id};                    
                    progress(0,'Collecting data', (file_id / length(files)), audio_filename, fold);
                    
                    % Load features
                    feature_filename = get_feature_filename(audio_filename, feature_path);
                    if exist(feature_filename,'file')
                        feature_data = load_data(feature_filename);
                        feature_data = feature_data.stat;
                    else
                        error(['Features not found [', item.file, ']']);                        
                    end

                    % Accumulate statistics
                    normalizer.accumulate(feature_data);
                end

                % Calculate normalization factors
                normalizer.finalize();       

                % Save
                save_data(current_normalizer_file, normalizer);
            end
        end
    end
    disp('  ');
end

function do_system_training(dataset, model_path, feature_normalizer_path, feature_path, hop_length_seconds, classifier_params, dataset_evaluation_mode, classifier_method, overwrite)
    % System training
    %
    % model container format (struct):
    %   model.normalizer = normalizer_class;
    %   model.models = containers.Map();
    %   model.models(scene_label) = [model_struct (positive model), model_struct (negative model)];
    %
    % Parameters
    % ----------
    % dataset : class
    %     dataset class
    %
    % model_path : str
    %     path where the models are saved.
    %
    % feature_normalizer_path : str
    %     path where the feature normalizers are saved.
    %
    % feature_path : str
    %     path where the features are saved.
    %
    % hop_length_seconds : float > 0
    %     feature frame hop length in seconds    
    %
    % classifier_params : struct
    %     parameter struct
    %
    % dataset_evaluation_mode : str ['folds', 'full']
    %     evaluation mode, 'full' all material available is considered to belong to one fold.
    %
    % classifier_method : str ['gmm']
    %     classifier method, currently only GMM supported
    %
    % overwrite : bool
    %     overwrite existing models
    %
    % Returns
    % -------
    % nothing
    %
    % Raises
    % -------
    % error
    %     classifier_method is unknown.
    %     Feature normalizer not found.
    %     Feature file not found.
    %

    if ~strcmp(classifier_method, 'gmm')
        disp(['Unknown classifier method [', classifier_method, ']']);
    end

    % Check that target path exists, create if not
    check_path(model_path);

    progress(1, 'Collecting data', 0, '');
    for fold=dataset.folds(dataset_evaluation_mode)        
        scene_labels = dataset.scene_labels();
        for scene_id=1:length(scene_labels)
            scene_label = scene_labels{scene_id};
            current_model_file = get_model_filename(fold, scene_label, model_path);

            if or(~exist(current_model_file, 'file'),overwrite)        
                
                % Load normalizer
                feature_normalizer_filename = get_feature_normalizer_filename(fold, scene_label, feature_normalizer_path);
                if exist(feature_normalizer_filename, 'file')
                    normalizer = load_data(feature_normalizer_filename);
                else
                    error(['Feature normalizer not found [', feature_normalizer_filename, ']']);            
                end

                % Initialize model container
                model_container = struct('normalizer', normalizer, 'models',containers.Map());                
                
                train_items = dataset.train(fold, 'scene_label', scene_label);
                
                % Restructure training data in to structure[files][events]
                ann = containers.Map();
                for item_id=1:length(train_items)
                    item = train_items(item_id);
                    [~, name, ext] = fileparts(item.file);
                    key = name;
                    if ~ann.isKey(key)
                        ann(key) = [];
                    end

                    ann(key) = [ann(key); {item.event_label, item.file, item.event_onset, item.event_offset}];                    
                end
               
                
                % Collect training examples            
                data_positive = containers.Map();
                data_negative = containers.Map();                
                keys = ann.keys;
                for item_id=1:length(ann)
                    list = ann(keys{item_id});
                    events = unique(list(:,1));
                    file = list{1,2};
                    progress(0,'Collecting data',(item_id / length(ann)),[scene_label,' / ',file],fold);
                    
                    % Load features
                    feature_filename = get_feature_filename(file, feature_path);
                    if exist(feature_filename,'file')
                        feature_data = load_data(feature_filename);
                        feature_data = feature_data.feat;
                    else
                        error(['Features not found [', file, ']']);                        
                    end

                    % Normalize features
                    feature_data = model_container.normalizer.normalize(feature_data);
                    
                    for event_id = 1:length(events)
                        event_label = events{event_id};
                        positive_mask = false(size(feature_data,2),1);
                        
                        for i=1:size(list,1)
                            event = list(i,:);
                            if(strcmp(event{1},event_label))
                                start_frame = floor(event{3} / hop_length_seconds)+1;
                                stop_frame = ceil(event{4} / hop_length_seconds)+1;
                            
                                if stop_frame > size(feature_data,2)
                                    stop_frame = size(feature_data,2);
                                end                                
                                positive_mask(start_frame:stop_frame) = 1;
                            end
                        end
                        
                        % Store positive examples
                        if ~data_positive.isKey(event_label)
                            data_positive(event_label) = feature_data(:,positive_mask);
                        else
                            data_positive(event_label) = [data_positive(event_label), feature_data(:,positive_mask)];
                        end
                        
                        % Store negative examples
                        if ~data_negative.isKey(event_label)
                            data_negative(event_label) = feature_data(:,~positive_mask);
                        else
                            data_negative(event_label) = [data_negative(event_label), feature_data(:,~positive_mask)];
                        end                            
                    end
                end
                
                % Train models for each class
                label_id = 1;
                for event_label=data_positive.keys
                    progress(0,'Train models',(label_id / length(data_positive.keys)),[scene_label,' / ',char(event_label)],fold);

                    if strcmp(classifier_method,'gmm')                         
                        [positive_gmm.mu,...
                         positive_gmm.Sigma,...
                         positive_gmm.w,...
                         positive_gmm.avglogl,...
                         positive_gmm.f,...
                         positive_gmm.normlogl,...
                         positive_gmm.avglogl_iter]=gaussmix(data_positive(char(event_label))',...
                                                             [],...
                                                             classifier_params.n_iter+classifier_params.min_covar,...
                                                             classifier_params.n_components,...
                                                             'hf');
                        [negative_gmm.mu,...
                         negative_gmm.Sigma,...
                         negative_gmm.w,...
                         negative_gmm.avglogl,...
                         negative_gmm.f,...
                         negative_gmm.normlogl,...
                         negative_gmm.avglogl_iter]=gaussmix(data_negative(char(event_label))',...
                                                             [],...
                                                             classifier_params.n_iter+classifier_params.min_covar,...
                                                             classifier_params.n_components,...
                                                             'hf');                        
                        model_container.models(char(event_label)) = [positive_gmm, negative_gmm];
                        
                    end
                    label_id = label_id + 1;
                end
                
                % Save models
                save_data(current_model_file, model_container);
            end
        end
    end
    disp('  ');
end

function do_system_testing(dataset, feature_path, result_path, model_path, feature_params, detector_params, dataset_evaluation_mode, classifier_method, overwrite)
    % System testing.
    % 
    % If extracted features are not found from disk, they are extracted but not saved.
    %
    % Parameters
    % ----------
    % dataset : class
    %     dataset class
    % 
    % result_path : str
    %     path where the results are saved.
    % 
    % feature_path : str
    %     path where the features are saved.
    % 
    % model_path : str
    %     path where the models are saved.
    % 
    % feature_params : struct
    %     parameter struct
    % 
    % dataset_evaluation_mode : str ['folds', 'full']
    %     evaluation mode, 'full' all material available is considered to belong to one fold.
    % 
    % classifier_method : str ['gmm']
    %     classifier method, currently only GMM supported
    % 
    % overwrite : bool
    %     overwrite existing models
    % 
    % Returns
    % -------
    % nothing
    % 
    % Raises
    % -------
    % error
    %     classifier_method is unknown.
    %     Model file not found.
    %     Audio file not found.
    % 
    
    if ~strcmp(classifier_method, 'gmm')
        error(['Unknown classifier method [', classifier_method, ']']);
    end
    % Check that target path exists, create if not
    check_path(result_path);
    
    progress(1, 'Testing', 0, '');
    for fold=dataset.folds(dataset_evaluation_mode)        
        scene_labels = dataset.scene_labels();
        for scene_id=1:length(scene_labels)
            scene_label = scene_labels{scene_id};

            current_result_file = get_result_filename(fold, scene_label, result_path);
            if or(~exist(current_result_file,'file'),overwrite)     
                results = [];

                % Load class model container
                model_filename = get_model_filename(fold, scene_label, model_path);
                if exist(model_filename,'file')
                    model_container = load_data(model_filename);
                else
                    error(['Model file not found [',model_filename,']']);                
                end
                
                test_items = dataset.test(fold, 'scene_label', scene_label);
                for item_id=1:length(test_items)
                    item = test_items(item_id);
                    progress(0, 'Testing', (item_id / length(test_items)), [scene_label,' / ',item.file], fold);

                    % Load features
                    feature_filename = get_feature_filename(item.file, feature_path);
                    if exist(feature_filename, 'file')
                        feature_data = load_data(feature_filename);
                        feature_data = feature_data.feat;
                    else
                        % Load audio                
                        if exist(dataset.relative_to_absolute_path(item.file),'file')
                            [y, fs] = load_audio(dataset.relative_to_absolute_path(item.file), 'mono', true, 'target_fs', feature_params.fs);
                        else
                            error(['Audio file not found [', item.file, ']']);
                        end
                        feature_data = feature_extraction(y,...
                                                          fs,...
                                                          'statistics',false,...
                                                          'include_mfcc0',feature_params.include_mfcc0,...
                                                          'include_delta',feature_params.include_delta,...
                                                          'include_acceleration',feature_params.include_acceleration,...
                                                          'mfcc_params',feature_params.mfcc,...
                                                          'delta_params',feature_params.mfcc_delta,...
                                                          'acceleration_params', feature_params.mfcc_acceleration);
                        feature_data = feature_data.feat;
                    end
                    
                    % Normalize features
                    feature_data = model_container.normalizer.normalize(feature_data);
                    
                    current_results = event_detection(feature_data,...
                                                      model_container,...
                                                      'hop_length_seconds',feature_params.hop_length_seconds,...
                                                      'smoothing_window_length_seconds',detector_params.smoothing_window_length,...
                                                      'decision_threshold',detector_params.decision_threshold,...
                                                      'minimum_event_length',detector_params.minimum_event_length,...
                                                      'minimum_event_gap',detector_params.minimum_event_gap);

                    % Store the result
                    for event_id=1:size(current_results,1)
                        results = [results; {dataset.absolute_to_relative(item.file), current_results{event_id,1},current_results{event_id,2},current_results{event_id,3}}];
                    end
                end

                % Save testing results
                fid = fopen(current_result_file, 'wt');
                for result_id=1:size(results,1)
                    result_item = results(result_id,:);
                    fprintf(fid,'%s\t%5.2f\t%5.2f\t%s\n',result_item{1},result_item{2},result_item{3},result_item{4});
                end
                fclose(fid);
            end
        end
    end
    disp('  ');
end

function do_system_evaluation(dataset, dataset_evaluation_mode, result_path)
    % System evaluation. Testing outputs are collected and evaluated. Evaluation results are printed.
    % 
    % Parameters
    % ----------
    % dataset : class
    %     dataset class
    % 
    % result_path : str
    %     path where the results are saved.
    % 
    % dataset_evaluation_mode : str ['folds', 'full']
    %     evaluation mode, 'full' all material available is considered to belong to one fold.
    % 
    % Returns
    % -------
    % nothing
    % 
    % Raises
    % -------
    % error
    %     Result file not found
    % 

    scene_labels = dataset.scene_labels();    
    overall_metrics_per_scene = containers.Map();    
    
    progress(1, 'Collecting results', 0, '');
    for scene_id=1:length(scene_labels) 
        scene_label = scene_labels{scene_id};

        dcase2016_segment_based_metric = DCASE2016_EventDetection_SegmentBasedMetrics(dataset.event_labels('scene_label',scene_label));
        dcase2016_event_based_metric = DCASE2016_EventDetection_EventBasedMetrics(dataset.event_labels('scene_label',scene_label));

        for fold=dataset.folds(dataset_evaluation_mode)                    
            result_filename = get_result_filename(fold, scene_label, result_path);
            if exist(result_filename,'file')
                fid = fopen(result_filename,'r');
                C = textscan(fid, '%s%f%f%s', 'delimiter','\t');
                fclose(fid);             
            else
                error(['Result file not found [',result_filename,']']);          
            end

            results = [];
            for i=1:length(C{1})
                results = [results; {strtrim(C{1}{i}) C{2}(i) C{3}(i) strtrim(C{4}{i})}];
            end
            test_items = dataset.test(fold, 'scene_label', scene_label);
            
            for file_id=1:length(test_items)
                progress(0, 'Collecting results', (file_id / length(test_items)), scene_label, fold);
                item = test_items(file_id);
                current_file_results = [];
                
                for result_id=1:size(results,1)
                    result_line = results(result_id,:);
                    if strcmp(result_line{1}, item.file)
                        current_file_results = [current_file_results; struct('file', result_line{1},...
                                                                             'event_onset',result_line{2},...
                                                                             'event_offset',result_line{3},...
                                                                             'event_label',result_line{4})];
                    end                   
                end
                meta = dataset.file_meta(dataset.absolute_to_relative(item.file));
                
                dcase2016_segment_based_metric.evaluate(current_file_results, meta);               
                dcase2016_event_based_metric.evaluate(current_file_results, meta);        
            end
                        
        end 
        overall_metrics_per_scene(scene_label) = struct('segment_based_metrics',dcase2016_segment_based_metric.results(),...
                                                        'event_based_metrics',dcase2016_event_based_metric.results());
    end
    fprintf('  Evaluation over %d folds\n',dataset.fold_count());
    fprintf('  \n');
    fprintf('  Results per scene\n');
    fprintf('     %-18s | %-5s |  | %-39s \n','','Main','Secondary metrics');
    fprintf('     %-18s | %-5s |  | %-38s | %-14s | %-14s | %-14s |\n','','','Seg/Overall', 'Seg/class', 'Event/Overall', 'Event/Class');
    fprintf('     %-18s | %-5s |  | %-6s : %-5s : %-5s : %-5s : %-5s | %-6s : %-5s | %-6s : %-5s | %-6s : %-5s |\n','Scene','ER','F1', 'ER', 'ER/S', 'ER/D', 'ER/I', 'F1', 'ER', 'F1', 'ER', 'F1', 'ER');
    fprintf('  ----------------------+-------+  +--------+-------+-------+-------+-------+--------+-------+--------+-------+--------+-------+\n');

    averages = struct('segment_based_metrics', struct('overall', struct ('ER', [],'F', []),...
                                                      'class_wise_average', struct('ER', [],'F', [])),...
                      'event_based_metrics', struct('overall', struct('ER', [],'F', []),...
                                                    'class_wise_average', struct('ER', [],'F', [])));

    for scene_id=1:length(scene_labels) 
        scene_label = scene_labels{scene_id};
        fprintf('     %-18s | %5.2f |  | %4.1f %% : %5.2f : %5.2f : %5.2f : %5.2f | %4.1f %% : %5.2f | %4.1f %% : %5.2f | %4.1f %% : %5.2f |\n',...
                scene_label,...
                overall_metrics_per_scene(scene_label).segment_based_metrics.overall.ER,...
                overall_metrics_per_scene(scene_label).segment_based_metrics.overall.F * 100,...
                overall_metrics_per_scene(scene_label).segment_based_metrics.overall.ER,...
                overall_metrics_per_scene(scene_label).segment_based_metrics.overall.S,...
                overall_metrics_per_scene(scene_label).segment_based_metrics.overall.D,...
                overall_metrics_per_scene(scene_label).segment_based_metrics.overall.I,...                
                overall_metrics_per_scene(scene_label).segment_based_metrics.class_wise_average.F * 100,...
                overall_metrics_per_scene(scene_label).segment_based_metrics.class_wise_average.ER,...
                overall_metrics_per_scene(scene_label).event_based_metrics.overall.F * 100,...
                overall_metrics_per_scene(scene_label).event_based_metrics.overall.ER,...
                overall_metrics_per_scene(scene_label).event_based_metrics.class_wise_average.F * 100,...
                overall_metrics_per_scene(scene_label).event_based_metrics.class_wise_average.ER);

        averages.segment_based_metrics.overall.ER = [averages.segment_based_metrics.overall.ER; overall_metrics_per_scene(scene_label).segment_based_metrics.overall.ER];
        averages.segment_based_metrics.overall.F = [averages.segment_based_metrics.overall.F; overall_metrics_per_scene(scene_label).segment_based_metrics.overall.F];
        
        averages.segment_based_metrics.class_wise_average.ER = [averages.segment_based_metrics.class_wise_average.ER; overall_metrics_per_scene(scene_label).segment_based_metrics.class_wise_average.ER];
        averages.segment_based_metrics.class_wise_average.F = [averages.segment_based_metrics.class_wise_average.F; overall_metrics_per_scene(scene_label).segment_based_metrics.class_wise_average.F];

        averages.event_based_metrics.overall.ER = [averages.event_based_metrics.overall.ER; overall_metrics_per_scene(scene_label).event_based_metrics.overall.ER];
        averages.event_based_metrics.overall.F = [averages.event_based_metrics.overall.F; overall_metrics_per_scene(scene_label).event_based_metrics.overall.F];
        
        averages.event_based_metrics.class_wise_average.ER =[averages.event_based_metrics.class_wise_average.ER; overall_metrics_per_scene(scene_label).event_based_metrics.class_wise_average.ER];
        averages.event_based_metrics.class_wise_average.F = [averages.event_based_metrics.class_wise_average.F; overall_metrics_per_scene(scene_label).event_based_metrics.class_wise_average.F];
    end
    fprintf('  ----------------------+-------+  +--------+-------+-------+-------+-------+--------+-------+--------+-------+--------+-------+\n');
    
    fprintf('     %-18s | %5.2f |  | %4.1f %% : %5.2f : %-21s | %4.1f %% : %5.2f | %4.1f %% : %5.2f | %4.1f %% : %5.2f |\n',...
                'Average',...
                mean(averages.segment_based_metrics.overall.ER),...
                mean(averages.segment_based_metrics.overall.F) * 100,...
                mean(averages.segment_based_metrics.overall.ER),...
                '',...               
                mean(averages.segment_based_metrics.class_wise_average.F) * 100,...
                mean(averages.segment_based_metrics.class_wise_average.ER),...
                mean(averages.event_based_metrics.overall.F) * 100,...
                mean(averages.event_based_metrics.overall.ER),...
                mean(averages.event_based_metrics.class_wise_average.F) * 100,...
                mean(averages.event_based_metrics.class_wise_average.ER));    
    fprintf('  \n');
    fprintf('  Results per events \n');
    for scene_id=1:length(scene_labels) 
        scene_label = scene_labels{scene_id};
        fprintf('  \n');
        fprintf('  %-21s \n',upper(scene_label));
        fprintf('  %-20s | %-30s |  | %-15s \n','', 'Segment-based', 'Event-based');
        fprintf('  %-20s | %-5s : %-5s : %-6s : %-5s |  | %-5s : %-5s : %-6s : %-5s |\n', 'Event', 'Nref', 'Nsys', 'F1', 'ER', 'Nref', 'Nsys', 'F1', 'ER');
        fprintf('  ---------------------+-------+-------+--------+-------+  +-------+-------+--------+-------+\n');
        seg_Nref = 0;
        seg_Nsys = 0;

        event_Nref = 0;
        event_Nsys = 0;
        event_labels = dataset.event_labels('scene_label',scene_label);
        for event_label_id=1:length(event_labels),
            event_label = event_labels{event_label_id};
            segment_based_metrics = overall_metrics_per_scene(scene_label).segment_based_metrics.class_wise;
            event_based_metrics = overall_metrics_per_scene(scene_label).event_based_metrics.class_wise;
            fprintf('  %-20s | %5d : %5d : %4.1f %% : %5.2f |  | %5d : %5d : %4.1f %% : %5.2f |\n',event_label,...
                    segment_based_metrics(event_label).Nref,...
                    segment_based_metrics(event_label).Nsys,...
                    segment_based_metrics(event_label).F*100,...
                    segment_based_metrics(event_label).ER,...
                    event_based_metrics(event_label).Nref,...
                    event_based_metrics(event_label).Nsys,...
                    event_based_metrics(event_label).F*100,...
                    event_based_metrics(event_label).ER);
            seg_Nref = seg_Nref + segment_based_metrics(event_label).Nref;
            seg_Nsys = seg_Nsys + segment_based_metrics(event_label).Nsys;

            event_Nref = event_Nref + event_based_metrics(event_label).Nref;
            event_Nsys = event_Nsys + event_based_metrics(event_label).Nsys;
        end
        fprintf('  ---------------------+-------+-------+--------+-------+  +-------+-------+--------+-------+\n');
        fprintf('  %-20s | %5d : %5d : %-14s |  | %5d : %5d : %-14s |\n',...
                'Sum',...
                seg_Nref,...
                seg_Nsys,...
                '',...
                event_Nref,...
                event_Nsys,...
                '');
        fprintf('  %-20s | %-5s   %-5s : %4.1f %% : %5.2f |  | %-5s   %-5s : %4.1f %% : %5.2f |\n',...
                'Average',...
                '', '',...
                overall_metrics_per_scene(scene_label).segment_based_metrics.class_wise_average.F*100,...                
                overall_metrics_per_scene(scene_label).segment_based_metrics.class_wise_average.ER,...
                '', '',...
                overall_metrics_per_scene(scene_label).event_based_metrics.class_wise_average.F*100,...                
                overall_metrics_per_scene(scene_label).event_based_metrics.class_wise_average.ER);
        fprintf('  \n');       
    end
end