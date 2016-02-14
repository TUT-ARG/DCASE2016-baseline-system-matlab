classdef TUTAcousticScenes_2016_DevelopmentSet < DatasetBase
    % TUT Acoustic scenes 2016 development dataset
    %
    % This dataset is used in DCASE2016 - Task 1, Acoustic scene classification
    %
    %

    properties

    end
    methods
        function obj = TUTAcousticScenes_2016_DevelopmentSet(data_path)
            obj.name = 'TUT-acoustic-scenes-2016-development';
            
            obj.authors = 'Annamaria Mesaros, Toni Heittola, and Tuomas Virtanen';
            obj.name_remote = 'TUT Sound Events 2016, development dataset';
            obj.url = 'https://zenodo.org/record/45739';
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
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.doc.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.doc.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.meta.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.meta.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                       
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.audio.1.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.audio.1.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                                              
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.audio.2.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.audio.2.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                                                                     
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.audio.3.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.audio.3.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                                                                     
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.audio.4.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.audio.4.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                                                                     
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.audio.5.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.audio.5.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),                                                                     
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.audio.6.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.audio.6.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),      
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.audio.7.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.audio.7.zip'),...
                       'local_audio_path',fullfile(obj.local_path, 'audio')),      
                struct('remote_package','https://zenodo.org/record/45739/files/TUT-acoustic-scenes-2016-development.audio.8.zip',...
                       'local_package',fullfile(obj.local_path, 'TUT-acoustic-scenes-2016-development.audio.8.zip'),...
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

                meta_data = containers.Map();
                for fold=1:obj.evaluation_folds
                    % Read train files in
                    train_filename = fullfile(obj.evaluation_setup_path, ['fold',num2str(fold),'_train.txt']);

                    fid = fopen(train_filename, 'rt');
                    C = textscan(fid, '%s%s', 'delimiter','\t');
                    fclose(fid);

                    for file_id=1:length(C{1})
                        meta_data(C{1}{file_id}) = C{2}{file_id};
                    end

                    % Read evaluation files in
                    eval_filename = fullfile(obj.evaluation_setup_path, ['fold',num2str(fold),'_evaluate.txt']);

                    fid = fopen(train_filename, 'rt');
                    C = textscan(fid, '%s%s', 'delimiter','\t');
                    fclose(fid);

                    for file_id=1:length(C{1})
                        meta_data(C{1}{file_id}) = C{2}{file_id};
                    end
                end

                fid = fopen(obj.meta_file, 'wt');
                for file=meta_data.keys
                    [raw_path, raw_filename, ext] = fileparts(char(file));
                    relative_path = obj.absolute_to_relative(raw_path);
                    label = meta_data(char(file));
                    fprintf(fid,'%s\t%s\n',fullfile(relative_path,[raw_filename,ext]), label);
                end
                fclose(fid);

                foot();
            end
        end
    end
end