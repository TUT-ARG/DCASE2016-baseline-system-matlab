function save_data(file,data)
	% Save variable into a pickle file
	% 
    % Parameters
    % ----------
    % filename: str
    %     Path to file
    % 
    % data: array or struct
    %     Data to be saved.	
    % 
    % Returns
    % -------
    % nothing
    % 
    
    save(file,'data');
end