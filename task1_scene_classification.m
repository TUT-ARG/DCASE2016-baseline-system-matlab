function task1_scene_classification(varargin)
    % DCASE 2016
    %  Task 1: Acoustic Scene Classification
    %  Baseline system
    %  ---------------------------------------------
    %  Tampere University of Technology / Audio Research Group
    %  Author:  Toni Heittola ( toni.heittola@tut.fi )
    %
    %  System description
    %     This is an baseline implementation for D-CASE 2016 challenge acoustic scene classification task.
    %     Features: MFCC (static+delta+acceleration)
    %     Classifier: GMM
    %
    %
    
    download_external_libraries % Download external libraries
    add_paths;   % Add file paths
    
    rng(123456); % let's make randomization predictable
    
    parser = inputParser;
    parser.addOptional('mode', 'development', @isstr);
    parse(parser, varargin{:});

    params = load_parameters('task1_scene_classification.yaml');
    params = process_parameters(params);

    title('DCASE 2016::Acoustic Scene Classification / Baseline System');

    % Check if mode is defined
    if(strcmp(parser.Results.mode, 'development')),
        args.development = true;
        args.challenge = false;
    elseif(strcmp(parser.Results.mode, 'challenge')),
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
    if strcmp(params.general.development_dataset, 'TUTAcousticScenes_2016_DevelopmentSet')
        dataset = TUTAcousticScenes_2016_DevelopmentSet(params.path.data);
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

        % Collect files in train sets
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
                           params.features,...
                           params.classifier.parameters,...                           
                           dataset_evaluation_mode,...
                           params.classifier.method,...
                           params.classifier.audio_error_handling.clean_data,...
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
                              dataset_evaluation_mode,...
                              params.classifier.method,...
                              params.recognizer.audio_error_handling.clean_data,...
                              params.general.overwrite);
            foot();
        end
        
        % System evaluation
        % ==================================================
        if params.flow.evaluate_system
            section_header('System evaluation');

            do_system_evaluation(dataset,...                                 
                                 params.path.results,...
                                 dataset_evaluation_mode);

            foot();
        end
    % System evaluation with challenge data
    elseif(~args.development && args.challenge)
        % Get dataset container class
        if strcmp(params.general.challenge_dataset, 'TUTAcousticScenes_2016_EvaluationSet')
            challenge_dataset = TUTAcousticScenes_2016_EvaluationSet(params.path.data);
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
                              params.path.challenge_results,...
                              params.path.models,...
                              params.features,...
                              dataset_evaluation_mode,...
                              params.classifier.method,...
                              params.recognizer.audio_error_handling.clean_data,...
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
    % Let's keep hashes backwards compatible after added parameters.
    % Only if error handling is used, they are included in the hash.
    classifier_params = params.classifier;
    if ~classifier_params.audio_error_handling.clean_data
        classifier_params = rmfield(classifier_params,'audio_error_handling');
    end
    params.classifier.hash = get_parameter_hash(classifier_params);

    params.recognizer.hash = get_parameter_hash(params.recognizer);

    params.path.features = fullfile(params.path.base, params.path.features,params.features.hash);
    params.path.feature_normalizers = fullfile(params.path.base, params.path.feature_normalizers,params.features.hash);
    params.path.models = fullfile(params.path.base, params.path.models,params.features.hash, params.classifier.hash);
    params.path.results = fullfile(params.path.base, params.path.results, params.features.hash, params.classifier.hash, params.recognizer.hash);
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
    filename = fullfile(path, [raw_filename, '.', extension]);
end

function filename = get_feature_normalizer_filename(fold, path, extension)
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

    if nargin < 3
        extension = 'mat';
    end    
    filename = fullfile(path, ['scale_fold',num2str(fold), '.', extension]);
end

function filename = get_model_filename(fold, path, extension)
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

    if nargin < 3
        extension = 'mat';
    end
    filename = fullfile(path, ['model_fold',num2str(fold), '.', extension]);
end

function filename = get_result_filename(fold, path, extension)
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

    if nargin < 3
        extension = 'txt';
    end
    filename = fullfile(path, ['results_fold',num2str(fold), '.', extension]);
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

    progress(1,'Extracting',(0 / length(files)),'');
    for file_id = 1:length(files)
        audio_filename = files{file_id};
        [raw_path, raw_filename, ext] = fileparts(audio_filename);
        current_feature_file = get_feature_filename(audio_filename,feature_path);
        
        progress(0,'Extracting',(file_id / length(files)),raw_filename)
        
        if or(~exist(current_feature_file,'file'),overwrite)
            % Load audio data
            if exist(dataset.relative_to_absolute_path(audio_filename),'file')
                [y, fs] = load_audio(dataset.relative_to_absolute_path(audio_filename), 'mono', true, 'target_fs', params.fs);
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
        current_normalizer_file = get_feature_normalizer_filename(fold, feature_normalizer_path);
        if or(~exist(current_normalizer_file,'file'),overwrite)
            % Initialize statistics            
            file_count = length(dataset.train(fold));
            normalizer = FeatureNormalizer();
            train_items = dataset.train(fold);
            
            for item_id=1:length(train_items)
                item = train_items(item_id);
                progress(0, 'Collecting data', (item_id / length(train_items)), item.file, fold);
                
                % Load features
                if exist(get_feature_filename(item.file, feature_path), 'file')
                    feature_data = load_data(get_feature_filename(item.file, feature_path));
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
    disp('  ');
end

function do_system_training(dataset, model_path, feature_normalizer_path, feature_path, feature_params, classifier_params, dataset_evaluation_mode, classifier_method, clean_audio_errors, overwrite)
    % System training
    %
    % model container format (struct):
    %   model.normalizer = normalizer_class;
    %   model.models = containers.Map();
    %   model.models(scene_label) = model_struct;    
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
    % feature_params : struct
    %     parameter struct
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
    % clean_audio_errors : bool
    %      Remove audio errors from the training data
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

    if ~strcmp(classifier_method,'gmm')
        error(['Unknown classifier method [',classifier_method,']']);
    end

    % Check that target path exists, create if not
    check_path(model_path);

    progress(1, 'Collecting data', 0, '');
    for fold=dataset.folds(dataset_evaluation_mode)        
        current_model_file = get_model_filename(fold, model_path);
        if or(~exist(current_model_file, 'file'), overwrite)
            % Load normalizer
            feature_normalizer_filename = get_feature_normalizer_filename(fold, feature_normalizer_path);
            if exist(feature_normalizer_filename, 'file')
                normalizer = load_data(feature_normalizer_filename);
            else
                error(['Feature normalizer not found [', feature_normalizer_filename, ']']);
            end
            
            % Initialize model container
            model_container = struct('normalizer', normalizer, 'models', containers.Map() );
            
            % Collect training examples            
            train_items = dataset.train(fold);
            data = containers.Map();
            for item_id=1:length(train_items)
                item = train_items(item_id);
                progress(0, 'Collecting data', (item_id / length(train_items)), item.file, fold);
                
                % Load features
                feature_filename = get_feature_filename(item.file, feature_path);
                if exist(feature_filename, 'file')
                    feature_data = load_data(feature_filename);
                    feature_data = feature_data.feat;
                else
                    error(['Features not found [', item.file, ']']);
                end
                
                % Scale features
                feature_data = model_container.normalizer.normalize(feature_data);

                % Audio error removal
                if (clean_audio_errors)
                    current_errors = dataset.file_error_meta(item.file);
                    if ~isempty(current_errors)
                        removal_mask = true(size(feature_data,2),1);
                        for error_event_id=1:size(current_errors,2)
                            error_event = current_errors(error_event_id);
                            onset_frame = floor(error_event.event_onset / feature_params.hop_length_seconds) + 1;
                            offset_frame = ceil(error_event.event_offset / feature_params.hop_length_seconds) + 1;

                            if offset_frame > size(feature_data,2)
                                offset_frame = size(feature_data,2);
                            end
                            removal_mask(onset_frame:offset_frame) = 0;
                        end
                        feature_data = feature_data(:,removal_mask);
                    end
                end

                % Store features per class label
                if ~isKey(data,item.scene_label)
                    data(item.scene_label) = feature_data;
                else
                    data(item.scene_label) = [data(item.scene_label), feature_data];
                end
                    
            end
            
            % Train models for each class
            label_id = 1;
            for label=data.keys
                progress(0, 'Train models', (label_id / length(data.keys)), char(label), fold);
            
                if strcmp(classifier_method,'gmm')                                       
                    [gmm.mu, gmm.Sigma, gmm.w , gmm.avglogl, gmm.f, gmm.normlogl, gmm.avglogl_iter]=gaussmix(data(char(label))', [], classifier_params.n_iter+classifier_params.min_covar, classifier_params.n_components, 'hf');
                    model_container.models(char(label)) = gmm;
                else
                   error(['Unknown classifier method ', classifier_method, ']']);                
                end
                label_id = label_id + 1;
            end

            % Save models
            save_data(current_model_file, model_container);
        end
    end
    disp('  ');
end

function do_system_testing(dataset, feature_path, result_path, model_path, feature_params, dataset_evaluation_mode, classifier_method, clean_audio_errors, overwrite)
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
    % clean_audio_errors : bool
    %     Remove audio errors from the training data
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

    if ~strcmp(classifier_method,'gmm')
        error(['Unknown classifier method [',classifier_method,']']);
    end
    % Check that target path exists, create if not
    check_path(result_path);

    progress(1, 'Testing', 0, '');
    for fold=dataset.folds(dataset_evaluation_mode)        
        current_result_file = get_result_filename(fold, result_path);
        if or(~exist(current_result_file, 'file'),overwrite)
            results = [];
            
            % Load class model container
            model_filename = get_model_filename(fold, model_path);
            if exist(model_filename, 'file')
                model_container = load_data(model_filename);
            else
                error(['Model file not found [', model_filename, ']']);
            end
            
            test_items = dataset.test(fold);

            for item_id=1:length(test_items)
                item = test_items(item_id);
                progress(0, 'Testing', (item_id / length(test_items)), item.file,fold);

                % Load features
                feature_filename = get_feature_filename(item.file, feature_path);
                if exist(feature_filename, 'file')
                    feature_data = load_data(feature_filename);
                    feature_data = feature_data.feat;
                else
                    if exist(dataset.relative_to_absolute_path(item.file),'file')
                        [y, fs] = load_audio(dataset.relative_to_absolute_path(item.file), 'mono', true, 'fs', feature_params.fs);
                    else
                        error(['Audio file not found [',item.file,']']);
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

                % Scale features
                feature_data = model_container.normalizer.normalize(feature_data);

                % Audio error removal
                if (clean_audio_errors)
                    current_errors = dataset.file_error_meta(item.file);
                    if ~isempty(current_errors)
                        removal_mask = true(size(feature_data,2),1);
                        for error_event_id=1:size(current_errors,2)
                            error_event = current_errors(error_event_id);
                            onset_frame = floor(error_event.event_onset / feature_params.hop_length_seconds) + 1;
                            offset_frame = ceil(error_event.event_offset / feature_params.hop_length_seconds) + 1;

                            if offset_frame > size(feature_data,2)
                                offset_frame = size(feature_data,2);
                            end
                            removal_mask(onset_frame:offset_frame) = 0;
                        end
                        feature_data = feature_data(:,removal_mask);
                    end
                end

                % Do classification for the block
                if strcmp(classifier_method, 'gmm')
                    current_result = do_classification_gmm(feature_data, model_container);
                else
                   error(['Unknown classifier method ', classifier_method, ']']);
                end

                % Store the result
                results = [results; {item.file, current_result}];

            end

            % Save testing results
            fid = fopen(current_result_file, 'wt');
            for result_id=1:size(results,1)
                result_item = results(result_id,:);
                fprintf(fid,'%s\t%s\n', result_item{1}, result_item{2});
            end
            fclose(fid);
        end
    end
    disp('  ');
end

function result = do_classification_gmm(feature_data, model_container)
    % GMM classification for give feature matrix
    % 
    % model container format (struct):
    %   model.normalizer = normalizer_class;
    %   model.models = containers.Map();
    %   model.models(scene_label) = model_struct;  
    % 
    % Parameters
    % ----------
    % feature_data : matrix [shape=(feature vector length, t)]
    %     feature matrix
    % 
    % model_container : struct
    %     model container
    % 
    % Returns
    % -------
    % result : str
    %     classification result as scene label
    % 

    % Initialize log-likelihood matrix to -inf
    logls = ones(length(model_container.models), 1);
    logls = logls .* -inf;
    
    label_id = 1;
    for label = model_container.models.keys
        [lp, rp, kh, kp] = gaussmixp(feature_data',...
                                     model_container.models(char(label)).mu,...
                                     model_container.models(char(label)).Sigma,...
                                     model_container.models(char(label)).w);
        logls(label_id) = sum(lp);
        label_id = label_id + 1;
    end
    [max_value,classification_result_id] = max(logls);
    k = model_container.models.keys;
    result = k{classification_result_id};
end

function do_system_evaluation(dataset, result_path, dataset_evaluation_mode)
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

    dcase2016_scene_metric = DCASE2016_SceneClassification_Metrics(dataset.scene_labels());

    results_fold = [];
    progress(1,'Collecting results',0,'');

    for fold=dataset.folds(dataset_evaluation_mode)
        dcase2016_scene_metric_fold = DCASE2016_SceneClassification_Metrics(dataset.scene_labels());
        results = [];
        result_filename = get_result_filename(fold, result_path);
        if exist(result_filename,'file')
            fid = fopen(result_filename, 'r');
            C = textscan(fid, '%s%s', 'delimiter', '\t');
            fclose(fid);             
        else
            error(['Result file not found [', result_filename, ']']);
        end
        
        for i=1:length(C{1})
            results = [results; {C{1}{i} C{2}{i}}];
        end
        y_true = [];
        y_pred = [];
        for result_id=1:length(results)
            progress(0, 'Collecting results', (result_id / length(results)), '', fold);
            y_true = [y_true; {dataset.file_meta(results{result_id,1}).scene_label}];
            y_pred = [y_pred; {results{result_id,2}}];
        end
        dcase2016_scene_metric.evaluate(y_pred, y_true);
        dcase2016_scene_metric_fold.evaluate(y_pred, y_true);
        results_fold = [results_fold; dcase2016_scene_metric_fold.results()];
    end
    disp('  ');

    results = dcase2016_scene_metric.results();

    fprintf('  File-wise evaluation, over %d folds\n', dataset.fold_count());

    separator = '     =====================+======+======+===========+';
    fold_labels = '';
    if dataset.fold_count() > 1
        separator = [separator,'  +'];
        for fold=dataset.folds(dataset_evaluation_mode)
            fold_labels = [fold_labels, sprintf(' %-8s |', ['fold',num2str(fold)])];
            separator = [separator,'==========+'];
        end
    end

    fprintf(['     %-20s | %-4s : %-4s | %-8s  |  |',fold_labels,'\n'], 'Scene label', 'Nref', 'Nsys', 'Accuracy');
    fprintf([separator,'\n']);
    labels = results.class_wise_accuracy.keys;
    for label_id=1:length(labels)
        fold_values = '';
        if dataset.fold_count() > 1
            for fold=dataset.folds(dataset_evaluation_mode)
                fold_values = [fold_values, sprintf(' %5.1f %%  |', results_fold(fold).class_wise_accuracy(labels{label_id}) * 100)];
            end
        end
        values = sprintf('     %-20s | %4d : %4d | %5.1f %%   |  |', labels{label_id},...
                                                                     results.class_wise_data(labels{label_id}).Nref,...
                                                                     results.class_wise_data(labels{label_id}).Nsys,...
                                                                     results.class_wise_accuracy(labels{label_id})*100 );
        disp([values, fold_values]);
    end
    fprintf([separator,'\n']);
    fold_values = '';
    if dataset.fold_count() > 1
        for fold=dataset.folds(dataset_evaluation_mode)
            fold_values = [fold_values, sprintf(' %5.1f %%  |', results_fold(fold).overall_accuracy * 100)];
        end
    end

    values = sprintf('     %-20s | %4d : %4d | %5.1f %%   |  |', 'Overall performance',...
                                                                 results.Nref,...
                                                                 results.Nsys,...
                                                                 results.overall_accuracy * 100);
    disp([values, fold_values]);
end