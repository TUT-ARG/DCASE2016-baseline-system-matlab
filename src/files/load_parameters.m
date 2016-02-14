function params = load_parameters(filename)
	% Load parameters from YAML-file
	% 
    % Parameters
    % ----------
    % filename: str
    %    Path to file
    % 
    % Returns
    % -------
    % parameters: struct
    %     Struct containing loaded parameters
    % 
    % Raises
    % -------
    % error
    %     file is not found.
    % 

    if(exist(filename,'file')),
    	params = ReadYaml(filename);
   	else
   		error(['Parameter file not found [',filename,']']);
   	end
end