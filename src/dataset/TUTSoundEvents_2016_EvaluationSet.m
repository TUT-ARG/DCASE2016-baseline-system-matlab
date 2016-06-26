classdef TUTSoundEvents_2016_EvaluationSet < DatasetBase
    % TUT Sound events 2016 evaluation dataset
    %
    % This dataset is used in DCASE2016 - Task 3, Real-life audio sound event detection
    %
    % 
       
    properties

    end
    methods
        function obj = TUTSoundEvents_2016_EvaluationSet(data_path)
            obj.name = 'TUT-sound-events-2016-evaluation';
            obj.authors = 'Annamaria Mesaros, Toni Heittola, and Tuomas Virtanen';

            obj.url = 'http://www.cs.tut.fi/sgn/arg/dcase2016/download/';
            obj.audio_source = 'Field recording';
            obj.audio_type = 'Natural';
            obj.recording_device_model = 'Roland Edirol R-09';
            obj.microphone_model = 'Soundman OKM II Klassik/studio A3 electret microphone';
            obj.evaluation_folds = 1;

            obj.local_path = fullfile(data_path, obj.name);

            if(exist(obj.local_path, 'dir') ~= 7),
                mkdir(obj.local_path)
            end

            obj.meta_file = fullfile(obj.local_path, obj.meta_filename);
            obj.evaluation_setup_path = fullfile(obj.local_path, obj.evaluation_setup_folder);

            obj.package_list = [
                struct('remote_package',[],'local_package',[],'local_audio_path',fullfile(obj.local_path, 'audio')),
                struct('remote_package',[],'local_package',[],'local_audio_path',fullfile(obj.local_path, 'audio','residential_area')),
                struct('remote_package',[],'local_package',[],'local_audio_path',fullfile(obj.local_path, 'audio','home')),
                struct('remote_package','http://www.cs.tut.fi/sgn/arg/dcase2016/evaluation_data/TUT-sound-events-2016-evaluation.doc.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-sound-events-2016-evaluation.doc.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),    
                struct('remote_package','http://www.cs.tut.fi/sgn/arg/dcase2016/evaluation_data/TUT-sound-events-2016-evaluation.meta.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-sound-events-2016-evaluation.meta.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                    
                struct('remote_package','http://www.cs.tut.fi/sgn/arg/dcase2016/evaluation_data/TUT-sound-events-2016-evaluation.audio.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-sound-events-2016-evaluation.audio.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                            
            ];
        end

        function on_after_extract(obj)
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

        function labels = scene_labels(obj)
            % Cell array of unique scene labels in the meta data.
            % 
            % Parameters
            % ----------
            % Nothing
            % 
            % Returns
            % -------
            % labels : cell array
            %    Cell array of scene labels in alphabetical order.
            %
            
            labels = [{'home','residential_area'}];
            labels = sort(unique(labels));
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
                        fid = fopen(fullfile(obj.evaluation_setup_path, [scene_label_,'_test.txt']), 'rt');
                        C = textscan(fid, '%s%s', 'delimiter','\t');
                        fclose(fid);

                        data = [];
                        for file_id=1:length(C{1})
                            current_item_label = C{2}(file_id);
                            if strcmp(current_item_label,scene_label_)
                                data = [data; struct('file',C{1}(file_id),'scene_label',C{2}(file_id))];
                            end
                        end
                        obj.evaluation_data_test{1}(scene_label_) = data;
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