% params
basedir = "C:\Users\Zach\Box\Zach_repo\Projects\Remote memory\Miniscope data\miniscope_cohort2\ROC analyzed";
dirstruct = dir(basedir);
first = 1;
for d = 3:size(dirstruct,1)
    cd(basedir);
    cd(dirstruct(d).name);

    % load ROC_Log
    load('ROC_Log.mat');
    r = ROC_Log;

    data_search = dir('*data_processed*.mat');
    load(data_search.name, 'seedsfn');
    nn = length(seedsfn);

    %% get percentage of neurons excited or suppressed
    i_csp = find(strcmp('cspVector',r.Vector));
    csp_e = length(cell2mat(r.Excited(i_csp))) / nn * 100;
    csp_i = length(cell2mat(r.Suppressed(i_csp))) / nn * 100;

    i_csm = find(strcmp('csmVector',r.Vector));
    csm_e = length(cell2mat(r.Excited(i_csm))) / nn * 100;
    csm_i = length(cell2mat(r.Suppressed(i_csm))) / nn * 100;

    i_frz = find(strcmp('freezingVector',r.Vector));
    frz_e = length(cell2mat(r.Excited(i_frz))) / nn * 100;
    frz_i = length(cell2mat(r.Suppressed(i_frz))) / nn * 100;

    i_cspfrz = find(strcmp('cspFreezingVector',r.Vector));
    csp_frz_e = length(cell2mat(r.Excited(i_cspfrz))) / nn * 100;
    csp_frz_i = length(cell2mat(r.Suppressed(i_cspfrz))) / nn * 100;

    i_csmfrz = find(strcmp('csmFreezingVector',r.Vector));
    csm_frz_e = length(cell2mat(r.Excited(i_csmfrz))) / nn * 100;
    csm_frz_i = length(cell2mat(r.Suppressed(i_csmfrz))) / nn * 100;

    if ~isempty(find(strcmp('shockVector',r.Vector)))
        i_shock = find(strcmp('shockVector',r.Vector));
        shock_e = length(cell2mat(r.Excited(i_shock))) / nn * 100;
        shock_i = length(cell2mat(r.Suppressed(i_shock))) / nn * 100;
    else
        shock_e = NaN;
        shock_i = NaN;
    end

    %% build output table for percentages
    labels = [{'ID'}, {'NN'}, {'CSp_e',} {'CSp_i',} {'CSm_e',} {'CSm_i',} {'freeze_e',} {'freeze_i',} ...
        {'CSp_freeze_e',} {'CSp_freeze_i',} {'CSm_freeze_e',} {'CSm_freeze_i',} ...
        {'shock_e',} {'shock_i'}];
    id = string(dirstruct(d).name);
    i_ROC_perc_table = table(id, nn, csp_e, csp_i, csm_e, csm_i, frz_e, frz_i, csp_frz_e, csp_frz_i, ...
        csm_frz_e, csm_frz_i, shock_e, shock_i, 'VariableNames', labels);

    if first == 1
        ROC_perc_table = i_ROC_perc_table;
    else
        ROC_perc_table = [ROC_perc_table; i_ROC_perc_table];
    end
    %% calculate overlap in population

    % overlap CSp_e and CSm_e
    a = cell2mat(r.Excited(i_csp));
    b = cell2mat(r.Excited(i_csm));
    in = intersect(a,b);
    if ~isempty(in)
        ol.cspe_csme = length(in)/length(b);
        ol.csme_cspe = length(in)/length(a);
    else
        ol.cspe_csme = [];
        ol.csme_cspe = [];
    end

    % overlap CSp_i and CSm_i
    a = cell2mat(r.Suppressed(i_csp));
    b = cell2mat(r.Suppressed(i_csm));
    in = intersect(a,b);
    if ~isempty(in)
        ol.cspi_csmi = length(in)/length(b);
        ol.csmi_cspi = length(in)/length(a);
    else
        ol.cspi_csmi = [];
        ol.csmi_cspi = [];
    end

    % overlap CSp_frz_e and CSm_frz_e
    a = cell2mat(r.Excited(i_cspfrz));
    b = cell2mat(r.Excited(i_csmfrz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.cspfrze_csmfrze = length(in)/length(b);
        ol.csmfrze_cspfrze = length(in)/length(a);
    else
        ol.cspfrze_csmfrze = [];
        ol.csmfrze_cspfrze = [];
    end

    % overlap CSp_frz_i and CSm_frz_i
    a = cell2mat(r.Suppressed(i_cspfrz));
    b = cell2mat(r.Suppressed(i_csmfrz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.cspfrzi_csmfrzi = length(in)/length(b);
        ol.csmfrzi_cspfrzi = length(in)/length(a);
    else
        ol.cspfrzi_csmfrzi = [];
        ol.csmfrzi_cspfrzi = [];
    end

    % overlap CSp_e and CSp_freeze_e
    a = cell2mat(r.Excited(i_csp));
    b = cell2mat(r.Excited(i_cspfrz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.cspe_cspfrze = length(in)/length(b);
        ol.cspfrze_cspe = length(in)/length(a);
    else
        ol.cspe_cspfrze = [];
        ol.cspfrze_cspe = [];
    end

    % overlap CSp_i and CSp_freeze_i
    a = cell2mat(r.Suppressed(i_csp));
    b = cell2mat(r.Suppressed(i_cspfrz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.cspi_cspfrzi = length(in)/length(b);
        ol.cspfrzi_cspi = length(in)/length(a);
    else
        ol.cspi_cspfrzi = [];
        ol.cspfrzi_cspi = [];
    end

    % overlap CSm_e and CSm_freeze_e
    a = cell2mat(r.Excited(i_csm));
    b = cell2mat(r.Excited(i_csmfrz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.csme_csmfrze = length(in)/length(b);
        ol.csmfrze_csme = length(in)/length(a);
    else
        ol.csme_csmfrze = [];
        ol.csmfrze_csme = [];
    end

    % overlap CSm_i and CSm_freeze_i
    a = cell2mat(r.Suppressed(i_csm));
    b = cell2mat(r.Suppressed(i_csmfrz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.csmi_csmfrzi = length(in)/length(b);
        ol.csmfrzi_csmi = length(in)/length(a);
    else
        ol.csmi_csmfrzi = [];
        ol.csmfrzi_csmi = [];
    end

    % overlap CSp_e and freeze_e
    a = cell2mat(r.Excited(i_csp));
    b = cell2mat(r.Excited(i_frz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.cspe_frze = length(in)/length(b);
        ol.frze_cspe = length(in)/length(a);
    else
        ol.cspe_frze = [];
        ol.frze_cspe = [];
    end

    % overlap CSm_e and freeze_e
    a = cell2mat(r.Excited(i_csm));
    b = cell2mat(r.Excited(i_frz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.csme_frze = length(in)/length(b);
        ol.frze_csme = length(in)/length(a);
    else
        ol.csme_frze = [];
        ol.frze_csme = [];
    end

    % overlap CSp_i and freeze_i
    a = cell2mat(r.Suppressed(i_csp));
    b = cell2mat(r.Suppressed(i_frz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.cspi_frzi = length(in)/length(b);
        ol.frzi_cspi = length(in)/length(a);
    else
        ol.cspi_frzi = [];
        ol.frzi_cspi = [];
    end

    % overlap CSm_i and freeze_i
    a = cell2mat(r.Suppressed(i_csm));
    b = cell2mat(r.Suppressed(i_frz));
    in = intersect(a,b);
    if ~isempty(in)
        ol.csmi_frzi = length(in)/length(b);
        ol.frzi_csmi = length(in)/length(a);
    else
        ol.csmi_frzi = [];
        ol.frzi_csmi = [];
    end

    %% make table
    names = fieldnames(ol);
    names = [{'ID'}; names];
    vartypes = ["double"];
    vartypes = repmat(vartypes,[1, length(names)-1]);
    vartypes = ["string", vartypes];

    i_ROC_overlap_table = table('Size', [1,length(names)], 'VariableTypes', vartypes, 'VariableNames', names);
    for i = 1:length(names)
        if i == 1
            i_ROC_overlap_table.(names{i})(1) = id;
        elseif isempty(ol.(names{i}))
            i_ROC_overlap_table.(names{i})(1) = NaN;
        else
            i_ROC_overlap_table.(names{i})(1) = ol.(names{i});
        end
    end
    
    if first == 1
        ROC_overlap_table = i_ROC_overlap_table;
    else
        ROC_overlap_table = [ROC_overlap_table; i_ROC_overlap_table];
    end
    
    first = 0;
    clearvars -except basedir dirstruct d ROC_perc_table ROC_overlap_table first
    
end
