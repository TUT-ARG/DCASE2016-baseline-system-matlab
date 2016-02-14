function result = contiguous_regions(activity_array)    
	% Find contiguous regions from bool valued numpy.array.
    % Transforms boolean values for each frame into pairs of onsets and offsets.
    % 
    % Parameters
    % ----------
    % activity_array : array [shape=(t)]
    %     Event activity array, bool values
    % 
    % Returns
    % -------
    % change_indices : array [shape=(2, number of found changes)]
    %     Onset and offset indices pairs in matrix
	% 
    
    % Find the changes in the activity_array
    change_indices = find(diff(activity_array));

    % Shift change_index with one, focus on frame after the change.
    change_indices = change_indices + 1;

    if activity_array(1)
        % If the first element of activity_array is True add 0 at the beginning
        change_indices = [1; change_indices]; 
    end
    
    if activity_array(end)
        % If the last element of activity_array is True, add the length of the array
        change_indices = [change_indices; activity_array];
    end
    
    % Reshape the result into two columns
    result = reshape(change_indices,[2,length(change_indices)/2])';
end