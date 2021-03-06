function [pE,pC] = spm_erp_priors(A,B,C)
% prior moments for a neural-mass model of ERPs
% FORMAT [pE,pC] = spm_erp_priors(A,B,C)
%
% A{3},B{m},C  - binary constraints on extrinsic connections
%
% pE - prior expectation - f(x,u,P,M)
%
% synaptic parameters
%--------------------------------------------------------------------------
%    pE.T - syaptic time constants
%    pE.H - syaptic densities
%    pE.S - activation function parameters
%
% connectivity parameters
%--------------------------------------------------------------------------
%    pE.A - extrinsic
%    pE.B - trial-dependent
%    pE.C - stimulus input
%    pE.D - delays
%
% stimulus and noise parameters
%--------------------------------------------------------------------------
%    pE.R - onset and dispersion
%
% pC - prior covariances: cov(spm_vec(pE))
%
% Because priors are specified under log normal assumptions, most
% parameters are simply scaling coefficients with a prior expectation
% and variance of one.  After log transform this renders pE = 0 and
% pC = 1;  The prior expectations of what they scale are specified in
% spm_erp_fx
%__________________________________________________________________________
%
% David O, Friston KJ (2003) A neural mass model for MEG/EEG: coupling and
% neuronal dynamics. NeuroImage 20: 1743-1755
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_erp_priors.m 2374 2008-10-21 18:52:29Z karl $
 
% default: a single source model
%--------------------------------------------------------------------------
if nargin < 3
    A   = {0 0 0};
    B   = {};
    C   = 1;
end
 
% disable log zero warning
%--------------------------------------------------------------------------
warning('off','MATLAB:log:logOfZero');
n     = size(C,1);                                 % number of sources
u     = size(C,2);                                 % number of inputs

% parameters for neural-mass forward model
%==========================================================================
n1    = ones(n,1);
 
% set intrinsic [excitatory] time constants
%--------------------------------------------------------------------------
E.T   = log(n1);        V.T = n1/8;                % time constants
E.H   = log(n1);        V.H = n1/32;               % synaptic density
 
% set parameter of activation function
%--------------------------------------------------------------------------
E.S   = [0 0];          V.S = [1 1]/8;             % dispersion & threshold
 
 
% set extrinsic connectivity
%--------------------------------------------------------------------------
Q     = sparse(n,n);
for i = 1:length(A)
      A{i} = ~~A{i};
    E.A{i} = A{i}*32 - 32;                         % forward
    V.A{i} = A{i}/16;                              % backward
    Q      = Q | A{i};                             % and lateral connections
end
 
for i = 1:length(B)
      B{i} = ~~B{i};
    E.B{i} = 0*B{i};                               % input-dependent scaling
    V.B{i} = B{i}/16;
    Q      = Q | B{i};
end
C      = ~~C;
E.C    = C*32 - 32;                                % where inputs enter
V.C    = C/32;
 
% set delay (enforcing symmetric delays)
%--------------------------------------------------------------------------
E.D        = sparse(n,n);
V.D        = Q/16;
 
% set stimulus parameters: onset and dispersion
%--------------------------------------------------------------------------
E.R        = sparse(u,2);  V.R   = ones(u,1)*[1/16 1/16];
warning('on','MATLAB:log:logOfZero');

 
% covariance of neural parameters
%==========================================================================
pE    = E;
pC    = diag(sparse(spm_vec(V)));


return
 
% demo for log-normal pdf
%==========================================================================
x    = [1:64]/16;
for i = [2 16 128]
    v = 1/i;
    p = 1./x.*exp(-log(x).^2/(2*v))/sqrt(2*pi*v);
    plot(x,p)
    text(x(16),p(16),sprintf('variance = 1/%i',1/v))
    hold on
end
xlabel('scaling')
ylabel('density')
grid on
hold off
axis square
