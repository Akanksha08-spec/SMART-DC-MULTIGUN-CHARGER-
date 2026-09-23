function P = init_params()
%INIT_PARAMS  Canonical parameters for the Smart Multi-Gun DC Fast Charger.
%   Single source of truth for station, EV/BMS, thermal, module-switching and
%   simulation parameters. Values match the project specification exactly and
%   are used by build_dc_fast_charger.m, priority_allocator.m,
%   constraints_eval.m and run_validation.m.
%
%   Usage:
%       P = init_params;              % returns struct
%       init_params;                  % also assigns P in the base workspace

%% ---- Station (FIXED 180 kW - do NOT increase) --------------------------
P.stn.Ptotal_kW   = 180;   % total installed station capacity
P.stn.Nmod        = 6;     % number of 30 kW power modules
P.stn.Pmod_kW     = 30;    % rating of each module
P.stn.Nev         = 3;     % guns / EVs
P.stn.PgunMax_kW  = 120;   % per-gun connector ceiling
P.stn.NmodGunMax  = 4;     % max modules per EV
P.stn.Vbus_nom    = 800;   % DC bus nominal voltage

%% ---- Timing ------------------------------------------------------------
P.ts.fast = 0.1;           % plant/battery step  [s]
P.ts.sup  = 1.0;           % supervisor step     [s]
P.tstop   = 3600;          % simulation duration [s]
P.socStop = 0.97;          % target SOC
P.socMin  = 0.10;          % minimum SOC (V2G floor)

%% ---- EV / BMS parameters  [EV1 EV2 EV3] --------------------------------
% order per vehicle: [Cap_kWh; Vnom; Vpackmax; Imax_A; Pmax_kW; Rint_ohm; Temp_C]
P.ev.Cap_kWh = [60    80    50];
P.ev.Vnom    = [500   560   480];
P.ev.Vmax    = [650   700   640];
P.ev.Imax_A  = [200   150   180];
P.ev.Pmax_kW = [80    120   60];
P.ev.Rint    = [0.06  0.08  0.07];
P.ev.SOC0    = [0.15  0.30  0.55];
P.ev.Temp0   = [30    38    35];

% BMS Constant-block strings used by the builder (col vectors, 7 rows each)
P.bms1 = bms_str(P,1);
P.bms2 = bms_str(P,2);
P.bms3 = bms_str(P,3);
P.soc0 = P.ev.SOC0(:);

%% ---- Priority weights (fixed) -----------------------------------------
P.w.SOC    = 0.35;         % wSOC   : low-SOC need
P.w.Demand = 0.25;         % wDemand: normalized requested power
P.w.Urg    = 0.25;         % wUrg   : urgency to departure deadline
P.w.Fair   = 0.15;         % wFair  : fairness

%% ---- Simplified per-pack thermal model  Cth*dT/dt = I^2 Rint - (T-Tamb)/Rth
P.th.Cth   = 6.0e4;        % J/degC
P.th.Rth   = 0.010;        % degC/W
P.th.Tamb  = 25;           % degC ambient (scenario may override)
% thermal regions
P.th.WARM  = 40;           % >=40 warm  (moderate derate)
P.th.HOT   = 50;           % >=50 hot   (strong derate)
P.th.PROT  = 55;           % >=55 protection (Palloc = 0, modules released)

%% ---- Module safe-switching timing -------------------------------------
P.sw.tRampDown = 1.0;
P.sw.tOpenDelay= 0.2;
P.sw.tDeadTime = 0.5;
P.sw.tConnect  = 0.2;
P.sw.tRampUp   = 1.0;

%% ---- Defaults for scenario 2 (primary demonstration) ------------------
P.mode          = 5;                 % HYBRID (priority + EFT), single controller
P.scenario      = 2;
% no fault by default. MUST be 0x4 (not '[]', which is 0x0 and breaks the
% Module_Pool MATLAB Function block's codegen dimension checking).
P.faultSchedule = 'zeros(0,4)';      % rows [moduleID tStart tEnd type]

if nargout == 0, assignin('base','P',P); end
end

% ---------------------------------------------------------------------
function s = bms_str(P,g)
s = sprintf('[%g; %g; %g; %g; %g; %g; %g]', ...
    P.ev.Cap_kWh(g), P.ev.Vnom(g), P.ev.Vmax(g), P.ev.Imax_A(g), ...
    P.ev.Pmax_kW(g), P.ev.Rint(g), P.ev.Temp0(g));
end
