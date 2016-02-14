classdef DCASE2013_Scene_EvaluationSet < DatasetBase
  % DCASE 2013 Acoustic scene classification, evaluation dataset    
  %

  properties

  end
  methods
    function obj = DCASE2013_Scene_DevelopmentSet(data_path)            
        obj.name = 'DCASE2013-scene-challenge';

        obj.url = 'http://www.elec.qmul.ac.uk/digitalmusic/sceneseventschallenge/';
        obj.audio_source = 'Field recording';
        obj.audio_type = 'Natural';
        obj.recording_device_model = 'Unknown';
        obj.microphone_model = 'Soundman OKM II Klassik/studio A3 electret microphone';
        obj.evaluation_folds = 5;
        
        obj.local_path = fullfile(data_path, obj.name);

        if(exist(obj.local_path, 'dir') ~= 7),
            mkdir(obj.local_path)
        end

        obj.meta_file = fullfile(obj.local_path, obj.meta_filename);
        obj.evaluation_setup_path = fullfile(obj.local_path, obj.evaluation_setup_folder);

        obj.package_list = [ 
            struct('remote_package','https://archive.org/download/dcase2013_scene_classification_testset/scenes_stereo_testset.zip',...
            	   'local_package',fullfile(obj.local_path, 'scenes_stereo_testset.zip'),...
            	   'local_audio_path',fullfile(obj.local_path, 'scenes_stereo_testset')),                
        ];            
    end
    
    function on_after_extract(obj)            
        % Make legacy dataset compatible with DCASE2016 dataset scheme
        if ~exist(obj.meta_file,'file'),
            section_header('Generating meta file for dataset')
            files = obj.audio_files();
            fid = fopen(obj.meta_file, 'wt');
            for file_id=1:length(files) 
                file = files{file_id};                    
                [raw_path, raw_filename, ext] = fileparts(file);
                relative_path = obj.absolute_to_relative(raw_path);
                label = raw_filename(1:end-2);
                fprintf(fid,'%s\t%s\n',fullfile(relative_path,[raw_filename,ext]), label);
            end                               
            fclose(fid);                
            foot();
        end
        all_folds_found = true;
        
        for fold=1:obj.evaluation_folds
            if ~exist(fullfile(obj.evaluation_setup_path, ['fold', num2str(fold), '_train.txt']),'file')
                all_folds_found = false;
            end
            if ~exist(fullfile(obj.evaluation_setup_path, ['fold', num2str(fold), '_test.txt']),'file')
                all_folds_found = false;
            end
        end
        
        if ~all_folds_found
            section_header('Generating evaluation setup files for dataset')
            if ~exist(obj.evaluation_setup_path,'dir')
                mkdir(obj.evaluation_setup_path);
            end
            classes = [];
            files = [];
            meta = obj.meta();
            for item_id=1:length(meta)
                item = meta(item_id);
                classes = [classes, {item.scene_label}];
                files = [files, {item.file}];               
            end
            
            c = cvpartition(classes,'KFold',obj.evaluation_folds);
            for fold=1:c.NumTestSets
               train_files = files(c.training(fold));
               fid = fopen(fullfile(obj.evaluation_setup_path, ['fold',num2str(fold),'_train.txt']), 'wt');
               for file_id=1:length(train_files)
                  file = train_files{file_id};
                  [raw_path, raw_filename, ext] = fileparts(file);
                  label = raw_filename(1:end-2);
                  fprintf(fid,'%s\t%s\n',fullfile(raw_path,[raw_filename,ext]), label);
               end
               fclose(fid);
               
               test_files = files(c.test(fold));
               fid = fopen(fullfile(obj.evaluation_setup_path, ['fold',num2str(fold),'_test.txt']), 'wt');
               for file_id=1:length(test_files)
                  file = test_files{file_id};
                  [raw_path, raw_filename, ext] = fileparts(file);                      
                  fprintf(fid,'%s\n',fullfile(raw_path,[raw_filename,ext]));
               end                   
               fclose(fid);
               
               fid = fopen(fullfile(obj.evaluation_setup_path, ['fold',num2str(fold),'_evaluate.txt']), 'wt');
               for file_id=1:length(test_files)
                  file = test_files{file_id};
                  [raw_path, raw_filename, ext] = fileparts(file);                      
                  label = raw_filename(1:end-2);
                  fprintf(fid,'%s\t%s\n',fullfile(raw_path,[raw_filename,ext]), label);
               end                   
               fclose(fid);
            end
            foot();
        end        
    end
  end
end