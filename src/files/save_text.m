function save_text(file, text)
	% Save text into text file.
	% 
    % Parameters
    % ----------
    % filename: str
    %     Path to file
    % 
    % text: str
    %     String to be saved.
    % 
    % Returns
    % -------
    % nothing
	% 
	
    fid = fopen(file,'w');
    fprintf(fid,'%s',text);
    fclose(fid);
end