function data = load_data(file)
	% Load data from pickle file
	% 
    % Parameters
    % ----------
    % filename: str
    %     Path to file
    % 
    % Returns
    % -------
    % data: array or struct
    %     Loaded file.
    % 

    tmp = load(file,'data');
    data = tmp.data;
end