function event_result = postprocess_event_segments(event_segments, varargin)
	% Post process event segment list. Makes sure that minimum event length and minimum event gap conditions are met.
	% 
    % Parameters
    % ----------
    % event_segments : numpy.ndarray [shape=(2, number of event)]
    %     Event segments, first column has the onset, second has the offset.
    % 
    % minimum_event_length : float > 0.0
    %     Minimum event length in seconds, shorten than given are filtered out from the output.
    %     (Default value=0.1)
    % 
    % minimum_event_gap : float > 0.0
    %     Minimum allowed gap between events in seconds from same event label class.
    %     (Default value=0.1)
    % 
    % Returns
    % -------
    % event_results : numpy.ndarray [shape=(2, number of event)]
    %     postprocessed event segments
    % 

    % Parse the optional arguments
    [minimum_event_length, ...
     minimum_event_gap, unused] = process_options(varargin, ...
        'minimum_event_length', 0.1, ...
        'minimum_event_gap', 0.1);    

    % 1. remove short events
    event_results_1 = [];
    for event_id=1:size(event_segments,1)
        if(event_segments(event_id,2)-event_segments(event_id,1) >= minimum_event_length)
            event_results_1 = [event_results_1; [event_segments(event_id,1),event_segments(event_id,2)]];
        end
    end
    
    if(size(event_results_1,1) > 0)
        % 2. remove small gaps between events
        event_results_2 = [];
        
        % load first event into event buffer
        buffered_event_onset = event_results_1(1,1);
        buffered_event_offset = event_results_1(1,2);        
        for i=2:size(event_results_1,1)
            if event_results_1(i,1) - buffered_event_offset > minimum_event_gap
                % The gap between current event and the buffered is bigger than minimum event gap,
                % store event, and replace buffered event
                event_results_2 = [event_results_2; [buffered_event_onset, buffered_event_offset]];
                buffered_event_onset = event_results_1(i,1);
                buffered_event_offset = event_results_1(i,2);
            else
                % The gap between current event and the buffered is smalle than minimum event gap,
                % extend the buffered event until the current offset
                buffered_event_offset = event_results_1(i,2);
            end
        end
        % store last event from buffer
        event_results_2 = [event_results_2; [buffered_event_onset, buffered_event_offset]];                
        event_result = event_results_2;
    else
        event_result = event_results_1;
    end        
end
