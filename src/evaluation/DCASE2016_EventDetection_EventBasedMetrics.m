classdef DCASE2016_EventDetection_EventBasedMetrics < EventDetectionMetrics
    % DCASE2016 Event based metrics for sound event detection
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
    % >>     dcase2016_event_based_metric = DCASE2016_EventDetection_EventBasedMetrics(dataset.event_labels('scene_label',scene_label));
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
    % >>         dcase2016_event_based_metric.evaluate(current_file_results, meta);   
    % >>         end
    % >>     end
    % >>     overall_metrics_per_scene(scene_label) = dcase2016_event_based_metric.results();      
    % >>  end 
    %
    
    properties
        time_resolution = 1.0;
        t_collar = 0.2;
        
        overall = struct('Nref',0,...
                         'Nsys',0,...
                         'Nsubs',0,...                     
                         'Ntp',0,...
                         'Nfp',0,...
                         'Nfn',0);
                     
        class_wise = containers.Map();       
    end
    methods
        function obj = DCASE2016_EventDetection_EventBasedMetrics(class_list, varargin)   
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
            % t_collar : float > 0
            %     Time collar for event onset and offset condition
            %     (Default value = 0.2)
            %

            [obj.time_resolution,obj.t_collar,unused] = process_options(varargin,'time_resolution',1.0,'t_collar',0.2);
            obj.class_list = class_list;            
            
            for class_id=1:length(class_list)
                obj.class_wise(obj.class_list{class_id}) = struct('Nref',0,...
                                                                  'Nsys',0,...
                                                                  'Nsubs',0,...                     
                                                                  'Ntp',0,...
                                                                  'Nfp',0,...
                                                                  'Nfn',0);
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
                    
            % Overall metrics

            % Total number of detected and reference events
            Nsys = size(system_output, 1);
            Nref = size(annotated_groundtruth, 1);

            sys_correct = zeros(Nsys, 1);
            ref_correct = zeros(Nref, 1);

            % Number of correctly transcribed events, onset within a t_collar range
            for j=1:length(annotated_groundtruth)
                for i=1:length(system_output)
                    label_condition = strcmp(annotated_groundtruth(j).event_label, system_output(i).event_label);
                    onset_condition = obj.onset_condition(annotated_groundtruth(j), system_output(i), 't_collar', obj.t_collar);

                    % Offset within a t_collar range or within 20% of ground-truth event's duration
                    offset_condition = obj.offset_condition(annotated_groundtruth(j), system_output(i), 't_collar', obj.t_collar);

                    if(label_condition && onset_condition && offset_condition)
                        ref_correct(j) = 1;
                        sys_correct(i) = 1;
                        break
                    end
                end
            end
            
            Ntp = sum(sys_correct);
                        
            sys_leftover = find(~sys_correct)';
            ref_leftover = find(~ref_correct)';

            Nsubs = 0;
            for j=ref_leftover
                for i=sys_leftover
                    onset_condition = obj.onset_condition(annotated_groundtruth(j), system_output(i), 't_collar', obj.t_collar);

                    % Offset within a t_collar range or within 20% of ground-truth event's duration
                    offset_condition = obj.offset_condition(annotated_groundtruth(j), system_output(i), 't_collar', obj.t_collar);

                    if(onset_condition && offset_condition)
                        Nsubs = Nsubs + 1;
                        break;
                    end
                end
            end

            Nfp = Nsys - Ntp - Nsubs;
            Nfn = Nref - Ntp - Nsubs;
            
            obj.overall.Nref = obj.overall.Nref + Nref;
            obj.overall.Nsys = obj.overall.Nsys + Nsys;
            obj.overall.Ntp = obj.overall.Ntp + Ntp;
            obj.overall.Nsubs = obj.overall.Nsubs + Nsubs;
            obj.overall.Nfp = obj.overall.Nfp + Nfp;
            obj.overall.Nfn = obj.overall.Nfn + Nfn;

            % Class-wise metrics
            for class_id=1:length(obj.class_list)
                class_label = obj.class_list{class_id};
            
                Nref = 0.0;
                Nsys = 0.0;
                Ntp = 0.0;

                % Count event frequencies in the ground truth
                for i=1:length(annotated_groundtruth)
                    if strcmp(annotated_groundtruth(i).event_label, class_label)
                        Nref = Nref + 1;
                    end
                end

                % Count event frequencies in the system output
                for i=1:length(system_output)
                    if strcmp(system_output(i).event_label, class_label)
                        Nsys = Nsys + 1;
                    end
                end

                for j=1:length(annotated_groundtruth)
                    for i=1:length(system_output)
                        if strcmp(annotated_groundtruth(j).event_label,class_label) && strcmp(system_output(i).event_label, class_label)
                            onset_condition = obj.onset_condition(annotated_groundtruth(j), system_output(i), 't_collar', obj.t_collar);

                            % Offset within a +/-100 ms range or within 20% of ground-truth event's duration
                            offset_condition = obj.offset_condition(annotated_groundtruth(j), system_output(i), 't_collar', obj.t_collar);

                            if(onset_condition && offset_condition)
                                Ntp = Ntp + 1;
                                break
                            end
                        end
                    end
                end
                                
                Nfp = Nsys - Ntp;
                Nfn = Nref - Ntp;
                
                current_class_values = obj.class_wise(class_label);
                current_class_values.Nref = current_class_values.Nref + Nref;
                current_class_values.Nsys = current_class_values.Nsys + Nsys;
                
                current_class_values.Ntp = current_class_values.Ntp + Ntp;
                current_class_values.Nfp = current_class_values.Nfp + Nfp;
                current_class_values.Nfn = current_class_values.Nfn + Nfn;
                obj.class_wise(class_label) = current_class_values;
            end
            
        end
        
        function condition = onset_condition(obj, annotated_event, system_event, varargin)
            % Onset condition, checked does the event pair fulfill condition
            % 
            % Condition:
            % 
            % - event onsets are within t_collar each other
            % 
            % Parameters
            % ----------
            % annotated_event : struct
            %     Event struct
            % 
            % system_event : struct
            %     Event struct
            % 
            % Optional parameters as 'name' value pairs  
            % -----------------------------------------   
            % t_collar : float > 0
            %     Defines how close event onsets have to be in order to be considered match. In seconds.
            %     (Default value = 0.2)
            % 
            % Returns
            % -------
            % result : bool
            %     Condition result
            % 

            [t_collar,unused] = process_options(varargin, 't_collar', 0.2);
            condition = abs(annotated_event.event_onset - system_event.event_onset) <= t_collar;
        end

        function condition = offset_condition(obj, annotated_event, system_event, varargin)
            % Offset condition, checking does the event pair fulfill condition
            % 
            % Condition:
            % 
            % - event offsets are within t_collar each other
            % or
            % - system event offset is within the percentage_of_length*annotated event_length
            % 
            % Parameters
            % ----------
            % annotated_event : struct
            %     Event struct
            % 
            % system_event : struct
            %     Event struct
            % 
            % Optional parameters as 'name' value pairs  
            % -----------------------------------------
            % t_collar : float > 0
            %     Defines how close event onsets have to be in order to be considered match. In seconds.
            %     (Default value = 0.2)
            % 
            % percentage_of_length : float [0-1]
            % 
            % 
            % Returns
            % -------
            % result : bool
            %     Condition result            
            % 
            [t_collar,percentage_of_length,unused] = process_options(varargin,'t_collar',0.2,'percentage_of_length',0.5);
            
            annotated_length = annotated_event.event_offset - annotated_event.event_onset;
            condition = abs(annotated_event.event_offset - system_event.event_offset) <= max(t_collar, percentage_of_length * annotated_length);
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
            results.overall.Pre = obj.overall.Ntp / (obj.overall.Nsys + obj.eps);
            results.overall.Rec = obj.overall.Ntp / obj.overall.Nref;            
            results.overall.F = 2 * ((results.overall.Pre * results.overall.Rec) / (results.overall.Pre + results.overall.Rec + obj.eps));
            
            results.overall.ER = (obj.overall.Nfn + obj.overall.Nfp + obj.overall.Nsubs) / obj.overall.Nref;
            results.overall.S = obj.overall.Nsubs / obj.overall.Nref;
            results.overall.D = obj.overall.Nfn / obj.overall.Nref;
            results.overall.I = obj.overall.Nfp / obj.overall.Nref;
            
            % Class-wise metrics
            class_wise_F = [];
            class_wise_ER = [];
            
            for class_id=1:length(obj.class_list)
                class_label = obj.class_list{class_id};
                current_class_results =  struct();
                
                current_class_results.Pre = obj.class_wise(class_label).Ntp / (obj.class_wise(class_label).Nsys + obj.eps);
                current_class_results.Rec = obj.class_wise(class_label).Ntp / obj.class_wise(class_label).Nref;
                current_class_results.F = 2 * ((current_class_results.Pre * current_class_results.Rec) / (current_class_results.Pre + current_class_results.Rec + obj.eps));

                current_class_results.ER = (obj.class_wise(class_label).Nfn+obj.class_wise(class_label).Nfp) / obj.class_wise(class_label).Nref;
                current_class_results.D = obj.class_wise(class_label).Nfn / obj.class_wise(class_label).Nref;
                current_class_results.I = obj.class_wise(class_label).Nfp / obj.class_wise(class_label).Nref;

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