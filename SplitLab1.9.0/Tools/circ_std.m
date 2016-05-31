function s = circ_std(alpha, w, d)
% s = circ_std(alpha, w, d)
%   Computes circular standard deviation for circular data 
%   (equ. 26.20, Zar).   
%
%   Input:
%     alpha	sample of angles in radians
%     [w		weightings in case of binned angle data]
%     [d    spacing of bin centers for binned data, if supplied 
%           correction factor is used to correct for bias in 
%           estimation of r]
%
%   Output:
%     s     circular standard deviation
%
% PHB 6/7/2008
%
% References:
%   Statistical analysis of circular data, N.I. Fisher
%   Topics in circular statistics, S.R. Jammalamadaka et al. 
%   Biostatistical Analysis, J. H. Zar
%
% Copyleft (c) 2008 Philipp Berens
% berens@tuebingen.mpg.de - www.kyb.mpg.de/~berens/circStat.html
% Distributed under GPLv3 with no liability
% http://www.gnu.org/copyleft/gpl.html

% check vector size
if size(alpha,2) > size(alpha,1)
	alpha = alpha';
end

if nargin<2
  % if no specific weighting has been specified
  % assume no binning has taken place
	w = ones(size(alpha));
end

if nargin<3
  % per default do not apply correct for binned data
  d = 0;
end

% compute mean resultant vector length
r = circ_r(alpha,w,d);

% apply transformation to std
s = sqrt(2*(1-r));