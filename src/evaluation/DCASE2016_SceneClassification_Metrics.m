classdef DCASE2016_SceneClassification_Metrics < handle
    % DCASE 2016 scene classification metrics
    % 
    % Examples
    % --------
    % 
    %     >> dcase2016_scene_metric = DCASE2016_SceneClassification_Metrics(dataset.scene_labels());
    %     >> for fold=dataset.folds(dataset_evaluation_mode)
    %     >>     results = [];
    %     >>     result_filename = get_result_filename(fold, result_path);
    %     >>
    %     >>     if exist(result_filename,'file')
    %     >>         fid = fopen(result_filename, 'r');
    %     >>         C = textscan(fid, '%s%s', 'delimiter', '\t');
    %     >>         fclose(fid);             
    %     >>     else
    %     >>         error(['Result file not found [', result_filename, ']']);
    %     >>     end
    %     >>     y_true = [];
    %     >>     y_pred = [];
    %     >>     for result_id=1:length(results)
    %     >>         y_true = [y_true; {dataset.file_meta(results{result_id,1}).scene_label}];
    %     >>         y_pred = [y_pred; {results{result_id,2}}];
    %     >>     end
    %     >>     dcase2016_scene_metric.evaluate(y_pred, y_true);
    %     >> end
    %     >> results = dcase2016_scene_metric.results();
    % 
    
    properties
        class_list = [];
        accuracies_per_class = [];
        Nref = [];
        Nsys = [];
    end
    methods
        function obj = DCASE2016_SceneClassification_Metrics(class_list) 
            % Initialization method.
            %
            % Parameters
            % ----------
            % class_list : list
            %     Evaluated scene labels in the list
            %
            
            obj.class_list = class_list;
        end

        function results = accuracies(obj, y_true, y_pred, labels)
            % Calculate accuracy
            % 
            % Parameters
            % ----------
            % y_true : cell array
            %     Ground truth array, list of scene labels
            % 
            % y_pred : cell array
            %     System output array, list of scene labels
            % 
            % labels : cell array
            %     array of scene labels
            % 
            % Returns
            % -------
            % array : array [shape=(number of scene labels,)]
            %     Accuracy per scene label class
            % 

            results = zeros(length(labels),1);
            for label_id=1:length(labels)
                N_tested = sum(strcmp(y_true,labels(label_id)));
                correctly_classified = sum(strcmp(y_pred(strcmp(y_true,labels(label_id))),labels(label_id)));
                results(label_id) = correctly_classified/N_tested;
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

            obj.accuracies_per_class = [obj.accuracies_per_class, obj.accuracies(annotated_groundtruth, system_output, obj.class_list)];

            Nsys = zeros(length(obj.class_list),1);
            Nref = zeros(length(obj.class_list),1);

            for class_id=1:length(obj.class_list)
                class_label = obj.class_list(class_id);

                for item=1:length(system_output)
                    if strcmp(system_output{item},class_label)
                        Nsys(class_id) = Nsys(class_id) + 1;
                    end
                end

                for item=1:length(annotated_groundtruth)
                    if strcmp(annotated_groundtruth{item},class_label)
                        Nref(class_id) = Nref(class_id) + 1;
                    end
                end
            end
            obj.Nsys = [obj.Nsys, Nsys];
            obj.Nref = [obj.Nref, Nref];
        end

        function results = results(obj)
            % Get results
            % 
            % Outputs results in struct, format:
            % 
            %     struct(
            %         'class_wise_data', containers.Map() with struct('Nsys',100,'Nref',100),
            %         'class_wise_accuracy', containers.Map(),
            %         'overall_accuracy': mean(mean(obj.accuracies_per_class)),
            %         'Nsys': 100,
            %         'Nref': 100,
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
            accuracies = mean(obj.accuracies_per_class,2);

            class_wise_accuracies = containers.Map();
            class_wise_data = containers.Map();
            for class_id=1:length(obj.class_list)
               class_wise_accuracies(obj.class_list{class_id}) = accuracies(class_id);
               class_wise_data(obj.class_list{class_id}) = struct('Nsys',sum(obj.Nsys(class_id,:)),...
                                                                  'Nref',sum(obj.Nref(class_id,:)));
            end

            Nsys = sum(sum(obj.Nsys));
            Nref = sum(sum(obj.Nref));

            results = struct('overall_accuracy', mean(mean(obj.accuracies_per_class)), ...
                             'class_wise_accuracy', class_wise_accuracies,...
                             'class_wise_data',class_wise_data,...
                             'Nref', Nref,...
                             'Nsys', Nsys);
        end
    end
end