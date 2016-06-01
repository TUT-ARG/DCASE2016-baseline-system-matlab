classdef TUTSoundEvents_2016_DevelopmentSet < DatasetBase
    % TUT Sound events 2016 development dataset
    % 
    % This dataset is used in DCASE2016 - Task 3, Real-life audio sound event detection
    %
    %
    
    properties

    end
    methods
        function obj = TUTSoundEvents_2016_DevelopmentSet(data_path)
            obj.name = 'TUT-sound-events-2016-development';
            obj.authors = 'Annamaria Mesaros, Toni Heittola, and Tuomas Virtanen';

            obj.url = 'http://www.cs.tut.fi/sgn/arg/dcase2016/download/';
            obj.audio_source = 'Field recording';
            obj.audio_type = 'Natural';
            obj.recording_device_model = 'Roland Edirol R-09';
            obj.microphone_model = 'Soundman OKM II Klassik/studio A3 electret microphone';
            obj.evaluation_folds = 4;

            obj.local_path = fullfile(data_path, obj.name);

            if(exist(obj.local_path, 'dir') ~= 7),
                mkdir(obj.local_path)
            end

            obj.meta_file = fullfile(obj.local_path, obj.meta_filename);
            obj.evaluation_setup_path = fullfile(obj.local_path, obj.evaluation_setup_folder);

            obj.package_list = [
                struct('remote_package',[],...
                       'local_package',[],...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),
                struct('remote_package',[],...
                       'local_package',[],...
                       'local_audio_path',fullfile(obj.local_path, 'audio','residential_area')),
                struct('remote_package',[],...
                       'local_package',[],...
                       'local_audio_path',fullfile(obj.local_path, 'audio','home')),
                struct('remote_package','https://zenodo.org/record/45759/files/TUT-sound-events-2016-development.doc.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-sound-events-2016-development.doc.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                
                struct('remote_package','https://zenodo.org/record/45759/files/TUT-sound-events-2016-development.meta.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-sound-events-2016-development.meta.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                
                struct('remote_package','https://zenodo.org/record/45759/files/TUT-sound-events-2016-development.audio.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-sound-events-2016-development.audio.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                
            ];
        end

        function on_after_extract(obj)
            % After dataset packages are downloaded and extracted, meta-files are checked.
            % 
            % Parameters
            % ----------
            % nothing
            % 
            % Returns
            % -------
            % nothing        
            if ~exist(obj.meta_file,'file'),
                section_header('Generating meta file for dataset')
                files = obj.audio_files();
                fid = fopen(obj.meta_file, 'wt');
                for file_id=1:length(files)
                    file = files{file_id};
                    [raw_path, raw_filename, ext] = fileparts(file);
                    relative_path = obj.absolute_to_relative(raw_path);

                    scene_label = strrep(relative_path,['audio',filesep], '');

                    annotation_filename = fullfile(obj.local_path, strrep(relative_path,'audio', 'meta'), [raw_filename, '.ann']);
                    if exist(annotation_filename,'file')
                        anno_fid = fopen(annotation_filename, 'r');
                        C = textscan(anno_fid, '%s%s%s', 'delimiter','\t');
                        fclose(anno_fid);
                        for i=1:length(C{1})
                            fprintf(fid,'%s\t%s\t%f\t%f\t%s\t%s\n',fullfile(relative_path,[raw_filename,ext]), scene_label, str2num(strrep(C{1}{i},',','.')),str2num(strrep(C{2}{i},',','.')),C{3}{i},'m');
                        end
                    end
                end
                fclose(fid);
                foot();
            end
        end

        function count = scene_label_count(obj, varargin)
            [scene_label, unused] = process_options(varargin,'scene_label',false);
            count = length(obj.scene_labels('scene_label',scene_label));
        end

        function labels = event_labels(obj, varargin)
            [scene_label, unused] = process_options(varargin,'scene_label',false);
            labels = [];
            
            meta = obj.meta();
            for file_id=1:length(meta)               
                if scene_label == false
                    labels = [labels; {meta(file_id).event_label}];
                else
                    if strcmp(meta(file_id).scene_label,scene_label)
                        labels = [labels; {meta(file_id).event_label}];
                    end
                end
            end
            labels = sort(unique(labels));
        end

        function files = train(obj, fold, varargin)
            [scene_label, unused] = process_options(varargin,'scene_label',false);

            if length(obj.evaluation_data_train) < (fold+1) || ~isempty(obj.evaluation_data_train{fold+1})
                obj.evaluation_data_train{fold+1} = containers.Map();
                scene_list = obj.scene_labels();
                for scene_id = 1:length(scene_list)
                    scene_label_ = scene_list{scene_id};

                    if fold > 0
                        obj.evaluation_data_train{fold+1}(scene_label_) = [];
                        fid = fopen(fullfile(obj.evaluation_setup_path, [scene_label_,'_fold',num2str(fold),'_train.txt']), 'rt');
                        C = textscan(fid, '%s%s%f%f%s%s', 'delimiter','\t');
                        fclose(fid);
                        for file_id=1:length(C{1})
                            obj.evaluation_data_train{fold+1}(scene_label_) = [obj.evaluation_data_train{fold+1}(scene_label_); struct('file',C{1}{file_id},...
                                                                                                       'scene_label',C{2}{file_id},...
                                                                                                       'event_onset',C{3}(file_id),...
                                                                                                       'event_offset',C{4}(file_id),...
                                                                                                       'event_label',C{5}{file_id},...
                                                                                                       'event_type',C{6}{file_id})];
                        end
                    else
                        meta = obj.meta();
                        data = [];
                        for file_id=1:length(meta)  
                            current_item = meta(file_id);                            
                            if strcmp(current_item.scene_label,scene_label_)
                                data = [data; struct('file',current_item.file,...
                                                     'scene_label',current_item.scene_label,...
                                                     'event_onset',current_item.event_onset,...
                                                     'event_offset',current_item.event_offset,...
                                                     'event_label',current_item.event_label,...
                                                     'event_type',current_item.event_type)];
                            end
                        end
                        obj.evaluation_data_train{1}(scene_label_) = data;
                    end
                end

            end

            if scene_label
                files = obj.evaluation_data_train{fold+1}(scene_label);
            else
                files = [];
                for scene_id = 1:length(scene_list)
                    scene_label_ = scene_list{scene_id};
                    list = obj.evaluation_data_train{fold+1}(scene_label_);

                    for i=1:length(list)
                        files = [files; list(i)];
                    end
                end
            end
        end

        function files = test(obj, fold, varargin)
            [scene_label, unused] = process_options(varargin,'scene_label',false);

            if length(obj.evaluation_data_test) < (fold+1) || ~isempty(obj.evaluation_data_test{fold+1})
                obj.evaluation_data_test{fold+1} = containers.Map();
                scene_list = obj.scene_labels();
                for scene_id = 1:length(scene_list)
                    scene_label_ = scene_list{scene_id};

                    if fold > 0
                        obj.evaluation_data_test{fold+1}(scene_label_) = [];
                        fid = fopen(fullfile(obj.evaluation_setup_path, [scene_label_,'_fold',num2str(fold),'_test.txt']), 'rt');
                        C = textscan(fid, '%s%s', 'delimiter','\t');
                        fclose(fid);
                        for file_id=1:length(C{1})
                            obj.evaluation_data_test{fold+1}(scene_label_) = [obj.evaluation_data_test{fold+1}(scene_label_); struct('file',C{1}{file_id},'scene_label',C{2}{file_id})];
                        end
                    else
                        meta = obj.meta();
                        data = [];
                        for file_id=1:length(meta)  
                            current_item = meta(file_id);  
                            if strcmp(current_item.scene_label,scene_label_)
                                data = [data; struct('file',current_item.file,...
                                                     'scene_label',current_item.scene_label,...
                                                     'event_onset',current_item.event_onset,...
                                                     'event_offset',current_item.event_offset,...
                                                     'event_label',current_item.event_label,...
                                                     'event_type',current_item.event_type)];
                            end
                        end
                        obj.evaluation_data_test{1} = data;
                    end
                end
            end

            if scene_label
                files = obj.evaluation_data_test{fold+1}(scene_label);
            else
                files = [];
                for scene_id = 1:length(scene_list)
                    scene_label_ = scene_list{scene_id};
                    list = obj.evaluation_data_test{fold+1}(scene_label_);

                    for i=1:length(list)
                        files = [files; list(i)];
                    end
                end
            end
        end  
    end
end