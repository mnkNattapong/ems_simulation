clear; clc;

% ---- user-input parameter ----
start_date   = '2023-03-16 08:00:00';           % Start date (str format: YYYY-MM-DD HH:mm:ss)
                                                % Note that: Default time is 00:00:00
resolution   = 5;                     % Resolution in minutes (int)
time_horizon = 30;                % Optimization horizon in minutes (int)
                                            % Planning      : day ahead (resolution 15 mins)
                                            % Near real-time: 30-min ahead (resolution 5 mins)
pv_capacity  = 66;                     % Solar panel installation capacity in kWp (int) 

% TOU_CHOICE = 'smart1';             % Choice for TOU
% TOU_CHOICE = 'nosell';
TOU_CHOICE = 'THcurrent';

% ---- get load&pv data and buy&sell rate ----
[PARAM.PL,PARAM.PV] = get_load_and_pv_data(start_date, resolution, time_horizon, pv_capacity);
[PARAM.Buy_rate,PARAM.Sell_rate] = getBuySellrate(start_date,resolution,time_horizon,TOU_CHOICE);

% ---- save parameters ----
PARAM.start_date  = start_date;
PARAM.Resolution  = resolution;
PARAM.Horizon     = time_horizon; 
PARAM.PV_capacity = pv_capacity;
PARAM.TOU_CHOICE  = TOU_CHOICE;

% Battery parameters
PARAM.battery.charge_effiency = [0.95 0.95]; %bes charge eff
PARAM.battery.discharge_effiency = [0.95*0.93 0.95*0.93]; %  bes discharge eff note inverter eff 0.93-0.96
PARAM.battery.discharge_rate = [30 30]; % kW max discharge rate
PARAM.battery.charge_rate = [30 30]; % kW max charge rate
PARAM.battery.actual_capacity = [125 125]; % kWh soc_capacity 
PARAM.battery.initial = [50 50]; % userdefined int 0-100 %
PARAM.battery.min = [20 20]; %min soc userdefined int 0-100 %
PARAM.battery.max = [80 80]; %max soc userdefined int 0-100 %
%end of 2 batt

PARAM.battery.num_batt = length(PARAM.battery.actual_capacity);

% end of ---- parameters ----
%%
solution_path = 'solution';
sol = EMS1_opt(PARAM,1,solution_path);

%%
graph_path = 'graph';
[f,t] = EMS1_plot(sol,0,graph_path);
