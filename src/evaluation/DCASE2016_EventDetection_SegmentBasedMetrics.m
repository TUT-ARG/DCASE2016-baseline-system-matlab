classdef DCASE2016_EventDetection_SegmentBasedMetrics < EventDetectionMetrics
    % DCASE2016 Segment based metrics for sound event detection
    % 
    % Supported metrics:
    % - Overall
    %     - Error rate (ER), Substitutions (S), Insertions (I), Deletions (D)
    %     - F-score (F1)
    % - Class-wise
    %     - Error rate (ER), Insertions (I), Deletions (D)
    %     - F-score (F1)    
    % 
    % Examples
    % --------
    % 
    % >> overall_metrics_per_scene = containers.Map();    
    % >> for scene_id=1:length(scene_labels) 
    % >>     scene_label = scene_labels{scene_id};
    % >>     dcase2016_segment_based_metric = DCASE2016_EventDetection_SegmentBasedMetrics(dataset.event_labels('scene_label',scene_label));
    % >>     for fold=dataset.folds(dataset_evaluation_mode)
    % >>         result_filename = get_result_filename(fold, scene_label, result_path);
    % >>         if exist(result_filename,'file')
    % >>             fid = fopen(result_filename,'r');
    % >>             C = textscan(fid, '%s%f%f%s', 'delimiter','\t');
    % >>             fclose(fid);             
    % >>         else
    % >>             error(['Result file not found [',result_filename,']']);          
    % >>         end
    % >>         results = [];
    % >>         for i=1:length(C{1})
    % >>             results = [results; {strtrim(C{1}{i}) C{2}(i) C{3}(i) strtrim(C{4}{i})}];
    % >>         end
    % >>         test_items = dataset.test(fold, 'scene_label', scene_label);    
    % >>         for file_id=1:length(test_items)
    % >>             item = test_items(file_id);
    % >>             current_file_results = [];                
    % >>             for result_id=1:size(results,1)
    % >>                 result_line = results(result_id,:);
    % >>                 if strcmp(result_line{1}, item.file)
    % >>                     current_file_results = [current_file_results; struct('file', result_line{1},...
    % >>                                                                          'event_onset',result_line{2},...
    % >>                                                                          'event_offset',result_line{3},...
    % >>                                                                          'event_label',result_line{4})];
    % >>             end                   
    % >>         end
    % >>         meta = dataset.file_meta(dataset.absolute_to_relative(item.file));
    % >>         dcase2016_segment_based_metric.evaluate(current_file_results, meta);   
    % >>         end
    % >>     end
    % >>     overall_metrics_per_scene(scene_label) = dcase2016_segment_based_metric.results();      
    % >>  end 
    %

    properties
        time_resolution = 1.0;
        overall = struct('Ntp',0,...
                         'Ntn',0,...
                         'Nfp',0,...
                         'Nfn',0,...
                         'Nref',0,...
                         'Nsys',0,...
                         'ER',0,...
                         'S',0,...
                         'D',0,...
                         'I',0);
        class_wise = containers.Map();       
    end
    methods
        function obj = DCASE2016_EventDetection_SegmentBasedMetrics(class_list, varargin)   
            % Initialization method.
            % 
            % Parameters
            % ----------
            % class_list : list
            %     List of class labels to be evaluated.
            %
            % Optional parameters as 'name' value pairs  
            % -----------------------------------------   
            % time_resolution : float > 0
            %     Time resolution used when converting event into event roll.
            %     (Default value = 1.0)
            % 

            [obj.time_resolution,unused] = process_options(varargin,'time_resolution',1.0);
            obj.class_list = class_list;
                        
            for class_id=1:length(class_list)
                obj.class_wise(obj.class_list{class_id}) = struct('Ntp',0,...
                                                                  'Ntn',0,...
                                                                  'Nfp',0,...
                                                                  'Nfn',0,...
                                                                  'Nref',0,...
                                                                  'Nsys',0,...
                                                                  'ER',0,...
                                                                  'S',0,...
                                                                  'D',0,...
                                                                  'I',0);
            end
        end
        
        function evaluate(obj, system_output, annotated_groundtruth)
            % Evaluate system output and annotated ground truth pair.
            % 
            % Use results method to get results.
            % 
            % Parameters
            % ----------
            % annotated_ground_truth : cell array
            %     Ground truth array, list of scene labels
            % 
            % system_output : cell array
            %     System output array, list of scene labels
            % 
            % Returns
            % -------
            % nothing
            % 

            % Convert event list into frame-based representation
            system_event_roll = obj.list_to_roll(system_output, 'time_resolution',obj.time_resolution);
            annotated_event_roll = obj.list_to_roll(annotated_groundtruth, 'time_resolution',obj.time_resolution);
            
            % Fix durations of both event_rolls to be equal
            if size(annotated_event_roll,1) > size(system_event_roll,1)
                padding = zeros(size(annotated_event_roll,1) - size(system_event_roll,1), length(obj.class_list));
                system_event_roll = [system_event_roll; padding];
            end

            if size(system_event_roll,1) > size(annotated_event_roll,1)
                padding = zeros(size(system_event_roll,1) - size(annotated_event_roll,1), length(obj.class_list));
                annotated_event_roll = [annotated_event_roll; padding];
            end
           
            % Compute segment-based overall metrics
            for segment_id=1:size(annotated_event_roll,1)
                annotated_segment = annotated_event_roll(segment_id, :);
                system_segment = system_event_roll(segment_id, :);

                Ntp = sum(system_segment + annotated_segment > 1);
                Ntn = sum(system_segment + annotated_segment == 0);
                Nfp = sum(system_segment - annotated_segment > 0);
                Nfn = sum(annotated_segment - system_segment > 0);

                Nref = sum(annotated_segment);
                Nsys = sum(system_segment);

                S = min(Nref, Nsys) - Ntp;
                D = max(0, Nref - Nsys);
                I = max(0, Nsys - Nref);
                ER = max(Nref, Nsys) - Ntp;

                obj.overall.Ntp = obj.overall.Ntp + Ntp;
                obj.overall.Ntn = obj.overall.Ntn + Ntn;
                obj.overall.Nfp = obj.overall.Nfp + Nfp;
                obj.overall.Nfn = obj.overall.Nfn + Nfn;
                obj.overall.Nref = obj.overall.Nref + Nref;
                obj.overall.Nsys = obj.overall.Nsys + Nsys;
                obj.overall.S = obj.overall.S + S;
                obj.overall.D = obj.overall.D + D;
                obj.overall.I = obj.overall.I + I;
                obj.overall.ER = obj.overall.ER + ER;
            end
            
            for class_id =1:length(obj.class_list)
                class_label = obj.class_list{class_id};
                annotated_segment = annotated_event_roll(:, class_id);
                system_segment = system_event_roll(:, class_id);

                Ntp = sum(system_segment + annotated_segment > 1);
                Ntn = sum(system_segment + annotated_segment == 0);
                Nfp = sum(system_segment - annotated_segment > 0);
                Nfn = sum(annotated_segment - system_segment > 0);

                Nref = sum(annotated_segment);
                Nsys = sum(system_segment);
                
                current_class_values = obj.class_wise(class_label);
                current_class_values.Ntp = current_class_values.Ntp + Ntp;
                current_class_values.Ntn = current_class_values.Ntn + Ntn;
                current_class_values.Nfp = current_class_values.Nfp + Nfp;
                current_class_values.Nfn = current_class_values.Nfn + Nfn;
                current_class_values.Nref = current_class_values.Nref + Nref;
                current_class_values.Nsys = current_class_values.Nsys + Nsys;
                obj.class_wise(class_label) = current_class_values;
            end
        end
        
        function results = results(obj)
            % Get results
            % 
            % Outputs results in struct, format:
            % 
            %     struct(
            %         'overall', struct(
            %            'Pre', 0,
            %            'Rec', 0,
            %            'F', 0,
            %            'ER', 0,
            %            'S', 0,
            %            'D', 0,
            %            'I', 0,
            %         ),
            %         'class_wise', containers.Map() with: 
            %                                             struct('pre',0,
            %                                                    'Rec',0,
            %                                                    'F',0,
            %                                                    'ER',0,
            %                                                    'D',0,
            %                                                    'I',0,
            %                                                    'Nref',0,
            %                                                    'Nsys',0,
            %                                                    'Ntp',0,
            %                                                    'Nfn',0,
            %                                                    'Nfp',0),
            %         'class_wise_overall': struct('F',0,'ER',0),
            %     )
            % 
            % Parameters
            % ----------
            % nothing
            % 
            % Returns
            % -------
            % results : struct
            %     Results struct  
            %            

            results = struct('overall',struct(),'class_wise',containers.Map(),'class_wise_overall',struct());
            
            % Overall metrics
            results.overall.Pre = obj.overall.Ntp / obj.overall.Nsys;
            results.overall.Rec = obj.overall.Ntp / obj.overall.Nref;            
            results.overall.F = 2 * ((results.overall.Pre * results.overall.Rec) / (results.overall.Pre + results.overall.Rec));
            
            results.overall.ER = obj.overall.ER / obj.overall.Nref;
            results.overall.S = obj.overall.S / obj.overall.Nref;
            results.overall.D = obj.overall.D / obj.overall.Nref;
            results.overall.I = obj.overall.I / obj.overall.Nref;
            
            % Class-wise metrics
            class_wise_F = [];
            class_wise_ER = [];
            
            for class_id=1:length(obj.class_list)
                class_label = obj.class_list{class_id};
                current_class_results =  struct();
                
                current_class_results.Pre = obj.class_wise(class_label).Ntp / (obj.class_wise(class_label).Nsys + obj.eps);
                current_class_results.Rec = obj.class_wise(class_label).Ntp / (obj.class_wise(class_label).Nref + obj.eps);
                current_class_results.F = 2 * ((current_class_results.Pre * current_class_results.Rec) / (current_class_results.Pre + current_class_results.Rec + obj.eps));

                current_class_results.ER = (obj.class_wise(class_label).Nfn+obj.class_wise(class_label).Nfp) / (obj.class_wise(class_label).Nref + obj.eps);
                current_class_results.D = obj.class_wise(class_label).Nfn / (obj.class_wise(class_label).Nref + obj.eps);
                current_class_results.I = obj.class_wise(class_label).Nfp / (obj.class_wise(class_label).Nref + obj.eps);

                current_class_results.Nref = obj.class_wise(class_label).Nref;
                current_class_results.Nsys = obj.class_wise(class_label).Nsys;
                current_class_results.Ntp = obj.class_wise(class_label).Ntp;
                current_class_results.Nfn = obj.class_wise(class_label).Nfn;
                current_class_results.Nfp = obj.class_wise(class_label).Nfp;

                class_wise_F = [class_wise_F; current_class_results.F];
                class_wise_ER = [class_wise_ER; current_class_results.ER];
                
                results.class_wise(class_label) = current_class_results;
            end
            results.class_wise_average.F = mean(class_wise_F);
            results.class_wise_average.ER = mean(class_wise_ER);            
        end
    end
end