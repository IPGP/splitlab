function [out1, out2, out3] = sacgetdata(s)
% [INDEP, DEP] = GETSACDATA(S); extracts independent and dependent variables
% from SAC structure S and puts them in INDEP and DEP. INDEP and DEP can either
% be time and data or x and y. They are cell arrays if length(S) > 1 and double
% arrays otherwise.
%
% [OUT1, OUT2, OUT3] = GETSACDATA(S); extracts either spectral data from spectral
% type of SAC files or xyz data from xyz SAC files. In case of spectral files,
% OUT1 is frequency, OUT2 is either real part or amplitude, and OUT3 is either
% imaginary part or phase.
%
% S is defined in m-file readsac.m and is usually the output from readsac.m.
% S must contain same type of data (time series, spectra or xyz).

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
%           Xiaoning Yang	2002, 2008

% check output arguments
if nargout < 2
   error(' Number of output arguments must be larger than one !!!')
end

% allocate output arguments
l = length(s);
if l == 0
   out1 = [];
   out2 = [];
   if nargout == 3
      out3 = [];
   end
   return
end
out1 = cell(l,1);
out2 = cell(l,1);
if nargout == 3
   out3 = cell(l,1);
end

% reference time for all traces
year0 = s(1).NZYEAR-1901;
days0 = year0*365+round(year0/4)+s(1).NZJDAY;
ref0 = days0*86400+s(1).NZHOUR*3600+s(1).NZMIN*60+s(1).NZSEC+s(1).NZMSEC/1000;

% loop over s
ll = zeros(l, 1); % lengths of time series
for i = 1:l
   ll(i) = length(s(i).DATA1);
   if i == 1
      file_type = s(i).IFTYPE;
   end

   % check file type
   if ~strcmp(s(i).IFTYPE,file_type)
      error(' File types in input structure must be same !!!')
   end

   if strcmp(s(i).IFTYPE,'IXYZ')    % this file type is not defined in SAC
      if nargout ~= 3
         error(' Number of output arguments for XYZ file must be three !!!')
      end
      out1(i) = {s(i).DATA2};    % to be consistent with XY type of data
      out2(i) = {s(i).DATA3};
      out3(i) = {s(i).DATA1};
   elseif strcmp(s(i).IFTYPE,'IXY')
      if nargout ~= 2
         error(' Number of output arguments for XY file must be two !!!')
      end
      out1(i) = {s(i).DATA2};
      out2(i) = {s(i).DATA1};
   else     % spectrum and evenly-spaced time series         
      if isnan(s(i).B)
         B = 0;
      else
         B = s(i).B;
      end
      if strcmp(s(i).IFTYPE,'ITIME')

         if isnan(s(i).O)
            % reference time of this trace
            year = s(i).NZYEAR-1901;
            days = year*365+round(year/4)+s(i).NZJDAY;
            ref = days*86400+s(i).NZHOUR*3600+s(i).NZMIN*60+s(i).NZSEC+ ...
               s(i).NZMSEC/1000;

            B = B+ref-ref0;
            if isnan(B)
               B = 0;
            end
            O = 0;
         else
            O = s(i).O;
         end
         out1(i) = {(0:s(i).NPTS-1)'*s(i).DELTA+B-O};
      else
         out1(i) = {(0:s(i).NPTS-1)'*s(i).DELTA+B};
      end

      if strcmp(s(i).IFTYPE,'ITIME') && nargout ~= 2
         error([' Number of output arguments for time-series data ', ...
            'must be two !!!'])
      elseif ~strcmp(s(i).IFTYPE,'ITIME') && nargout ~= 3
         error([' Number of output arguments for spectral data must be ', ...
            'three !!!'])
      else
         out2(i) = {s(i).DATA1};
         if ~strcmp(s(i).IFTYPE,'ITIME')
            out3(i) = {s(i).DATA2};
         end
      end
   end
end

if l == 1
   out1 = out1{:};
   out2 = out2{:};
   if nargout == 3
      out3 = out3{:};
   end
elseif ~any(diff(ll))
   temp1 = zeros(ll(1), l);
   temp2 = temp1;
   if nargout == 3
      temp3 = temp1;
   end
   for i = 1:l
      temp1(:, i) = out1{i};
      temp2(:, i) = out2{i};
      if nargout == 3
         temp3(:, i) = out3{i};
      end
   end
   out1 = temp1;
   out2 = temp2;
   if nargout == 3
      out3 = temp3;
   end
end
