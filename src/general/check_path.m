function check_path(path)
    % Check if path exists, if not creates one
    % 
    % Parameters
    % ----------
    % path : str
    %     Path to be checked.
	% 
    % Returns
    % -------
    % Nothing
	% 

    if ~exist(path,'dir')
        mkdir(path);
    end
end