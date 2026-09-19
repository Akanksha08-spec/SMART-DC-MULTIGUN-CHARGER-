function out = scenario_config(what)
%SCENARIO_CONFIG  SINGLE SOURCE OF TRUTH for the scenario-override schema.
%   Both build_dc_fast_charger.m (which consumes an override struct) and
%   run_validation.m (which produces them) call this function, so the two can
%   never drift apart.
%
%   d = scenario_config('defaults')  -> the default override struct (Scenario 2)
%   S = scenario_config('all')       -> 1x10 struct array: .id .name .ov
%
%   OVERRIDE SCHEMA (every field is optional in a caller's struct; anything
%   missing is filled from 'defaults' by build_dc_fast_charger):
%     soc0   3x1  initial SOC per EV [0..1]        (build-time initial condition)
%     temp0  3x1  initial pack temperature [degC]  (build-time initial condition)
%     tdep   3x1  departure deadline [s]
%     conn0  3x1  initial connected flags (0/1)
%     lateEV scalar EV id that arrives late (0 = none), lateT  [s] arrival time
%     discEV scalar EV id that departs      (0 = none), discT  [s] departure time
%     v2g    3x1  per-EV export request [kW] (0 = none, >0 = discharge to grid)
%     gc0    scalar nominal grid cap [kW]
%     gclo   scalar reduced grid cap [kW] applied during [gt0,gt1)
%     gt0,gt1 scalar grid-cap window [s]
%     tamb   scalar ambient temperature [degC]
%     fault  char  MATLAB literal for the module fault schedule, rows
%                  [moduleID tStart tEnd type], type 1=Fault 2=Maint 3=Offline.
%                  MUST stay dimensionally 0x4 when empty -> 'zeros(0,4)'
%                  (a bare '[]' is 0x0 and breaks MATLAB Function codegen).
%     scenario scalar id (labelling only)
%     mode   scalar controller mode; 5 = HYBRID (the real charger)

P = init_params;

d.soc0   = P.ev.SOC0(:);
d.temp0  = P.ev.Temp0(:);
d.tdep   = [3400; 3000; 3400];
d.conn0  = [1;1;1];
d.lateEV = 0;   d.lateT = 0;
d.discEV = 0;   d.discT = 1e9;
d.v2g    = [0;0;0];
d.gc0    = 180; d.gclo = 180; d.gt0 = 1e9; d.gt1 = 1e9;
d.tamb   = 25;
d.fault  = 'zeros(0,4)';      % 0x4, NOT '[]' - keeps codegen dimensions valid
d.scenario = 2;
d.mode   = 5;                 % one combined hybrid controller

switch lower(what)
    case 'defaults'
        out = d;

    case 'all'
        S(1)  = item( 1,'Single EV',            set(d,'conn0',[1;0;0],'scenario',1));
        S(2)  = item( 2,'Three-EV Sharing',     set(d,'scenario',2));
        S(3)  = item( 3,'Different SOC',        set(d,'soc0',[0.15;0.50;0.80],'scenario',3));
        S(4)  = item( 4,'Different Temperature',set(d,'temp0',[55;48;35],'scenario',4));
        S(5)  = item( 5,'Different Deadlines',  set(d,'tdep',[1200;2400;3600],'scenario',5));
        S(6)  = item( 6,'EV Departure',         set(d,'discEV',2,'discT',1500,'scenario',6));
        S(7)  = item( 7,'Module Fault (M3)',    set(d,'fault','[3 1200 1e9 1]','scenario',7));
        S(8)  = item( 8,'V2G Export',           set(d,'conn0',[0;1;0],'soc0',[0.15;0.80;0.55], ...
                                                      'v2g',[0;50;0],'scenario',8));
        S(9)  = item( 9,'Mixed G2V+V2G',        set(d,'soc0',[0.15;0.30;0.80], ...
                                                      'v2g',[0;0;40],'scenario',9));
        S(10) = item(10,'Thermal Protection',   set(d,'temp0',[60;48;35],'tamb',45,'scenario',10));
        out = S;

    otherwise
        error('scenario_config:what','Use ''defaults'' or ''all''.');
end
end

% ---------------------------------------------------------------------
function s = item(id,name,ov)
s.id = id; s.name = name; s.ov = ov;
end

function d = set(d,varargin)
for k = 1:2:numel(varargin), d.(varargin{k}) = varargin{k+1}; end
end
