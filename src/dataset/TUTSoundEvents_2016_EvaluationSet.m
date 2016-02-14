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
    end
end