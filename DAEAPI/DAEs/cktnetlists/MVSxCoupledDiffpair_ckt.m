function cktnetlist = MVSxCoupledDiffpair_ckt()
%function cktnetlist = MVSxCoupledDiffpair_ckt()
%This function returns a cktnetlist structure for a cross-coupled
% differential pair circuit made of MVS 1.0.1 MOS devices. 
%
%The circuit
%   A cross-coupled ideal-ish differential pair using MVS MOS devices. The 
%   source nodes of 2 N-type MOSFETs are connected at node nS (node voltage
%   e_nS). 
%   An ideal current source of DC value IS drains node S. The drain of the
%   MOSFET on the left is connected to node nDL (node voltage e_nDL); that of
%   the one on the right to node nDR (node voltage e_nDR). Resistors rL and rR
%   connect from VDD to nodes nDL and nDR, respectively; similarly with
%   capacitors CL and CR. The gate of the transistor on the right is connected
%   to the drain of the transistor on the left, and vice-versa -- this is
%   cross coupling. There is a voltage source Vin between the two drain (or
%   gate) nodes. The current through this voltage source should exhibit
%   a negative resistance region as the voltage is swept.
%
%Examples
%--------
%
% DAE =  MNA_EqnEngine(MVSxCoupledDiffpair_ckt());
% DAE = feval(DAE.set_uQSS, 'Vin:::E', -3, DAE);
%
% % This ckt has DC convergence problems at Vin=-3 (which could be due to
% % a bug in init/limiting). The following initguess was found by doing
% % a dcsweep from 0 to -3.
%
% initguess = [ ...
%    1.236691454980733e+00; ...
%    1.500000000000000e+00; ...
%    4.500000000000000e+00; ...
%    5.000000000000000e+00; ...
%   -2.000000000000000e-03; ...
%    1.416576597595399e-01; ...
%    1.216508852597263e-01; ...
%    3.184959430278994e+00; ...
%    7.834911474027248e-02; ...
%    5.334911474027317e-04 ...
%   ]
%
% % Possible init/limiting bug in NR:
% %{
% dco = op(DAE); % does not work
% dco = op(DAE, initguess); % does not work
% dco = op(DAE, initguess, 'init', 0); % does not work
% dco = op(DAE, initguess, 'limiting', 0); % does not work
% dco = op(DAE, initguess, 'init', 0, 'limiting', 0); % works. WHY?
% %}
%
% inpORparm = 1; init = 0; limiting = 0; 
% swp = dcsweep(DAE, initguess, 'Vin:::E', -3:0.12:3, inpORparm, init, limiting);
% feval(swp.plot, swp);
%
%See also
%--------
% 
% add_element, supported_ModSpec_devices[TODO], DAEAPI, DAE_concepts,
%
% Author: Jaijeet Roychowdhury, 2015/06/15 (copied MVSdiffpair_ckt and modified)
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Type "help MAPPlicense" at the MATLAB/Octave prompt to see the license      %
%% for this software.                                                          %
%% Copyright (C) 2008-2020 Jaijeet Roychowdhury <jr@berkeley.edu>. All rights  %
%% reserved.                                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % MOS model
	MVS_Model = MVS_1_0_1_ModSpec_vv4; % swp = dcsweep(DAE, [], 'Vin:::E',
                                       % -3:0.12:3) takes 4.022s
	%MVS_Model = MVS_1_0_1_ModSpec; % swp = dcsweep(DAE, [], 'Vin:::E',
                                     % -3:0.12:3) takes 23.46s
	% MVS_Model = MVS_1_0_1_ModSpec_wrapper; % swp = dcsweep(DAE, [], 
                                             % 'Vin:::E', -3:0.12:3) takes 17.5s
	% ckt name

    % ckt name
    cktnetlist.cktname = 'MOS (MVS) cross coupled diffpair';
    % nodes (names)
    cktnetlist.nodenames = {'nS', 'nDL', 'nDR', 'nDD'}; % non-ground 
                                % nodes
    cktnetlist.groundnodename = 'gnd';

    % circuit element values
    VDD = 5.0; % 5V
    VinDC = 0; % DC input value of Vin
    vinoft = @(t, args) args.A*sin(2*pi*args.f*t + args.phi); % transient 
                                                   % input function for Vin
    vinargs.A = 1; vinargs.f = 1e3; vinargs.phi = 0; % arguments for
                             % transient function
    IS = 2e-3; % 2mA
    rL = 2000; % 2kOhms
    rR = 2000; % 2kOhms
    CL = 1e-7; % 0.1uF
    CR = 1e-7; % 0.1uF

    cktnetlist = add_element(cktnetlist, vsrcModSpec(), 'VDD', {'nDD', 'gnd'}, {},         {{'E' {'DC', VDD}}});
    %                             ^         ^            ^          ^          ^                  ^
    %                          cktnetlist, ModSpec model, name       nodes  , parameters,    DC/transient/AC values of internal sources
    %                                                     []=defaults,     optional args

    cktnetlist = add_element(cktnetlist, resModSpec(), 'rL', {'nDD', 'nDL'}, ...
                      {{'R', rL}}, {});
    cktnetlist = add_element(cktnetlist, resModSpec(), 'rR', {'nDD', 'nDR'}, ...
                  rR, {});
    cktnetlist = add_element(cktnetlist, capModSpec(), 'CL', {'nDD', 'nDL'}, ...
                      {{'C', CL}});
    cktnetlist = add_element(cktnetlist, capModSpec(), 'CR', {'nDD', 'nDR'}, CR);
    cktnetlist = add_element(cktnetlist, MVS_Model, 'ML', ...
                  {'nDL', 'nDR', 'nS', 'nS'}, ...
                  {{'Type', 1}, {'W', 1e-4}, {'Lgdr', 32e-7}, {'dLg', 9e-7}, ...
                   {'Cg', 2.57e-6}, {'Beta', 1.8}, {'Alpha', 3.5}, {'etov', 1.3e-3}, ...
                   {'Cif', 0}, {'Cof', 0}, {'phib', 1.2}, {'Gamma', 0}, {'mc', 0.2}, ...
                   {'CTM_select', 1}, {'Rs0', 100}, {'Rd0', 100}, {'n0', 1.68}, ...
                   {'nd', 0.1}, {'vxo', 1.2e7}, {'Mu', 200}, {'Vt0', 0.4}, {'delta', 0.15}...
                  });
    cktnetlist = add_element(cktnetlist, MVS_Model(), 'MR', ...
                  {'nDR', 'nDL', 'nS', 'nS'}, ...
                  {{'Type', 1}, {'W', 1e-4}, {'Lgdr', 32e-7}, {'dLg', 9e-7}, ...
                   {'Cg', 2.57e-6}, {'Beta', 1.8}, {'Alpha', 3.5}, {'etov', 1.3e-3}, ...
                   {'Cif', 0}, {'Cof', 0}, {'phib', 1.2}, {'Gamma', 0}, {'mc', 0.2}, ...
                   {'CTM_select', 1}, {'Rs0', 100}, {'Rd0', 100}, {'n0', 1.68}, ...
                   {'nd', 0.1}, {'vxo', 1.2e7}, {'Mu', 200}, {'Vt0', 0.4}, {'delta', 0.15}...
                  });
    cktnetlist = add_element(cktnetlist, vsrcModSpec(), 'Vin', {'nDL', 'nDR'}, {},         {{'E', {'DC', VinDC}, {'AC' 1}, {'tr', vinoft, vinargs}}});
    %                              ^          ^           ^           ^        ^                    ^      ^        ^
    %                           cktnetlist, ModSpec model, name       nodes  , parameters,    DC/transient values of internal sources
    %                                                         []=defaults,     optional args
    cktnetlist = add_element(cktnetlist, isrcModSpec(), 'IS', {'nS', 'gnd'}, {},         {{'I', {'DC', IS}}});
    %                        ^          ^           ^           ^       ^                  ^      ^        ^
    %                     cktnetlist, ModSpec model, name       nodes  , parameters,    DC/transient values of internal sources
    %                                                 []=defaults,     optional args
    cktnetlist = add_output(cktnetlist, 'i(Vin)', -1000);
end
