function [formattedID] = formatID(id)
%% break apart cell id containing concatenated id info into componenet parts


site_separate = string;
site_combined = string;
gt = string;
session = string;
mID = string;

%% get genotype of mouse

    if contains(id, "63")
        gt = "pos";
        mID = "63";
    end
    
    if contains(id, "66")
        gt = "neg";
        mID = "66";
    end
    
    if contains(id, "67")
        gt = "pos";
        mID = "67";
    end
    
    if contains(id, "68")
        gt = "pos";
        mID = "68";
    end
    
    if contains(id, "70")
        gt = "neg";
        mID = "70";
    end
    
    if contains(id, "71")
        gt = "pos";
        mID = "71";

    end
    
    if contains(id, "72")
        gt = "neg";
        mID = "72";
    end
    
    if contains(id, "73")
        gt = "neg";
        mID = "73";
    end
    if contains(id, "76")
        gt = "pos";
        mID = "76";
    end
    
    if contains(id, "79")
        gt = "neg";
        mID = "79";
    end
    
    if contains(id, "80")
        gt = "pos";
        mID = "80";
    end
    
    if contains(id, "82")
        gt = "pos";
        mID = "82";
    end
    
    if contains(id, "85")
        gt = "pos";
        mID = "85";
    end

 %% get site of mouse
    if contains(id, "vermis", 'IgnoreCase', true) || contains(id, "v", 'IgnoreCase', true)
        site_separate = "vermis";
    elseif contains(id, "latCB", 'IgnoreCase', true) || contains(id, "s", 'IgnoreCase', true)
        site_separate = "latCB";
    else
        site_separate = "error";
    end



    if gt == "pos"
        site_combined = site_separate;
    elseif gt =="neg"
        site_combined = "combined";
    else
        site_combined = "error";
    end

    if contains(id, "_A_")
        session = "A";
    elseif contains(id, "_B_")
        session = "B";
    elseif contains(id, "_C_")
        session = "C";
    elseif contains(id, "training")
        session = "training";
    elseif contains(id, "testing")
        session = "testing";
    else
        session = "error";
    end

% 
% id = {id};
%  mID = {mID};
% site_seperate = {site_separate};
% site_combined = {site_combined};
% session = {session};

formattedID = [id mID gt site_separate site_combined session];

%% filter data based on occupancy

% 
% excl = ["67" "vermis" "A"; "67" "vermis" "B"; "67" "vermis" "C"; "67" "latCB" "A"; "67" "latCB" "B"; "67" "latCB" "C"; "68" "vermis" "B"; "68" "vermis" "B"; "68" "latCB" "A"; "68" "latCB" "B"; "68" "latCB" "C"; "70" "vermis" "B"; "71" "vermis" "A"; "71" "vermis" "B"; "72" "vermis" "A"; "72" "vermis" "B"; "76" "vermis" "A"; "76" "vermis" "B"; "82" "vermis" "A"; "82" "vermis" "B"; "82" "vermis" "C"; "82" "latCB" "A"; "82" "latCB" "C"; "85" "latCB" "A"];
% 
% remove = zeros(size(allID,1),1);
% for i = 1:length(excl)
%     for j = 1:length(allID)
%          if allID(j,1) == excl(i,1) && allID(j,3) == excl(i,2) && allID(j,5) == excl(i,3)
%              remove(j) = 1;
%          end
%     end
% end
% 
% for i = 1:length(remove)
%     if remove == 1
%         allCellData_fp_formatted(i,:) = "";
%     end
% end
% 
% allCellData_fp_formatted = cell(allCellData_fp_formatted);
% 
% output = allCellData_fp_formatted(~strcmp(allCellData_fp_formatted(:,2),""),:);

end