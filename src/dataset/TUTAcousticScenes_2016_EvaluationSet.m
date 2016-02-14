classdef TUTAcousticScenes_2016_EvaluationSet < DatasetBase
    % TUT Acoustic scenes 2016 evaluation dataset
    %
    % This dataset is used in DCASE2016 - Task 1, Acoustic scene classification
    %
    %

    properties

    end
    methods
        function obj = TUTAcousticScenes_2016_EvaluationSet(data_path)
            obj.name = 'TUT-acoustic-scenes-2016-evaluation';
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
                struct('remote_package',[],'local_package',[],'local_audio_path',fullfile(obj.local_path, 'audio')),
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
            eval_filename = fullfile(obj.evaluation_setup_path, 'evaluate.txt');

            if ~exist(obj.meta_file,'file') && exist(eval_filename,'file')
                section_header('Generating meta file for dataset');
                meta_data = containers.Map();

                fid = fopen(eval_filename, 'rt');
                C = textscan(fid, '%s%s', 'delimiter','\t');
                fclose(fid);
                for file_id=1:length(C{1})
                    meta_data(C{1}{file_id}) = C{2}{file_id};
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