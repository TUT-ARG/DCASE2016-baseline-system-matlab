function meta_data=load_event_list(file)
  % Load event list from tab delimited text file (csv-formated)
  % 
  % Supported input formats:
  % 
  %     - [event_onset (float)][tab][event_offset (float)]
  %     - [event_onset (float)][tab][event_offset (float)][tab][event_label (string)]
  %     - [file(string)[tab][scene_label][tab][event_onset (float)][tab][event_offset (float)][tab][event_label (string)]
  % 
  % Event struct format:  
  % 
  %     struct(
  %         file', 'filename',...
  %         'scene_label', 'office',...
  %         'event_onset', 0.0,...
  %         'event_offset', 1.0,...
  %         'event_label', 'people_walking',
  %     )
  % 
  % Parameters
  % ----------
  % file : str
  %     Path to the event list in text format (csv)
  % 
  % Returns
  % -------
  % data : array of event structs
  %     Array containing event structs
  %   
  
  fid = fopen(file, 'r');
  C = textscan(fid, '%s%s%s%s%s', 'delimiter','\t');                        
  fclose(fid);
  
  for field_count = 1:5
    if( isempty(C{field_count}{1}) ) 
      field_count = field_count - 1;
      break 
    end
  end
  
  
  meta_data = [];
  for(row_id=1:length(C{1}))
    if(field_count == 2)
      meta_data = [meta_data; struct('event_onset',str2num(C{1}{row_id}),...
                                     'event_offset',str2num(C{2}{row_id}))];            
    elseif(field_count == 3)
      meta_data = [meta_data; struct('event_onset',str2num(C{1}{row_id}),...
                                     'event_offset',str2num(C{2}{row_id}),...
                                     'event_label',C{3}{row_id})];            
    elseif(field_count == 5)
      meta_data = [meta_data; struct('file',C{1}(row_id),...
                                     'scene_label',C{2}(row_id),...
                                     'event_onset',str2num(C{3}{row_id}),...
                                     'event_offset',str2num(C{4}{row_id}),...
                                     'event_label',C{5}{row_id})];            
    end 
  end
end