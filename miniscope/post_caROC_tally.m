gp_dir = uigetdir;  % grandparent dir to loop through
dir_contents = dir(gp_dir);

for i_dir = 3:size(dir_contents,1)
    cd([dir_contents(i_dir).folder '\' dir_contents(i_dir).name]);
    load('ROC_Log.mat');
    ca_file = dir('*data_processed*');
    load(ca_file.name,'dff');
    nn = size(dff,1);
    
    %create empty matrix for cell responses
    % first col = CSp repsonsive, second col = Csm repsonsive, third col frz
    % repsonsive
    resp_mat_both = zeros(nn,3);
    resp_mat_exc = zeros(nn,3);
    resp_mat_sup = zeros(nn,3);
    
    %get vector type
    vec_name = ROC_Log.Vector;
    beh_vec = 0;
    csp_vec = 0;
    csm_vec = 0;
    
    
    % go through vectors
    for i = 1:length(vec_name)
    
        %determine if vec is event or beh
        i_vec = vec_name{i};
        if contains(i_vec,'freez','IgnoreCase',true)
            beh_vec = 1;
        end
        if contains(i_vec,'csp','IgnoreCase',true)
            csp_vec = 1;
        end
        if contains(i_vec,'csm','IgnoreCase',true)
            csm_vec = 1;
        end
    
        % get responsiveness
        r_e = ROC_Log.Excited{i,1};
        if ~isnan(r_e)
            if csp_vec
                resp_mat_exc(r_e,1) = 1;
            end
            if csm_vec
                resp_mat_exc(r_e,2) = 1;
            end
            if beh_vec
                resp_mat_exc(r_e,3) = 1;
            end
        end
    
        r_s = ROC_Log.Suppressed{i,1};
        if ~isnan(r_s)
            if csp_vec
                resp_mat_sup(r_s,1) = 1;
            end
            if csm_vec
                resp_mat_sup(r_s,2) = 1;
            end
            if beh_vec
                resp_mat_sup(r_s,3) = 1;
            end
        end
    beh_vec = 0;
    csm_vec = 0;
    csp_vec = 0;
    end
    
    resp_mat_both = resp_mat_exc + resp_mat_sup;
    
    % do excited response stats
    resp.csp = 0;
    resp.csm = 0;
    resp.frz = 0;
    resp.csp_csm = 0;
    resp.tone_frz = 0;
    
    for n = 1:nn
        r = resp_mat_exc(n,:);
        if r == [1 0 0]
            resp.csp = resp.csp + 1;
        end
        if r == [0 1 0]
            resp.csm = resp.csm + 1;
        end
        if r == [0 0 1]
            resp.frz = resp.frz + 1;
        end
        if r == [1 1 0]
            resp.csp_csm = resp.csp_csm + 1;
        end
        if r == [1 0 1] | r == [0 1 1] | r == [1 1 1]
           resp.tone_frz = resp.tone_frz + 1;
        end
    end
    
    out.labels = {'csp','csm','frz','csp_csm','tone_frz'};
    out.exc_resp = [resp.csp, resp.csm, resp.frz, resp.csp_csm, resp.tone_frz];
    out.nn = nn;
    out.exc_per_resp = out.exc_resp./nn;
    out.per_exc = sum(out.exc_resp) / nn;
    % do suppressed response stats
    resp.csp = 0;
    resp.csm = 0;
    resp.frz = 0;
    resp.csp_csm = 0;
    resp.tone_frz = 0;
    
    for n = 1:nn
        r = resp_mat_sup(n,:);
        if r == [1 0 0]
            resp.csp = resp.csp + 1;
        end
        if r == [0 1 0]
            resp.csm = resp.csm + 1;
        end
        if r == [0 0 1]
            resp.frz = resp.frz + 1;
        end
        if r == [1 1 0]
            resp.csp_csm = resp.csp_csm + 1;
        end
        if r == [1 0 1] | r == [0 1 1] | r == [1 1 1]
           resp.tone_frz = resp.tone_frz + 1;
        end
    end
    
    out.sup_resp = [resp.csp, resp.csm, resp.frz, resp.csp_csm, resp.tone_frz];
    out.sup_per_resp = out.sup_resp./nn;
    out.per_sup = sum(out.sup_resp) / nn;
    
    a = sum(resp_mat_both,2);
    out.any_resp = sum(a~=0);
    out.any_resp_per = out.any_resp / nn;
    
    resp_mat_labels = {'CSp','CSm','freeze'};
    save('ROC_response_tally.mat','out','resp_mat_both','resp_mat_exc','resp_mat_sup', 'resp_mat_labels');
    clearvars -except gp_dir dir_contents i_dir
end


    
