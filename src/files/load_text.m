function text = load_text(file)
	% Load text file
	% 
    % Parameters
    % ----------
    % filename: str
    %     Path to file
    % 
    % Returns
    % -------
    % text: string
    %     Loaded text.
	% 
    
    text = textread(file,'%s');
end