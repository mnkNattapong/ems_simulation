function sol = EMS2_opt(PARAM,is_save,save_path) 
    %%% This function is used to solve optimization problem, consisting 3 parts. 
    %%% (I) Define optimization variable 
    %%% (II) Define constraints
    %%% (III) Call the solver and save parameters.
    
    options = optimoptions('intlinprog','MaxTime',40);
 
    length_optimvar = PARAM.Horizon/PARAM.Resolution; % Length of each optimization variable
    
    % Change the unit of Resolution from (minute => hour) to be used in Expense calculation
    minutes_in_hour = 60;
    resolution_in_hour = PARAM.Resolution/minutes_in_hour;
    
    % Define optimization variables
    Pnet =      optimvar('Pnet',length_optimvar,'LowerBound',-inf,'UpperBound',inf);
    u =         optimvar('u',length_optimvar,'LowerBound',-inf,'UpperBound',inf); % Upper bound of Net profit
    s =         optimvar('s',length_optimvar,'LowerBound',0,'UpperBound',inf);    % Upper bound of SoC diff objective  
    Pdchg =     optimvar('Pdchg',length_optimvar,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
    xdchg =     optimvar('xdchg',length_optimvar,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
    Pchg =      optimvar('Pchg',length_optimvar,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',inf);
    xchg =      optimvar('xchg',length_optimvar,PARAM.battery.num_batt,'LowerBound',0,'UpperBound',1,'Type','integer');
    soc =       optimvar('soc',length_optimvar+1,PARAM.battery.num_batt,'LowerBound',ones(length_optimvar+1,PARAM.battery.num_batt).*PARAM.battery.min,'UpperBound',ones(length_optimvar+1,PARAM.battery.num_batt).*PARAM.battery.max);
    prob =      optimproblem('Objective',sum(u) + sum(s));
    
    % Constraint part
    %--constraint for buy and sell electricity
    prob.Constraints.epicons1 = -resolution_in_hour*PARAM.Buy_rate.*Pnet - u <= 0;

    % %--battery should be used equally
    prob.Constraints.battdeviate1 = soc(2:length_optimvar+1,1) - soc(2:length_optimvar+1,2) <= s;
    prob.Constraints.battdeviate2 = -s <= soc(2:length_optimvar+1,1) - soc(2:length_optimvar+1,2);
    
    %--battery constraint

    prob.Constraints.chargeconsbatt = Pchg <= xchg.*(ones(length_optimvar,PARAM.battery.num_batt).*PARAM.battery.charge_rate);
    
    prob.Constraints.dischargeconsbatt = Pdchg   <= xdchg.*(ones(length_optimvar,PARAM.battery.num_batt).*PARAM.battery.discharge_rate);
    
    prob.Constraints.NosimultDchgAndChgbatt = xchg + xdchg >= 0;
    
    prob.Constraints.NosimultDchgAndChgconsbatt1 = xchg + xdchg <= 1;
    
    %--Pnet constraint
    prob.Constraints.powercons = Pnet == PARAM.PV + sum(Pdchg,2) - PARAM.PL - sum(Pchg,2);
    
    %end of static constraint part
    
    %--soc dynamic constraint 
    soccons = optimconstr(length_optimvar+1,PARAM.battery.num_batt);
    
    soccons(1,1:PARAM.battery.num_batt) = soc(1,1:PARAM.battery.num_batt)  == PARAM.battery.initial ;
    for j = 1:PARAM.battery.num_batt
        soccons(2:length_optimvar+1,j) = soc(2:length_optimvar+1,j)  == soc(1:length_optimvar,j) + ...
                                 (PARAM.battery.charge_effiency(:,j)*100*resolution_in_hour/PARAM.battery.actual_capacity(:,j))*Pchg(1:length_optimvar,j) ...
                                    - (resolution_in_hour*100/(PARAM.battery.discharge_effiency(:,j)*PARAM.battery.actual_capacity(:,j)))*Pdchg(1:length_optimvar,j);
        
    end
    prob.Constraints.soccons = soccons;
    
    %---solve for optimal sol
    sol = solve(prob,'Options',options);
    sol.PARAM = PARAM;
    if is_save == 1
        % Filename is in format: 'TOU_CHOICE_resolution_start_date.mat' 
        % e.g. 'THcurrent_15min_2023-03-16.mat'
        save(strcat(save_path,'/EMS2/',PARAM.TOU_CHOICE,'_',num2str(PARAM.Resolution),'min_',PARAM.start_date,'.mat'),'-struct','sol')
    end
end