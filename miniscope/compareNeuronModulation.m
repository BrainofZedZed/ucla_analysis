function [comparisonTable] = compareNeuronModulation(modulation_struct_d1, alignment_day1, modulation_struct_d2, alignment_day2, modulation_struct_d3, alignment_day3, modulation_struct_d4, alignment_day4, AlignmentTable)
    % Get all unique features across all days
    allFeatures = unique([fieldnames(modulation_struct_d1); fieldnames(modulation_struct_d2); fieldnames(modulation_struct_d3); fieldnames(modulation_struct_d4)]);
    
    % Initialize the comparison table
    comparisonTable = cell(size(AlignmentTable));
    
    % Process each day's modulation struct
    processDay(modulation_struct_d1, alignment_day1, 1);
    processDay(modulation_struct_d2, alignment_day2, 2);
    processDay(modulation_struct_d3, alignment_day3, 3);
    processDay(modulation_struct_d4, alignment_day4, 4);
    
    % Convert the cell array to a table
    comparisonTable = cell2table(comparisonTable, 'VariableNames', {'Day1', 'Day2', 'Day3', 'Day4'});
    
    function processDay(modulation_struct, alignment_day, day_index)
        for i = 1:numel(allFeatures)
            feature = allFeatures{i};
            if isfield(modulation_struct, feature)
                processFeature(feature, modulation_struct.(feature).n_excited, 'excited', alignment_day, day_index);
                processFeature(feature, modulation_struct.(feature).n_suppressed, 'suppressed', alignment_day, day_index);
            end
        end
    end
    
    function processFeature(feature, neuron_ids, modulation_type, alignment_day, day_index)
        for j = 1:numel(neuron_ids)
            neuron_id = neuron_ids(j);
            aligned_row = find(AlignmentTable(:, alignment_day) == neuron_id);
            if ~isempty(aligned_row)
                current_modulation = comparisonTable{aligned_row, day_index};
                if isempty(current_modulation)
                    current_modulation = {};
                elseif ischar(current_modulation)
                    current_modulation = {current_modulation};
                end
                current_modulation{end+1} = sprintf('%s_%s', feature, modulation_type);
                comparisonTable{aligned_row, day_index} = current_modulation;
            end
        end
    end

    % Optionally save as CSV
    % writetable(comparisonTable, 'neuron_modulation_comparison.csv');
end