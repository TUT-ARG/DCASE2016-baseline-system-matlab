function results = event_detection(feature_data, model_container, varargin)
    % Sound event detection
    % 
    % Parameters
    % ----------
    % feature_data : matrix [shape=(n_features, t)]
    %     Feature matrix
    % 
    % model_container : struct
    %     Sound event model pairs [positive and negative] in struct
    % 
    % Optional parametes as 'name' value pairs  
    % ----------------------------------------       
    % hop_length_seconds : float > 0.0
    %     Feature hop length in seconds, used to convert feature index into time-stamp
    %     (Default value=0.01)
    % 
    % smoothing_window_length_seconds : float > 0.0
    %     Accumulation window (look-back) length, withing the window likelihoods are accumulated.
    %     (Default value=1.0)
    % 
    % decision_threshold : float > 0.0
    %     Likelihood ratio threshold for making the decision.
    %     (Default value=0.0)
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
    % results : list (event dicts)
    %     Detection result, event list
    % 
    
    % Parse the optional arguments
    [hop_length_seconds, ...
     smoothing_window_length_seconds, ...
     decision_threshold, ...
     minimum_event_length, ...
     minimum_event_gap, unused] = process_options(varargin, ...
        'hop_length_seconds', 0.01, ...
        'smoothing_window_length_seconds', 1.0, ...
        'decision_threshold', 0.0, ...
        'minimum_event_length', 0.1, ...
        'minimum_event_gap', 0.1);
      
    
    smoothing_window = round(smoothing_window_length_seconds / hop_length_seconds);

    results = [];
    event_labels = model_container.models.keys;
    
    for event_id = 1:length(event_labels)
        current_models = model_container.models(event_labels{event_id});
        
        [positive,rp,kh,kp]=gaussmixp(feature_data',...
                        current_models(1).mu,...
                        current_models(1).Sigma,...
                        current_models(1).w);         
        
        [negative,rp,kh,kp]=gaussmixp(feature_data',...
                        current_models(2).mu,...
                        current_models(2).Sigma,...
                        current_models(2).w); 
        % Lets keep the system causal and use look-back while smoothing (accumulating) likelihoods
        for(stop_id=1:size(feature_data,2))
            start_id = stop_id - smoothing_window;
            if start_id < 1
                start_id=1;
            end

            positive(start_id)=sum(positive(start_id:stop_id));
            negative(start_id)=sum(negative(start_id:stop_id));
        end
        likelihood_ratio = positive - negative;
        event_activity = likelihood_ratio > decision_threshold;
        
        % Find contiguous segments and convert frame-ids into times
        event_segments = contiguous_regions(event_activity) * hop_length_seconds;
        
        
        % Preprocess the event segments
        event_segments = postprocess_event_segments(event_segments,...
                                                   'minimum_event_length',minimum_event_length,...
                                                   'minimum_event_gap',minimum_event_gap);
        
        for i=1:size(event_segments,1)
            results = [results; {event_segments(i,1),event_segments(i,2), event_labels{event_id}}];
        end  
    end   
end