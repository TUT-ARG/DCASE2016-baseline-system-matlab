classdef EventDetectionMetrics < handle
    % Baseclass for sound event metric classes.
    properties
        class_list = [];
        eps = 2.2204460492503131e-16; % equals to numpy.spacing(1) in python 
    end

    methods
        function obj = EventDetectionMetrics()
           
        end

        function max = max_event_offset(obj, data)
            % Get maximum event offset from event list
            %
            % Parameters
            % ----------
            % data : array
            %     Event list, array of event structs
            % 
            % Returns
            % -------
            % max : float > 0
            %     Maximum event offset
            % 

            max = 0;
            for event_id=1:size(data,1)            
                if data(event_id).event_offset > max
                    max = data(event_id).event_offset;
                end
            end
        end

        function event_roll = list_to_roll(obj, data, varargin)            
            % Convert event list into event roll.
            % Event roll is binary matrix indicating event activity withing time segment defined by time_resolution.
            % 
            % Parameters
            % ----------
            % data : array
            %     Event list, list of event structs
            %
            % Optional parameters as 'name' value pairs  
            % ---------------------------------------- 
            % time_resolution : float > 0
            %     Time resolution used when converting event into event roll.
            %     (Default value=0.01)  
            %
            % Returns
            % -------
            % event_roll : matrix [shape=(ceil(data_length * 1 / time_resolution), amount of classes)]
            %     Event roll
            % 

            [time_resolution,unused] = process_options(varargin,'time_resolution',0.01);
            
            % Initialize
            data_length = obj.max_event_offset(data);
            
            event_roll = zeros( ceil(data_length * 1 / time_resolution), length(obj.class_list));

            % Fill-in event_roll
            for event_id=1:size(data,1)
                event = data(event_id);
                
                pos = find(strcmp(obj.class_list,event.event_label));  
                
                onset = floor(event.event_onset * 1 / time_resolution)+1;
                offset = ceil(event.event_offset * 1 / time_resolution);
                
                event_roll(onset:offset, pos) = 1;
            end        
        end
    end
end