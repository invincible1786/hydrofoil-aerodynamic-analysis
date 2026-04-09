% BOEING 929 JETFOIL - NACA 0012 HYDROFOIL ANALYSIS
% This script calculates and plots aerodynamic performance
% Parameters based on published Boeing 929 specifications

clc; clear; close all;

% Set up plotting defaults
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 13);
set(groot, 'defaultLineLineWidth', 2.2);

% Define colors for consistency across plots
C.blue   = [0.07 0.36 0.65];   % Dark blue for primary data
C.red    = [0.80 0.13 0.13];   % Dark red for secondary data
C.green  = [0.13 0.55 0.13];   % Dark green for design points
C.orange = [0.90 0.45 0.00];   % Orange for optimal points
C.purple = [0.49 0.18 0.56];   % Purple
C.grey   = [0.45 0.45 0.45];   % Grey for reference lines
C.lblue  = [0.65 0.81 0.89];   % Light blue for shading
C.lred   = [0.98 0.70 0.70];   % Light red

% VESSEL AND FOIL PARAMETERS
% Boeing 929 Jetfoil - all values from published specs

rho = 1025;           % Seawater density (kg/m³)
mu = 1.07e-3;         % Seawater viscosity at 15°C (Pa·s)
chord = 1.8;          % Foil chord length (m)
S = 18.0;             % Total foil reference area (m²)
W = 961380;           % Vessel weight in Newtons (98,000 kg × 9.81)
V_cruise = 21.6;      % Design cruise speed (m/s) = 42 knots

% ANGLE OF ATTACK RANGE
% Hydrofoils operate between 0°-12°, but we analyze -4° to 18° to show stall
alpha_deg = -4 : 0.25 : 18;
alpha = deg2rad(alpha_deg);

% REYNOLDS NUMBER CALCULATION
Re = rho * V_cruise * chord / mu;

fprintf('\n---- BOEING 929 JETFOIL - NACA 0012 ANALYSIS ----\n');
fprintf('Vessel gross weight    : %.0f N  (%.0f kg)\n', W, W/9.81);
fprintf('Foil reference area    : %.1f m²\n', S);
fprintf('Chord length           : %.2f m\n', chord);
fprintf('Cruise speed           : %.1f m/s  (%.1f knots)\n', V_cruise, V_cruise*1.94384);
fprintf('Reynolds Number        : %.3e  [fully turbulent]\n\n', Re);

% AERODYNAMIC COEFFICIENTS FOR NACA 0012
% Reference: Ladson et al. (NACA TM-100526) at Re ≈ 10^7
% Physical benchmarks:
%   - Linear region: dCL/dα ≈ 0.1095/deg (thin airfoil theory)
%   - Stall: ±11° (turbulent boundary layer)
%   - CL_max: 1.52  (from Ladson et al.)
%   - CD_min: 0.0060  (turbulent flat plate)
%   - Post-stall drag rise

% LIFT COEFFICIENT - LINEAR REGION + STALL
CL = 2 * pi * alpha;          % Linear region (thin-airfoil theory)

stall_ang = 11.0;             % Stall onset (deg) — validated for Re~10^7
CL_max    = 1.52;             % Peak CL from Ladson et al.

% Positive stall: smooth cosine roll-off
mask_p = alpha_deg > stall_ang;
excess_p = alpha_deg(mask_p) - stall_ang;
CL(mask_p) = CL_max .* cos(deg2rad(7.5 * excess_p));

% Negative stall: symmetric NACA 0012
mask_n = alpha_deg < -stall_ang;
excess_n = abs(alpha_deg(mask_n)) - stall_ang;
CL(mask_n) = -CL_max .* cos(deg2rad(7.5 * excess_n));

% Clamp to avoid cos oscillation beyond deep stall
CL = max(min(CL, CL_max), -CL_max);

% DRAG COEFFICIENT - PARABOLIC POLAR FORM
% CD = CD0 + k*CL^2
% Submerged foil has lower k due to surface proximity effect
CD0 = 0.0060;   % Minimum drag at zero lift
k = 0.040;      % Induced drag coefficient
CD  = CD0 + k * CL.^2;

% POST-STALL DRAG RISE - Sheldahl & Klimas data
% Add smooth transition above stall angle
post_p = alpha_deg > stall_ang;
post_n = alpha_deg < -stall_ang;

% Cubic power gives realistic S-shaped rise
CD(post_p) = CD(post_p) + 0.012 * (alpha_deg(post_p) - stall_ang).^2.2;
CD(post_n) = CD(post_n) + 0.012 * (abs(alpha_deg(post_n)) - stall_ang).^2.2;
CD = min(CD, 0.38);   % Cap CD to realistic maximum

% PITCHING MOMENT - Near zero for symmetric airfoil
CM = zeros(size(alpha));
CM(mask_p) = -0.05 * (alpha_deg(mask_p) - stall_ang) / 10;
CM(mask_n) = 0.05 * (abs(alpha_deg(mask_n)) - stall_ang) / 10;

% EFFICIENCY RATIO
LD = CL ./ (CD + 1e-8);

% FORCES AT CRUISE SPEED
q = 0.5 * rho * V_cruise^2 * S;   % Dynamic pressure × area
Lift = q .* CL;                   % Lift force (N)
Drag = q .* CD;                   % Drag force (N)

% OPERATING POINT - CRUISE CONDITION
% Boeing 929 designed to cruise at 5° angle of attack
% This gives good L/D ratio and stable trim
alpha_cruise = 5.0;   % degrees (explicit design choice)
cruise_idx = find(alpha_deg >= alpha_cruise, 1, 'first');

% FIND KEY OPERATING POINTS
% Best L/D angle (positive AoA only)
pos_only = alpha_deg >= 0;
LD_pos = LD;
LD_pos(~pos_only) = -inf;
[LD_max, best_idx] = max(LD_pos);
alpha_bestLD = alpha_deg(best_idx);

% Maximum lift point (stall)
[CL_max_actual, stall_idx] = max(CL);

% TAKE-OFF SPEEDS at different angles of attack
AoA_to_set = [4, 5, 6, 7, 8];
fprintf('\nTake-off velocities at different angles:\n');
for i = 1:length(AoA_to_set)
    CL_i  = interp1(alpha_deg, CL, AoA_to_set(i), 'pchip');
    Vto_i = sqrt((2*W) / (rho * S * CL_i));
    fprintf('  α = %d°  →  V_takeoff = %.2f m/s  (%.1f knots)\n', ...
            AoA_to_set(i), Vto_i, Vto_i*1.94384);
end

CL_cruise  = interp1(alpha_deg, CL, alpha_cruise, 'pchip');
LD_cruise  = interp1(alpha_deg, LD, alpha_cruise, 'pchip');
CD_cruise  = interp1(alpha_deg, CD, alpha_cruise, 'pchip');
CL_cruise_pt = CL_cruise;
CL_6      = interp1(alpha_deg, CL, 6, 'pchip');
V_takeoff = sqrt((2*W) / (rho * S * CL_6));

fprintf('\nKey aerodynamic points:\n');
fprintf('Design cruise AoA        : %.1f°\n',  alpha_cruise);
fprintf('Best L/D angle           : %.1f°  (L/D = %.1f)\n', alpha_bestLD, LD_max);
fprintf('Take-off speed (α = 6°)  : %.2f m/s  (%.1f knots)\n', V_takeoff, V_takeoff*1.94384);
fprintf('Cruise speed             : %.1f m/s  (%.1f knots)\n', V_cruise, V_cruise*1.94384);
fprintf('Max C_L                  : %.3f  at α = %.1f°\n', CL_max_actual, alpha_deg(stall_idx));
fprintf('Min C_D                  : %.4f\n', min(CD));
fprintf('\n')

% FIGURE 1 - LIFT AND DRAG COEFFICIENTS VS ANGLE OF ATTACK
fig1 = figure('Position', [60 60 980 600], 'Color', 'w');
ax1 = axes('Position', [0.10 0.13 0.76 0.76]);
hold(ax1, 'on');

% Shade operational zone (4-8 degrees)
patch(ax1, [4 8 8 4], [-2 -2 2 2], C.lblue, 'FaceAlpha', 0.18, 'EdgeColor', 'none');

% Plot CL curve
plot(ax1, alpha_deg, CL, '-', 'Color', C.blue, 'LineWidth', 2.6);
plot(ax1, alpha_deg(stall_idx), CL_max_actual, 'o', 'MarkerSize', 9, ...
     'MarkerFaceColor', C.blue, 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
plot(ax1, alpha_bestLD, interp1(alpha_deg, CL, alpha_bestLD, 'pchip'), ...
     's', 'MarkerSize', 9, 'MarkerFaceColor', C.orange, 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
plot(ax1, alpha_cruise, CL_cruise, 'd', 'MarkerSize', 9, ...
     'MarkerFaceColor', C.green, 'MarkerEdgeColor', 'k', 'LineWidth', 1.2);

% Reference lines
xline(ax1, 0, '--', 'Color', C.grey, 'LineWidth', 0.9);
yline(ax1, 0, '--', 'Color', C.grey, 'LineWidth', 0.9);
xline(ax1, stall_ang, ':', 'Color', C.red, 'LineWidth', 1.3);
xline(ax1, -stall_ang, ':', 'Color', C.red, 'LineWidth', 1.3);

% Set axis properties
ax1.XLim = [min(alpha_deg) max(alpha_deg)];
ax1.YLim = [-1.7 1.8];
ax1.YColor = C.blue;
ax1.XLabel.String = 'Angle of Attack, \alpha [degrees]';
ax1.YLabel.String = 'Lift Coefficient, C_L';
ax1.XGrid = 'on';
ax1.YGrid = 'on';
ax1.GridAlpha = 0.25;

title(ax1, 'Boeing 929 Jetfoil: C_L and C_D vs Angle of Attack', 'FontSize', 14, 'FontWeight', 'bold');

% Add text annotations
text(ax1, alpha_deg(stall_idx) + 0.4, CL_max_actual + 0.06, ...
     sprintf('Stall (C_L_max = %.2f)', CL_max_actual), 'FontSize', 10, 'Color', C.blue);
text(ax1, alpha_bestLD + 0.4, interp1(alpha_deg, CL, alpha_bestLD, 'pchip') - 0.13, ...
     sprintf('Best L/D (\u03b1 = %.0f°)', alpha_bestLD), 'FontSize', 10, 'Color', C.orange);
text(ax1, alpha_cruise + 0.3, CL_cruise + 0.08, ...
     sprintf('Cruise (\u03b1 = %.0f°)', alpha_cruise), 'FontSize', 10, 'Color', C.green);
text(ax1, 4.1, -1.55, 'Operational zone (4°-8°)', 'FontSize', 9.5, 'Color', [0.15 0.35 0.65]);

% CD curve on right y-axis
ax2 = axes('Position', ax1.Position, 'Color', 'none', 'YAxisLocation', 'right', 'XAxisLocation', 'top');
ax2.XLim = ax1.XLim;
ax2.YLim = [0 0.42];
ax2.YColor = C.red;
ax2.XTick = [];
ax2.XGrid = 'off';
ax2.YGrid = 'off';
hold(ax2, 'on');

plot(ax2, alpha_deg, CD, '-', 'Color', C.red, 'LineWidth', 2.3);
ax2.YLabel.String = 'Drag Coefficient, C_D';

text(ax2, 13.5, 0.30, '\u2191 Post-stall drag rise', 'FontSize', 10, 'Color', C.red);
text(ax2, -3.5, 0.31, 'C_D_min = 0.006', 'FontSize', 9.5, 'Color', C.red);

% Shared legend
hCL_ln = plot(ax1, NaN, NaN, '-', 'Color', C.blue, 'LineWidth', 2.4);
hCD_ln = plot(ax1, NaN, NaN, '-', 'Color', C.red, 'LineWidth', 2.4);
hOp = plot(ax1, NaN, NaN, 'd', 'MarkerFaceColor', C.green, 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
hBL = plot(ax1, NaN, NaN, 's', 'MarkerFaceColor', C.orange, 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
hSt = plot(ax1, NaN, NaN, 'o', 'MarkerFaceColor', C.blue, 'MarkerEdgeColor', 'k', 'MarkerSize', 8);

legend(ax1, [hCL_ln, hCD_ln, hOp, hBL, hSt], ...
       {'C_L', 'C_D', 'Cruise point', 'Best L/D', 'Stall point'}, ...
       'Location', 'northwest', 'FontSize', 11, 'Box', 'on');

% FIGURE 2 - LIFT-TO-DRAG RATIO VS ANGLE OF ATTACK
fig2 = figure('Position', [100 100 900 560], 'Color', 'w');
hold on;

% Shade operational zone
patch([4 8 8 4], [-5 -5 50 50], C.lblue, 'FaceAlpha', 0.18, 'EdgeColor', 'none');

% Shade area under L/D curve (positive angles)
x_shade = alpha_deg(pos_only);
y_shade = LD(pos_only);
y_shade(y_shade < 0) = 0;
fill([x_shade, fliplr(x_shade)], [y_shade, zeros(1, sum(pos_only))], ...
     C.green, 'FaceAlpha', 0.12, 'EdgeColor', 'none');

% Plot L/D (dim for negative angles, bright for positive)
plot(alpha_deg(~pos_only), LD(~pos_only), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
plot(alpha_deg(pos_only), LD(pos_only), '-', 'Color', C.green, 'LineWidth', 2.6);

% Mark optimal and cruise points
plot(alpha_bestLD, LD_max, 'o', 'MarkerSize', 10, ...
     'MarkerFaceColor', C.orange, 'MarkerEdgeColor', 'k', 'LineWidth', 1.3);
LD_cruise = interp1(alpha_deg, LD, alpha_cruise, 'pchip');
plot(alpha_cruise, LD_cruise, 'd', 'MarkerSize', 10, ...
     'MarkerFaceColor', C.green, 'MarkerEdgeColor', 'k', 'LineWidth', 1.3);

% Reference lines and labels
xline(stall_ang, ':', 'Color', C.red, 'LineWidth', 1.4, 'Label', 'Stall onset (11°)', ...
      'LabelVerticalAlignment', 'middle', 'FontSize', 10);
yline(0, '--', 'Color', C.grey, 'LineWidth', 0.9);
xline(0, '--', 'Color', C.grey, 'LineWidth', 0.9);

text(alpha_bestLD + 0.3, LD_max + 0.6, sprintf('(L/D)_max = %.1f\n\u03b1_opt = %.0f°', LD_max, alpha_bestLD), ...
     'FontSize', 11, 'Color', C.orange, 'BackgroundColor', 'w', 'EdgeColor', [0.8 0.8 0.8]);
text(alpha_cruise + 0.3, LD_cruise - 1.5, sprintf('Cruise point\n\u03b1 = %.0f°, L/D = %.1f', alpha_cruise, LD_cruise), ...
     'FontSize', 10, 'Color', C.green);
text(4.2, 2.5, 'Operational zone\n(4°-8°)', 'FontSize', 9.5, 'Color', [0.15 0.35 0.65]);

xlabel('Angle of Attack, \alpha [degrees]', 'FontSize', 13);
ylabel('Lift-to-Drag Ratio, L/D', 'FontSize', 13);
title('Boeing 929 Jetfoil: Aerodynamic Efficiency (L/D)', 'FontSize', 14, 'FontWeight', 'bold');
xlim([min(alpha_deg) max(alpha_deg)]);
ylim([-8 LD_max*1.12]);
grid on;
ax = gca;
ax.GridAlpha = 0.25;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
ax.MinorGridAlpha = 0.10;

legend({'Negative AoA (non-op)', 'L/D curve (operational)', 'Best L/D', 'Cruise point'}, ...
       'Location', 'northeast', 'FontSize', 11);

% FIGURE 3 - LIFT FORCE VS VELOCITY AT MULTIPLE ANGLES OF ATTACK
fig3 = figure('Position', [140 80 960 580], 'Color', 'w');
hold on;

V_range = 6:0.2:30;           % 6-30 m/s
AoA_plot = [4, 5, 6, 7, 8];
clrs = {C.purple, C.blue, C.green, C.orange, C.red};
lstys = {'-', '--', '-.', ':', '-'};
lws = [1.8, 1.8, 2.5, 1.8, 1.8];

for i = 1:length(AoA_plot)
    CL_i = interp1(alpha_deg, CL, AoA_plot(i), 'pchip');
    Lift_V = 0.5 * rho * V_range.^2 * S * CL_i;
    plot(V_range, Lift_V/1e3, lstys{i}, 'Color', clrs{i}, 'LineWidth', lws(i), ...
         'DisplayName', sprintf('\u03b1 = %d° (C_L = %.3f)', AoA_plot(i), CL_i));
end

% Vessel weight reference line
yline(W/1e3, '-k', 'LineWidth', 2.0, ...
      'Label', sprintf('Vessel Weight = %.0f kN (%.0f t)', W/1e3, W/9810), ...
      'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom', 'FontSize', 11);

% Mark take-off points for each angle
for i = 1:length(AoA_plot)
    CL_i = interp1(alpha_deg, CL, AoA_plot(i), 'pchip');
    Vto_i = sqrt((2*W)/(rho*S*CL_i));
    if Vto_i <= max(V_range)
        plot(Vto_i, W/1e3, 'v', 'MarkerSize', 9, ...
             'MarkerFaceColor', clrs{i}, 'MarkerEdgeColor', 'k', 'LineWidth', 1.1, 'HandleVisibility', 'off');
        text(Vto_i + 0.2, W/1e3 - 50, sprintf('%.1f m/s\n(%.0f kn)', Vto_i, Vto_i*1.94384), ...
             'FontSize', 8.5, 'Color', clrs{i}, 'HorizontalAlignment', 'left');
    end
end

% Cruise speed line
xline(V_cruise, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.3, ...
      'Label', sprintf('Cruise %.0f m/s (%.0f kn)', V_cruise, V_cruise*1.94384), ...
      'LabelVerticalAlignment', 'bottom', 'FontSize', 10);

xlabel('Velocity, V [m/s]  (\u00d7 1.944 \u2192 knots)', 'FontSize', 13);
ylabel('Lift Force, L [kN]', 'FontSize', 13);
title('Boeing 929 Jetfoil: Lift Force vs Velocity', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11, 'Box', 'on');
xlim([6 30]);
ylim([0 max(0.5*rho*max(V_range)^2*S*max(CL))/1e3 * 1.08]);
grid on;
ax = gca;
ax.GridAlpha = 0.25;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
ax.MinorGridAlpha = 0.10;

text(6.3, W/1e3 + 40, '\u2207  Take-off point', 'FontSize', 10, 'Color', [0.3 0.3 0.3]);

% FIGURE 4 - AERODYNAMIC DRAG POLAR (CL VS CD)
fig4 = figure('Position', [180 100 700 640], 'Color', 'w');
hold on;

% Plot polar curve colored by angle of attack
npts = numel(CL);
cmap_pts = interp1([0;0.5;1], [C.blue; C.green; C.red], linspace(0, 1, npts));
for i = 1:npts-1
    plot(CD(i:i+1), CL(i:i+1), '-', 'Color', cmap_pts(i, :), 'LineWidth', 2.0);
end

% Best L/D tangent line from origin
slope_bestLD = LD_max;
CD_range_tan = linspace(0, CD(best_idx)*1.6, 50);
plot(CD_range_tan, slope_bestLD * CD_range_tan, '--', 'Color', C.orange, ...
     'LineWidth', 1.6, 'DisplayName', 'Best L/D tangent');

% Mark key points on polar
CD_bLD = CD(best_idx);
CL_bLD = CL(best_idx);
plot(CD_bLD, CL_bLD, 's', 'MarkerSize', 11, 'MarkerFaceColor', C.orange, ...
     'MarkerEdgeColor', 'k', 'LineWidth', 1.2);
text(CD_bLD + 0.003, CL_bLD + 0.04, sprintf('Best L/D = %.1f\n\u03b1 = %.0f°', LD_max, alpha_bestLD), ...
     'FontSize', 10.5, 'Color', C.orange, 'BackgroundColor', 'w', 'EdgeColor', [0.85 0.85 0.85]);

plot(CD(stall_idx), CL(stall_idx), 'o', 'MarkerSize', 10, 'MarkerFaceColor', C.red, ...
     'MarkerEdgeColor', 'k', 'LineWidth', 1.1);
text(CD(stall_idx) + 0.003, CL(stall_idx) + 0.04, sprintf('Stall (C_L_max = %.2f)', CL_max_actual), ...
     'FontSize', 10, 'Color', C.red);

plot(CD_cruise, CL_cruise_pt, 'd', 'MarkerSize', 10, 'MarkerFaceColor', C.green, ...
     'MarkerEdgeColor', 'k', 'LineWidth', 1.1);
text(CD_cruise + 0.003, CL_cruise_pt - 0.08, sprintf('Cruise\n\u03b1 = %.0f°', alpha_cruise), ...
     'FontSize', 10, 'Color', C.green);

yline(0, '--', 'Color', C.grey, 'LineWidth', 0.9);

% Color bar showing angle of attack
colormap(gca, interp1([0;0.5;1], [C.blue;C.green;C.red], linspace(0, 1, 256)));
cb = colorbar;
caxis([min(alpha_deg) max(alpha_deg)]);
cb.Label.String = 'Angle of Attack \u03b1 [degrees]';
cb.FontSize = 11;

xlabel('Drag Coefficient, C_D', 'FontSize', 13);
ylabel('Lift Coefficient, C_L', 'FontSize', 13);
title('Boeing 929 Jetfoil: Drag Polar (C_L vs C_D)', 'FontSize', 14, 'FontWeight', 'bold');
xlim([0 max(CD)*1.05]);
ylim([min(CL)*1.05 CL_max_actual*1.10]);
grid on;
ax = gca;
ax.GridAlpha = 0.25;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';

% FIGURE 5 - PERFORMANCE SUMMARY DASHBOARD (2x2 LAYOUT)
fig5 = figure('Position', [80 40 1220 850], 'Color', 'w');
sgtitle({'Boeing 929 Jetfoil: NACA 0012 Performance Summary', ...
         sprintf('Re = %.2e | W = %.0f kN | S = %.0f m^2 | V_cruise = %.0f m/s (%.0f kn)', ...
         Re, W/1e3, S, V_cruise, V_cruise*1.94384)}, ...
        'FontSize', 14, 'FontWeight','bold');

% SUBPLOT A - CL vs ANGLE OF ATTACK
sp1 = subplot(2,2,1);
patch([4 8 8 4], [-2 -2 2 2], C.lblue, 'FaceAlpha',0.2,'EdgeColor','none'); hold on;
plot(alpha_deg, CL, '-', 'Color', C.blue, 'LineWidth', 2.2);
plot(alpha_deg(stall_idx),  CL_max_actual, 'o', 'MarkerSize',8, ...
     'MarkerFaceColor',C.blue,   'MarkerEdgeColor','k');
plot(alpha_bestLD, interp1(alpha_deg,CL,alpha_bestLD,'pchip'), 's','MarkerSize',8,...
     'MarkerFaceColor',C.orange, 'MarkerEdgeColor','k');
plot(alpha_cruise, CL_cruise, 'd', 'MarkerSize',8, ...
     'MarkerFaceColor',C.green,  'MarkerEdgeColor','k');
xline(0,'--','Color',C.grey,'LineWidth',0.8);
yline(0,'--','Color',C.grey,'LineWidth',0.8);
xline(stall_ang,':','Color',C.red,'LineWidth',1.1);
xlabel('\alpha  [°]'); ylabel('C_L');
title('(A)  Lift Coefficient, C_L');
xlim([min(alpha_deg) max(alpha_deg)]); ylim([-1.7 1.8]);
grid on; sp1.GridAlpha = 0.25;
legend({'Op. zone','C_L','Stall','Best L/D','Cruise'}, ...
       'FontSize',8,'Location','northwest');

% SUBPLOT B - CD vs ANGLE OF ATTACK
sp2 = subplot(2,2,2);
patch([4 8 8 4], [0 0 0.5 0.5], C.lblue, 'FaceAlpha',0.2,'EdgeColor','none'); hold on;
plot(alpha_deg, CD, '-', 'Color', C.red, 'LineWidth', 2.2);
yline(CD0,'--','Color',C.grey,'LineWidth',0.9, ...
      'Label',sprintf('C_{D0} = %.4f',CD0),'LabelVerticalAlignment','top',...
      'FontName','Times New Roman','FontSize',9);
xline(stall_ang,':','Color',C.red,'LineWidth',1.1);
xlabel('\alpha  [°]'); ylabel('C_D');
title('(B)  Drag Coefficient, C_D');
xlim([min(alpha_deg) max(alpha_deg)]); ylim([0 0.42]);
grid on; sp2.GridAlpha = 0.25;

% SUBPLOT C - L/D vs ANGLE OF ATTACK
sp3 = subplot(2,2,3);
mask_plot = alpha_deg >= 0;
patch([4 8 8 4],[-5 -5 60 60],C.lblue,'FaceAlpha',0.2,'EdgeColor','none'); hold on;
plot(alpha_deg(~mask_plot), LD(~mask_plot), '-','Color',[0.75 0.75 0.75],'LineWidth',1.4);
plot(alpha_deg(mask_plot),  LD(mask_plot),  '-','Color',C.green,'LineWidth',2.2);
plot(alpha_bestLD, LD_max, 'o', 'MarkerSize',8, ...
     'MarkerFaceColor',C.orange,'MarkerEdgeColor','k');
plot(alpha_cruise, LD_cruise, 'd', 'MarkerSize',8, ...
     'MarkerFaceColor',C.green,'MarkerEdgeColor','k');
xline(stall_ang,':','Color',C.red,'LineWidth',1.1);
yline(0,'--','Color',C.grey,'LineWidth',0.8);
xlabel('\alpha  [°]'); ylabel('L/D');
title('(C)  Aerodynamic Efficiency, L/D');
xlim([min(alpha_deg) max(alpha_deg)]); ylim([-8 LD_max*1.15]);
grid on; sp3.GridAlpha = 0.25;

% SUBPLOT D - DRAG POLAR
sp4 = subplot(2,2,4);
hold on;
for i = 1:npts-1
    plot(CD(i:i+1), CL(i:i+1), '-', 'Color', cmap_pts(i,:), 'LineWidth', 1.8);
end
CD_tan = linspace(0, CD(best_idx)*1.6, 30);
plot(CD_tan, slope_bestLD*CD_tan, '--','Color',C.orange,'LineWidth',1.5);
plot(CD(best_idx),  CL(best_idx),  's','MarkerSize',9, ...
     'MarkerFaceColor',C.orange,'MarkerEdgeColor','k');
plot(CD(stall_idx), CL(stall_idx), 'o','MarkerSize',9, ...
     'MarkerFaceColor',C.red,   'MarkerEdgeColor','k');
plot(CD_cruise, CL_cruise_pt, 'd','MarkerSize',9, ...
     'MarkerFaceColor',C.green, 'MarkerEdgeColor','k');
yline(0,'--','Color',C.grey,'LineWidth',0.8);
xlabel('C_D'); ylabel('C_L');
title('(D)  Drag Polar (C_L vs C_D)');
xlim([0 max(CD)*1.05]); ylim([min(CL)*1.05 CL_max_actual*1.10]);
grid on; sp4.GridAlpha = 0.25;

% FINAL SUMMARY - PRINT KEY RESULTS TO CONSOLE
fprintf('\n---- FINAL RESULTS ----\n');
fprintf('Drag coefficient (zero lift)   %.4f\n', min(CD));
fprintf('Lift coefficient (max)         %.3f at %.0f degrees\n', CL_max_actual, alpha_deg(stall_idx));
fprintf('L/D ratio (best)               %.1f at %.0f degrees\n', LD_max, alpha_bestLD);
fprintf('\n');

% SAVE FIGURES
export_folder = fullfile(pwd, 'Hydrofoil_Figures');
if ~exist(export_folder, 'dir')
    mkdir(export_folder);
end

fprintf('Exporting figures to: %s\n', export_folder);

% Define figure metadata
figures = struct('handle', {fig1, fig2, fig3, fig4, fig5}, ...
                 'name', {'1_CL_CD', '2_Efficiency', '3_Lift_vs_Velocity', '4_Polar', '5_Dashboard'});

for i = 1:length(figures)
    figure(figures(i).handle);
    drawnow;
    pathname = fullfile(export_folder, [figures(i).name '.png']);
    exportgraphics(figures(i).handle, pathname, 'Resolution', 300, 'BackgroundColor', 'white');
    fprintf('[%d/%d] Saved: %s\n', i, length(figures), figures(i).name);
end
fprintf('\nAll figures saved successfully.\n');
