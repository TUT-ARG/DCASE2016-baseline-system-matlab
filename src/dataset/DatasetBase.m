classdef DatasetBase
    % Dataset base class.
    %
    % The specific dataset classes are inherited from this class, and only 
    % needed methods are reimplemented.
    %
    
    properties
        name = 'dataset';
        name_remote = '';
        authors = '';
        evaluation_setup_folder = 'evaluation_setup';
        meta_filename = 'meta.txt';
        error_meta_filename = 'error.txt';
        filelisthash_filename = 'filelist.hash';
        local_path = '';
        meta_file = '';
        error_meta_file = '';
        evaluation_setup_path = '';
        files = [];
        meta_data = [];
        error_meta_data = [];
        evaluation_data_train = {};
        evaluation_data_test = {};
        audio_extensions = {'wav', 'flac'};
        url = '';
        audio_source = '';
        audio_type = '';
        recording_device_model = 'Unknown';
        microphone_model = 'Unknown';
        evaluation_folds = 1;
        package_list = [];
    end
    
    methods
        function obj = DatasetBase()
            
        end

        function output = print_bytes(obj, num_bytes)
            % Output number of bytes according to locale and with IEC 
            % binary prefixes
            %
            % Parameters
            % ----------
            % num_bytes : int > 0 [scalar]
            %     Bytes
            %
            % Returns
            % -------
            % bytes : str
            %     Human readable string
            %

            KiB = 1024;
            MiB = KiB * KiB;
            GiB = KiB * MiB;
            TiB = KiB * GiB;
            PiB = KiB * TiB;
            EiB = KiB * PiB;
            ZiB = KiB * EiB;
            YiB = KiB * ZiB;

            output = [sprintf('%d',num_bytes),' bytes'];
            if(num_bytes > YiB),
               output = [output,sprintf(' (%.4g YiB)', (num_bytes / YiB))];
            elseif(num_bytes > ZiB),
               output = [output,sprintf(' (%.4g ZiB)', (num_bytes / ZiB))];
            elseif(num_bytes > EiB),
               output = [output,sprintf(' (%.4g EiB)', (num_bytes / EiB))];
            elseif(num_bytes > PiB),
               output = [output,sprintf(' (%.4g PiB)', (num_bytes / PiB))];
            elseif(num_bytes > TiB),
               output = [output,sprintf(' (%.4g TiB)', (num_bytes / TiB))];
            elseif(num_bytes > GiB),
               output = [output,sprintf(' (%.4g GiB)', (num_bytes / GiB))];
            elseif(num_bytes > MiB),
               output = [output,sprintf(' (%.4g MiB)', (num_bytes / MiB))];
            elseif(num_bytes > KiB),
               output = [output,sprintf(' (%.4g KiB)', (num_bytes / KiB))];
            end
        end

        function download(obj)
            % Download dataset over the internet to the local path
            %
            % Parameters
            % ----------
            % Nothing
            %
            % Returns
            % -------
            % Nothing
            %
            
            section_header('Download dataset')
            progress(1,'Downloading',(0 / length(obj.package_list)),'');
            for list_id = 1:length(obj.package_list),
                file = obj.package_list(list_id);
                if(~isempty(file.remote_package) && ~exist(file.local_package,'file'))
                    progress(0,'Downloading',(list_id / length(obj.package_list)),file.local_package)
                    
                    urlwrite(file.remote_package,file.local_package);                 
                end
            end
            disp('  ');
            foot();
        end

        function extract(obj)
            % Extract the dataset packages
            %
            % Parameters
            % ----------
            % Nothing
            %
            % Returns
            % -------
            % Nothing
            %
            
            section_header('Extract dataset')
            progress(1,'Extracting',(0 / length(obj.package_list)),'');
            for list_id = 1:length(obj.package_list),
                file = obj.package_list(list_id);
                if ~isempty(strfind(file.local_package,'.zip'))
                    [pathstr,name,ext] = fileparts(file.local_package);
                    
                    zipJavaFile = java.io.File(file.local_package);
                    zip_file = org.apache.tools.zip.ZipFile(zipJavaFile);
                                        
                    % Count files in the zip package
                    file_total_count = 1;
                    entries = zip_file.getEntries;                
                    while entries.hasMoreElements
                        entry = entries.nextElement;
                        file_total_count = file_total_count + 1;
                    end

                    % Loop through files and extract files if needed.
                    file_count = 1;                    
                    entries = zip_file.getEntries; 
                    while entries.hasMoreElements
                        entry = entries.nextElement;
                        entry_name = char(entry.getName);
                        
                        % Trick to omit first level folder
                        pos = strfind(entry_name, [obj.name,filesep]);
                        
                        if (~isempty(pos))
                            entry_name = strrep(entry_name,[obj.name,filesep],'');
                        end
                        target_filename = fullfile(obj.local_path,entry_name);
                        
                        if(~exist(target_filename,'file'))
                            target_file = java.io.File(target_filename);
                            parent_directory = java.io.File(target_file.getParent);
                            parent_directory.mkdirs;
                            try
                                target_file_output_stream = java.io.FileOutputStream(target_file);
                            catch
                                error('Could not create file [%s]',target_filename);
                            end

                            % Extract entry to output stream.
                            input_stream = zip_file.getInputStream(entry);
                            stream_copier = com.mathworks.mlwidgets.io.InterruptibleStreamCopier.getInterruptibleStreamCopier;
                            stream_copier.copyStream(input_stream,target_file_output_stream);
                            
                            % Close streams.
                            target_file_output_stream.close;
                            input_stream.close;
                        end                        
                        progress(0,['Extracting [',num2str(list_id),'/',num2str(length(obj.package_list)),']'],(file_count / file_total_count),[name,ext])
                         
                        file_count = file_count + 1;
                    end
                    zip_file.close();

                    %unzip(file.local_package,obj.local_path);
                end
            end

            disp('  ');
            foot();
        end

        function on_after_extract(obj)
            % Dataset meta data preparation, this will be overloaded in dataset specific classes
            %
            % Parameters
            % ----------
            % Nothing
            % 
            % Returns
            % -------
            % Nothing
            
        end

        function file_list = get_filelist(obj, path)
            % List of files under path (used recursively).
            %
            % Parameters
            % ----------
            % path : str
            %     path to the directory.
            %
            % Returns
            % -------
            % filelist: list
            %     File list
            %
            
            dir_data = dir(path);                                       % Get the data for the current directory
            dir_index = [dir_data.isdir];                               % Find the index for directories
            file_list = {dir_data(~dir_index).name}';                   % Get a list of the files
            if ~isempty(file_list)
                file_list = cellfun(@(x) fullfile(obj.local_path,x),file_list,'UniformOutput',false); % Prepend path to files
            end
            sub_directories = {dir_data(dir_index).name};               % Get a list of the subdirectories

            valid_index = ~ismember(sub_directories,{'.','..'});        % Find index of subdirectories that are not '.' or '..'
            if sum(valid_index)
                for i = find(valid_index)                               % Loop over valid subdirectories
                    next_directory = fullfile(path,sub_directories{i}); % Get the subdirectory path
                    file_list = [file_list; obj.get_filelist(next_directory)];  % Recursively call get_filelist
                end
            end
        end

        function flag = check_filelist(obj)
            % Generates hash from file list and check does it matches with one saved in filelist.hash.
            % If some files have been deleted or added, checking will result False.
            %
            % Parameters
            % ----------
            % Nothing
            % 
            % Returns
            % -------
            % result: bool
            %     Result
            % 
            
            if exist(fullfile(obj.local_path, obj.filelisthash_filename),'file'),
                hash = load_text(fullfile(obj.local_path, obj.filelisthash_filename));
                if strcmp(hash,get_parameter_hash(sort(obj.get_filelist(obj.local_path))))
                    flag = true;
                else
                    flag = false;
                end
            else
              flag = false;
            end
        end

        function save_filelist_hash(obj)
            % Generates file list hash, and saves it as filelist.hash under local_path.
            %
            % Parameters
            % ----------
            % Nothing
            %
            % Returns
            % -------
            % Nothing
            %

            filelist = obj.get_filelist(obj.local_path);
            filelist_hash_not_found = true;
            for file_id=1:length(filelist)
                if ~isempty(strfind(filelist{file_id},obj.filelisthash_filename))
                    break;
                    filelist_hash_not_found = false;
                end
            end
            if filelist_hash_not_found
                filelist = [filelist; fullfile(obj.local_path,obj.filelisthash_filename)];
            end
            filelist = sort(filelist);

            save_text(fullfile(obj.local_path, obj.filelisthash_filename), get_parameter_hash(sort(filelist)))
        end

        function fetch(obj)
            % Download, extract and prepare the dataset.
            % 
            % Parameters
            % ----------
            % Nothing
            % 
            % Returns
            % -------
            % Nothing
            %
                      
            if ~obj.check_filelist(),
                obj.download();
                obj.extract();
                obj.on_after_extract();
                obj.save_filelist_hash();
            end
        end

        function files = audio_files(obj)         
            % Get all audio files in the dataset
            % 
            % Parameters
            % ----------
            % Nothing
            %
            % Returns
            % -------
            % filelist : cell array
            %     Array of filenames.
            %
            
            if isempty(obj.files)
                obj.files = [];
                for list_id = 1:length(obj.package_list),
                    file = obj.package_list(list_id);
                    path = file.local_audio_path;
                    if ~isempty(path)
                        l = dir(path);
                        p = strrep(path,[obj.local_path,filesep],'');
                        for file_id = 1:length(l)
                            [pathstr,name,ext] = fileparts(l(file_id).name);
                            if(sum(strcmp(ext(2:end),obj.audio_extensions) > 0))
                               obj.files = [obj.files; {GetFullPath(fullfile(path,l(file_id).name))}]; 
                            end
                        end
                    end
                end
            end
            files = obj.files;
        end

        function meta = meta(obj)
            % Get meta data for dataset. If not already read from disk, data is read and returned.
            % 
            % meta data struct format:
            %  struct('file','string',...
            %         'scene_label','string',...
            %         'event_onset','float',...
            %         'event_offset','float',...
            %         'event_label','string',...
            %         'event_type','string',...
            %         'id','int');
            %
            % Parameters
            % ----------
            % Nothing
            % 
            % Returns
            % -------
            % meta_data : cell array with meta data structs
            %     Array containing meta data as struct.
            %
            
            if isempty(obj.meta_data)
                obj.meta_data = [];

                meta_id = 1;
                if exist(obj.meta_file,'file'),
                    fid = fopen(obj.meta_file,'r');
                    C = textscan(fid, '%s%s%f%f%s%s', 'delimiter','\t');
                    fclose(fid);

                    for file_id=1:length(C{1})
                        obj.meta_data = [obj.meta_data, struct('file',strtrim(C{1}{file_id}),...
                                                               'scene_label',strtrim(C{2}{file_id}),...
                                                               'event_onset',C{3}(file_id),...
                                                               'event_offset',C{4}(file_id),...
                                                               'event_label',strtrim(C{5}{file_id}),...
                                                               'event_type',strtrim(C{6}{file_id}),...
                                                               'id',meta_id)];

                        meta_id=meta_id+1;
                    end
                end
            end
            meta = obj.meta_data;
        end

        function file_meta = file_meta(obj, file)
            % Meta data for given file
            %
            % Parameters
            % ----------
            % file : str
            %     File name
            % 
            % Returns
            % -------
            % list : array of meta structs
            %    Array containing all meta data related to given file.
            %
            
            file = obj.absolute_to_relative(file);
            meta = obj.meta();
            file_meta = [];
            for file_id=1:length(meta)  
                current_item = meta(file_id);
                if(strcmp(current_item.file,file))
                    file_meta = [file_meta; current_item];
                end
            end        
        end

        function error_meta = error_meta(obj)
            % Get audio error meta data for dataset. If not already read from disk, data is read and returned.
            %
            % meta data struct format:
            %  struct('file','string',...
            %         'event_onset','float',...
            %         'event_offset','float',...
            %         'event_label','string',...
            %         'id','int');
            %
            % Parameters
            % ----------
            % Nothing
            %
            % Returns
            % -------
            % meta_data : cell array with meta data structs
            %     Array containing meta data as struct.
            %

            if isempty(obj.error_meta_data)
                obj.error_meta_data = [];

                error_meta_id = 1;
                if exist(obj.error_meta_file,'file'),
                    fid = fopen(obj.error_meta_file,'r');
                    C = textscan(fid, '%s%f%f%s', 'delimiter','\t');
                    fclose(fid);

                    for file_id=1:length(C{1})
                        obj.error_meta_data = [obj.error_meta_data, struct('file',strtrim(C{1}{file_id}),...
                                                               'event_onset',C{2}(file_id),...
                                                               'event_offset',C{3}(file_id),...
                                                               'event_label',strtrim(C{4}{file_id}),...
                                                               'id',error_meta_id)];

                        error_meta_id=error_meta_id+1;
                    end
                end
            end
            error_meta = obj.error_meta_data;
        end

        function file_error_meta = file_error_meta(obj, file)
            % Error meta data for given file
            %
            % Parameters
            % ----------
            % file : str
            %     File name
            %
            % Returns
            % -------
            % list : array of meta structs
            %    Array containing all error meta data related to given file.
            %

            file = obj.absolute_to_relative(file);
            error_meta = obj.error_meta();
            file_error_meta = [];
            for file_id=1:length(error_meta)
                current_item = error_meta(file_id);
                if(strcmp(current_item.file,file))
                    file_error_meta = [file_error_meta; current_item];
                end
            end
        end

        function folds = folds(obj, mode)
            % List of fold ids
            %
            % Parameters
            % ----------
            % mode : str {'folds','full'}
            %     Fold setup type, possible values are 'folds' and 'full'. In 'full' mode fold number is set 0 and all data is used for training.
            %
            % Returns
            % -------
            % list : array of integers
            %    Fold ids            
                
            if strcmp(mode,'folds')
                folds = 1:obj.evaluation_folds;
            elseif strcmp(mode,'full')
                folds = 0;
            end
        end

        function files = train(obj, fold)
            % List of training items.
            % 
            % Parameters
            % ----------
            % fold : int > 0 [scalar]
            %     Fold id, if zero all meta data is returned.
            %
            % Returns
            % -------
            % list : array of structs
            %     Array containing all meta data assigned to training set for given fold.
            %
            
            if length(obj.evaluation_data_train) < (fold+1) || ~isempty(obj.evaluation_data_train{fold+1})
                if fold > 0
                    obj.evaluation_data_train{fold+1} = [];
                    fid = fopen(fullfile(obj.evaluation_setup_path, ['fold',num2str(fold),'_train.txt']), 'rt'); 
                    C = textscan(fid, '%s%s%f%f%s%s', 'delimiter','\t');
                    fclose(fid);
                    for file_id=1:length(C{1})
                        obj.evaluation_data_train{fold+1} = [obj.evaluation_data_train{fold+1}; struct('file',strtrim(C{1}{file_id}),...
                                                                                                   'scene_label',strtrim(C{2}{file_id}),...
                                                                                                   'event_onset',C{3}(file_id),...
                                                                                                   'event_offset',C{4}(file_id),...
                                                                                                   'event_label',strtrim(C{5}{file_id}),...
                                                                                                   'event_type',strtrim(C{6}{file_id}))];
                    end
                else
                    meta = obj.meta();
                    data = [];
                    for file_id=1:length(meta)  
                        current_item = meta(file_id);

                        data = [data; struct('file',current_item.file,...
                                             'scene_label',current_item.scene_label,...
                                             'event_onset',current_item.event_onset,...
                                             'event_offset',current_item.event_offset,...
                                             'event_label',current_item.event_label,...
                                             'event_type',current_item.event_type)];
                    end
                    obj.evaluation_data_train{1} = data;
                end
            end
            files = obj.evaluation_data_train{fold+1};
        end

        function files = test(obj, fold)
            % List of testing items.
            % 
            % Parameters
            % ----------
            % fold : int > 0 [scalar]
            %     Fold id, if zero all meta data is returned.
            %
            % Returns
            % -------
            % list : array of structs
            %     Array containing all meta data assigned to testing set for given fold.            
            %
            
            if length(obj.evaluation_data_test) < (fold+1) || ~isempty(obj.evaluation_data_test{fold+1})
                if fold > 0
                    obj.evaluation_data_test{fold+1} = [];
                    fid = fopen(fullfile(obj.evaluation_setup_path, ['fold',num2str(fold),'_test.txt']), 'rt'); 
                    C = textscan(fid, '%s%s', 'delimiter','\t');
                    fclose(fid);
                    for file_id=1:length(C{1})
                        obj.evaluation_data_test{fold+1} = [obj.evaluation_data_test{fold+1}; struct('file',strtrim(C{1}{file_id}))];
                    end
                else
                    meta = obj.meta();
                    data = [];
                    for file_id=1:length(meta)  
                        current_item = meta(file_id);

                        data = [data; struct('file',current_item.file,...
                                             'scene_label',current_item.scene_label,...
                                             'event_onset',current_item.event_onset,...
                                             'event_offset',current_item.event_offset,...
                                             'event_label',current_item.event_label,...
                                             'event_type',current_item.event_type)];
                    end
                    obj.evaluation_data_test{1} = data;
                end
            end
            files = obj.evaluation_data_test{fold+1};
        end

        function path = relative_to_absolute_path(obj, path)          
            % Converts relative path into absolute path.
            % 
            % Parameters
            % ----------
            % path : str
            %     Relative path
            % 
            % Returns
            % -------
            % path : str
            %     Absolute path            
            %
            
            path = GetFullPath(fullfile(obj.local_path,path));
        end

        function path = absolute_to_relative(obj, path)
            % Converts absolute path into relative path.
            %
            % Parameters
            % ----------
            % path : str
            %     Absolute path
            %
            % Returns
            % -------
            % path : str
            %     Relative path            
            %
            
            path = strrep(path,fullfile(GetFullPath(obj.local_path),filesep),'');
        end

        function folds = fold_count(obj)
            % Number of fold in the evaluation setup.
            % 
            % Parameters
            % ----------
            % Nothing
            %
            % Returns
            % -------
            % fold_count : int
            %     Number of folds
            %
            
            folds = obj.evaluation_folds;
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
            
            labels = [];
            meta = obj.meta();
            for file_id=1:length(meta)
              labels = [labels; {meta(file_id).scene_label}];
            end
            labels = sort(unique(labels));
        end

        function count = scene_label_count(obj)
            % Number of unique scene labels in the meta data.
            % 
            % Parameters
            % ----------
            % Nothing
            % 
            % Returns
            % -------
            % scene_label_count : int
            %    Number of unique scene labels.
            
            count = length(obj.scene_labels);
        end

        function labels = event_labels(obj)
            % Cell array of unique event labels in the meta data.
            %
            % Parameters
            % ----------
            % Nothing
            %
            % Returns
            % -------
            % labels : cell array
            %     Cell array of event labels in alphabetical order.
            % 
            
            labels = [];
            meta = obj.meta();
            for file_id=1:length(meta)
                labels = [labels; {meta(file_id).event_label}];
            end
            labels = sort(unique(labels));
        end

        function count = event_label_count(obj)
            % Number of unique event labels in the meta data.
            % 
            % Parameters
            % ----------
            % Nothing
            %
            % Returns
            % -------
            % event_label_count : int
            %     Number of unique event labels
            %
            
            count = length(obj.scene_labels);
        end

    end
   
end