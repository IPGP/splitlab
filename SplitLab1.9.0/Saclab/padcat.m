function b = padcat(dim, varargin)
% B = PADCAT(DIM, A1, A2, ...); concatenates two-dimensional matrices
% A1, A2, ... along dimension DIM. If the matrics have different lengths along the
% other dimension, they are padded with NaNs to the same length equal to the longest
% length among the matrices for numerical matrices, and with ' ' for charater matrices.

% Copyright, 19, The Board of Governors of the Los Alamos National Security, LLC.
% This software was produced under a U. S. Government contract (DE-AC52-06NA25396)
% by Los Alamos National Laboratory, which is operated by the Los Alamos
% National Security, LLC for the U. S. Department of Energy. The U. S. Government
% is licensed to use, reproduce, and distribute this software. Permission is granted
% to the public to copy and use this software without charge, provided that 
% this Notice and any statement of authorship are reproduced on all copies.
% Neither the Government nor the LANS makes any warranty, express or implied, 
% or assumes any liability or responsibility for the use of this software.
%
%           Xiaoning Yang	2002


% check input
if nargin < 2 || numel(dim) ~= 1
   error(' Dimension not provided !!!')
end
if dim ~= 1 && dim ~= 2
   error(' Dimension can only be 1 or 2 !!!')
end
if dim == 1
   dim2 = 2;
else
   dim2 = 1;
end

% find largest length
n = zeros(length(varargin),1);
for i = 1:length(varargin)
   n(i) = size(varargin{i},dim2);
end

% pad arrays
if any(diff(n))
   mx = max(n);
   for i = 1:length(varargin)
      si = size(varargin{i});
      si(dim2) = mx-n(i);
      if ischar(varargin{i})
         dummy = ' ';
         varargin(i) = {cat(dim2,varargin{i},dummy(ones(si)))};
      else
         varargin(i) = {cat(dim2,varargin{i},nan*ones(si))};
      end
   end
end

% cat arrays
b = cat(dim,varargin{:});
