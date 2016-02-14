function md5 = get_parameter_hash(params)
	% Get unique hash string (md5) for given parameter struct
	% 
    % Parameters
    % ----------
    % params : struct
    %     Input parameters
    % 
    % Returns
    % -------
    % md5_hash : str
    %     Unique hash for parameter struct
	% 
    
    opt.method = 'MD5';
    md5 = DataHash(params, opt);
end