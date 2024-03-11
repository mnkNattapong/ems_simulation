function [f,t] = EMS2_plot(sol,is_save,save_path)
    % sol -> solution from EMS1_opt
    % num_plot -> choose 6 or 8 plot

    PARAM = sol.PARAM; % Get params from sol
    
    %----------------prepare solution for plotting----------------
    start_date = PARAM.start_date;      % The start_date of optimization
    start_date = datetime(start_date);  % Convert type from (str => datetime)
    end_date = start_date + minutes(PARAM.Horizon);  % Calculate end datetime

    length_optimvar = PARAM.Horizon/PARAM.Resolution;  % Length of optimization variable
    excess_gen = PARAM.PV - PARAM.PL; % Calculate excess generation power
    
    % Define length of vectors ranging from start_date to end_date and step by resolution
    t1 = start_date; t2 = end_date; 
    vect = t1:minutes(PARAM.Resolution):t2 ; vect(end) = []; vect = vect';

    % Change the unit of Resolution from (minute => hour) to be used in Expense calculation
    minutes_in_hour = 60;
    resolution_in_hour = PARAM.Resolution/minutes_in_hour;
    
    % Calculate profit and expense of with and without EMS
    [profit,expense,revenue] = getExpense(sol.Pnet,PARAM.Buy_rate,PARAM.Sell_rate,resolution_in_hour);
    [profit_noems,expense_noems,revenue_noems] = getExpense(PARAM.PV-PARAM.PL,PARAM.Buy_rate,PARAM.Sell_rate,resolution_in_hour);

    
    % Declare the figure size and number of plot
    f = figure('PaperPosition',[0 0 21 24],'PaperOrientation','portrait','PaperUnits','centimeters');
    t = tiledlayout(4,2,'TileSpacing','tight','Padding','tight');
    
    % fig (1,1): SoC of 1st battery with Pchg and Pdchg
    nexttile
    stairs(vect,sol.soc(1:length_optimvar,1),'-k','LineWidth',1.5)
    ylabel('SoC (%)')
    ylim([PARAM.battery.min(:,1)-5 PARAM.battery.max(:,1)+5])
    yticks(PARAM.battery.min(:,1):10:PARAM.battery.max(:,1))
    grid on
    hold on
    stairs(vect,[PARAM.battery.min(:,1)*ones(length_optimvar,1),PARAM.battery.max(:,1)*ones(length_optimvar,1)],'--m','HandleVisibility','off','LineWidth',1.2)
    hold on
    yyaxis right
    stairs(vect,sol.Pchg(:,1),'-b','LineWidth',1)
    hold on 
    stairs(vect,sol.Pdchg(:,1),'-r','LineWidth',1)
    yticks(0:10:PARAM.battery.charge_rate(:,1)+10)
    ylim([0 PARAM.battery.charge_rate(:,1)+10])
    legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
    ylabel('Power (kW)')
    title('State of charge 1 (SoC)','FontSize',24)
    xlabel('Hour')
    % xticks(start_date:hours(3):end_date)
    % datetick('x','HH','keepticks')
    
    % fig (1,2): SoC of 2nd battery with Pchg and Pdchg
    nexttile
    stairs(vect,sol.soc(1:length_optimvar,2),'-k','LineWidth',1.5)
    ylabel('SoC (%)')
    ylim([PARAM.battery.min(:,2)-5 PARAM.battery.max(:,2)+5])
    yticks(PARAM.battery.min(:,2):10:PARAM.battery.max(:,2))
    grid on
    hold on
    stairs(vect,[PARAM.battery.min(:,2)*ones(length_optimvar,1),PARAM.battery.max(:,2)*ones(length_optimvar,1)],'--m','HandleVisibility','off','LineWidth',1.2)
    hold on
    yyaxis right
    stairs(vect,sol.Pchg(:,2),'-b','LineWidth',1)
    hold on 
    stairs(vect,sol.Pdchg(:,2),'-r','LineWidth',1)
    yticks(0:10:PARAM.battery.charge_rate(:,2)+10)
    ylim([0 PARAM.battery.charge_rate(:,2)+10])
    legend('Soc','P_{chg}','P_{dchg}','Location','northeastoutside')
    ylabel('Power (kW)')
    title('State of charge 2 (SoC)','FontSize',24)
    xlabel('Hour')
    % xticks(start_date:hours(3):end_date)
    % datetick('x','HH','keepticks')
    
    % fig (2,1): Load consumption and solar generation profile
    nexttile
    stairs(vect,PARAM.PV,'LineWidth',1.2) 
    ylabel('Solar power (kW)')
    yticks(0:10:40)
    ylim([0 40])
    grid on
    hold on
    yyaxis right
    stairs(vect,PARAM.PL,'LineWidth',1.2)
    ylabel('Load (kW)')
    yticks(0:10:40)
    legend('Solar','load','Location','northeastoutside')
    title('Solar and load power','FontSize',24)
    xlabel('Hour')
    % xticks(start_date:hours(3):end_date)
    % datetick('x','HH','keepticks')
    hold off
    
    % fig (2,2): Pnet = PV + Pdchg - Pchg - Pload
    nexttile
    stairs(vect,max(0,sol.Pnet),'-r','LineWidth',1)
    hold on 
    grid on
    stairs(vect,min(0,sol.Pnet),'-b','LineWidth',1)
    legend('P_{net} > 0 (curtail)','P_{net} < 0 (bought from grid)','Location','northeastoutside')
    title('P_{net} = PV + P_{dchg} - P_{chg} - P_{load}','FontSize',24)
    xlabel('Hour')
    ylabel('P_{net} (kW)')
    % xticks(start_date:hours(3):end_date)
    % datetick('x','HH','keepticks')
    hold off
    
    % fig(3,1): Excess generation power (PV-PL) and status of chg/dchg
    nexttile
    stairs(vect,excess_gen,'-k','LineWidth',1.2)
    ylabel('Excess power (kW)')
    hold on
    grid on
    yyaxis right 
    stairs(vect,sol.xchg(:,1),'-b','LineWidth',1)
    hold on 
    grid on
    stairs(vect,-sol.xdchg(:,1),'-r','LineWidth',1)
    legend('Excess power','x_{chg}','x_{dchg}','Location','northeastoutside')
    title('Excess power = P_{pv} - P_{load} and Battery charge/discharge status','FontSize',24)
    xlabel('Hour')
    % xticks(start_date:hours(3):end_date)
    % datetick('x','HH','keepticks')
    yticks(-2:1:2)
    ylim([-1.5,1.5])
    hold off
    
    % fig(3,2): Cumulative profit with EMS
    nexttile
    stairs(vect,revenue,'-r','LineWidth',1)
    hold on
    stairs(vect,expense,'-b','LineWidth',1)
    ylabel('Expense/Revenue (THB)')
    % ylim([0 50])
    % yticks(0:10:50)
    hold on
    yyaxis right
    stairs(vect,cumsum(profit),'-k','LineWidth',1.5)
    ylabel('Cumulative profit (THB)')
    title('Cumulative profit when using EMS 2','FontSize',24) 
    legend('Expense','Cumulative profit','Location','northeastoutside') 
    grid on
    xlabel('Hour')
    % ylim([0 4000])
    % yticks(0:1000:4000)
    % xticks(start_date:hours(3):end_date)
    % datetick('x','HH','keepticks')
    hold off
    
    % fig(4,1): Pchg, Pdchg, TOU
    nexttile
    stairs(vect,PARAM.Buy_rate,'LineWidth',1.2) 
    ylim([0 8])
    ylabel('TOU (THB)')
    hold on
    grid on
    yyaxis right 
    stairs(vect,sol.Pchg(:,1),'-b','LineWidth',1)
    hold on 
    stairs(vect,sol.Pdchg(:,1),'-r','LineWidth',1)
    ylabel('Power (kW)')
    legend('Buy rate','P_{chg}','P_{dchg}','Location','northeastoutside')
    title('P_{chg},P_{dchg} and TOU','FontSize',24)
    xlabel('Hour')
    % xticks(start_date:hours(3):end_date)
    % datetick('x','HH','keepticks')
    ylim([0 80])
    hold off
    
    % fig(4,2): Cumulative profit without EMS 
    nexttile
    stairs(vect,revenue_noems,'-r','LineWidth',1)
    hold on
    stairs(vect,expense_noems,'-b','LineWidth',1)
    ylabel('expense (THB)')
    % ylim([0 50])
    % yticks(0:10:50)
    yyaxis right
    stairs(vect,cumsum(profit_noems),'-k','LineWidth',1.5)
    ylabel('Cumulative profit (THB)')
    title('Cumulative profit without EMS 2','FontSize',24) 
    legend('Expense','Cumulative profit','Location','northeastoutside') 
    grid on
    xlabel('Hour')
    % ylim([0 4000])
    % yticks(0:1000:4000)
    % xticks(start_date:hours(3):end_date)
    % datetick('x','HH','keepticks')
    hold off
    fontsize(0.6,'centimeters')
    if is_save == 1
        print(f,strcat(save_path,'/EMS2/png/8_plot_',PARAM.TOU_CHOICE,'_',num2str(PARAM.Resolution),'min_',PARAM.start_date,'-dpng'))
        print(f,strcat(save_path,'/EMS2/eps/8_plot_',PARAM.TOU_CHOICE,'_',num2str(PARAM.Resolution),'min_',PARAM.start_date,'-deps'))
    end
    
end