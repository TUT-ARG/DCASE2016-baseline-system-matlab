function progress(createline, title, percentage, note, fold)
    % Prints progress line
    % 
    % Parameters
    % ----------
    % title_text : str or None
    %     Title
    % 
    % fold : int > 0 [scalar] or None
    %     Fold number
    % 
    % percentage : float [0-1] or None
    %     Progress percentage.
    % 
    % note : str or None
    %     Note
    % 
    % label : str or None
    %     Label
    % 
    % Returns
    % -------
    % Nothing
    % 
       
    if nargin < 5
        msg = sprintf('  %-20s %3.0f %%%% [%-60s]', title, percentage*100, note);       
    else
        msg = sprintf('  %-20s %3.0f %%%% [fold %d] [%-50s]', title, percentage*100, fold, note);       
    end
    
    if createline
        fprintf(msg);
    else
        reverse_string = repmat('\b',1,length(msg)-1);
        fprintf([reverse_string, msg]);        
    end
end