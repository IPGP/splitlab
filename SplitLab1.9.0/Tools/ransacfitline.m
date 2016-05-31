% RANSACFITLINE - fits line to 3D array of points using RANSAC
%
% Usage  [L, inliers] = ransacfitline(XYZ, t, feedback)
%
% This function uses the RANSAC algorithm to robustly fit a line
% to a set of 3D data points.
%
% Arguments:
%          XYZ - 3xNpts array of xyz coordinates to fit line to.
%          t   - The distance threshold between data point and the line
%                used to decide whether a point is an inlier or not.
%          feedback - Optional flag 0 or 1 to turn on RANSAC feedback
%                     information.
%
% Returns:.
%           V - Line obtained by a simple fitting on the points that
%               are considered inliers.  The line goes through the
%               calculated mean of the inlier points, and is parallel to
%               the principal eigenvector.  The line is scaled by the
%               square root of the largest eigenvalue.
%               This line is a n*2 matrix.  The first column is the
%               beginning point, the second column is the end point of the
%               line.
%           L - The two points in the data set that were found to
%               define a line having the most number of inliers.
%               The two columns of L defining the two points.
%           inliers - The indices of the points that were considered
%                     inliers to the fitted line.
%
% See also:  RANSAC, FITPLANE, RANSACFITPLANE

% Copyright (c) 2003-2006 Peter Kovesi and Felix Duvallet (CMU)
% School of Computer Science & Software Engineering
% The University of Western Australia
% http://www.csse.uwa.edu.au/
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in 
% all copies or substantial portions of the Software.
%
% The Software is provided "as is", without warranty of any kind.

% Aug  2006 - created ransacfitline from ransacfitplane
%             author: Felix Duvallet

function [V, L, inliers] = ransacfitline(XYZ, t, feedback)
    
    if nargin == 2
	feedback = 0;
    end
    
    [rows, npts] = size(XYZ);
    
    if rows ~=3
        error('data is not 3D');
    end
    
    if npts < 2
        error('too few points to fit line');
    end
    
    s = 2;  % Minimum No of points needed to fit a line.
        
    fittingfn = @defineline;
    distfn    = @lineptdist;
    degenfn   = @isdegenerate;

    [L, inliers] = ransac(XYZ, fittingfn, distfn, degenfn, s, t, feedback);
    
    % Find the line going through the mean, parallel to the major
    % eigenvector
    V = fitline3d(XYZ(:, inliers));
    
%------------------------------------------------------------------------
% Function to define a line given 2 data points as required by
% RANSAC.

function L = defineline(X);
    L = X;
    
%------------------------------------------------------------------------
% Function to calculate distances between a line and a an array of points.
% The line is defined by a 3x2 matrix, L.  The two columns of L defining
% two points that are the endpoints of the line.
%
% A line can be defined with two points as:
%        lambda*p1 + (1-lambda)*p2
% Then, the distance between the line and another point (p3) is:
%        norm( lambda*p1 + (1-lambda)*p2 - p3 )
% where
%                  (p2-p1).(p2-p3)
%        lambda =  ---------------
%                  (p1-p2).(p1-p2)
%
% lambda can be found by taking the derivative of:
%      (lambda*p1 + (1-lambda)*p2 - p3)*(lambda*p1 + (1-lambda)*p2 - p3)
% with respect to lambda and setting it equal to zero

function [inliers, L] = lineptdist(L, X, t)

    p1 = L(:,1);
    p2 = L(:,2);
    
    npts = length(X);
    d = zeros(npts, 1);
    
    for i = 1:npts
        p3 = X(:,i);
      
        lambda = dot((p2 - p1), (p2-p3)) / dot( (p1-p2), (p1-p2) );
        
        d(i) = norm(lambda*p1 + (1-lambda)*p2 - p3);
    end
    
    inliers = find(abs(d) < t);
    
%------------------------------------------------------------------------
% Function to determine whether a set of 2 points are in a degenerate
% configuration for fitting a line as required by RANSAC.
% In this case two points are degenerate if they are the same point
% or if they are exceedingly close together.

function r = isdegenerate(X)
    %find the norm of the difference of the two points
    % this will be 0 iff the two points are the same (the norm of their
    % difference is zero)
    r = norm(X(:,1) - X(:,2)) < eps;
    
    
    
    
    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RANSAC - Robustly fits a model to data with the RANSAC algorithm
%
% Usage:
%
% [M, inliers] = ransac(x, fittingfn, distfn, degenfn s, t, feedback, ...
%                       maxDataTrials, maxTrials)
%
% Arguments:
%     x         - Data sets to which we are seeking to fit a model M
%                 It is assumed that x is of size [d x Npts]
%                 where d is the dimensionality of the data and Npts is
%                 the number of data points.
%
%     fittingfn - Handle to a function that fits a model to s
%                 data from x.  It is assumed that the function is of the
%                 form: 
%                    M = fittingfn(x)
%                 Note it is possible that the fitting function can return
%                 multiple models (for example up to 3 fundamental matrices
%                 can be fitted to 7 matched points).  In this case it is
%                 assumed that the fitting function returns a cell array of
%                 models.
%                 If this function cannot fit a model it should return M as
%                 an empty matrix.
%
%     distfn    - Handle to a function that evaluates the
%                 distances from the model to data x.
%                 It is assumed that the function is of the form:
%                    [inliers, M] = distfn(M, x, t)
%                 This function must evaluate the distances between points
%                 and the model returning the indices of elements in x that
%                 are inliers, that is, the points that are within distance
%                 't' of the model.  Additionally, if M is a cell array of
%                 possible models 'distfn' will return the model that has the
%                 most inliers.  If there is only one model this function
%                 must still copy the model to the output.  After this call M
%                 will be a non-cell object representing only one model. 
%
%     degenfn   - Handle to a function that determines whether a
%                 set of datapoints will produce a degenerate model.
%                 This is used to discard random samples that do not
%                 result in useful models.
%                 It is assumed that degenfn is a boolean function of
%                 the form: 
%                    r = degenfn(x)
%                 It may be that you cannot devise a test for degeneracy in
%                 which case you should write a dummy function that always
%                 returns a value of 1 (true) and rely on 'fittingfn' to return
%                 an empty model should the data set be degenerate.
%
%     s         - The minimum number of samples from x required by
%                 fittingfn to fit a model.
%
%     t         - The distance threshold between a data point and the model
%                 used to decide whether the point is an inlier or not.
%
%     feedback  - An optional flag 0/1. If set to one the trial count and the
%                 estimated total number of trials required is printed out at
%                 each step.  Defaults to 0.
%
%     maxDataTrials - Maximum number of attempts to select a non-degenerate
%                     data set. This parameter is optional and defaults to 100.
%
%     maxTrials - Maximum number of iterations. This parameter is optional and
%                 defaults to 1000.
%
% Returns:
%     M         - The model having the greatest number of inliers.
%     inliers   - An array of indices of the elements of x that were
%                 the inliers for the best model.
%
% For an example of the use of this function see RANSACFITHOMOGRAPHY or
% RANSACFITPLANE 

% References:
%    M.A. Fishler and  R.C. Boles. "Random sample concensus: A paradigm
%    for model fitting with applications to image analysis and automated
%    cartography". Comm. Assoc. Comp, Mach., Vol 24, No 6, pp 381-395, 1981
%
%    Richard Hartley and Andrew Zisserman. "Multiple View Geometry in
%    Computer Vision". pp 101-113. Cambridge University Press, 2001

% Copyright (c) 2003-2006 Peter Kovesi
% School of Computer Science & Software Engineering
% The University of Western Australia
% pk at csse uwa edu au    
% http://www.csse.uwa.edu.au/~pk
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in 
% all copies or substantial portions of the Software.
%
% The Software is provided "as is", without warranty of any kind.
%
% May      2003 - Original version
% February 2004 - Tidied up.
% August   2005 - Specification of distfn changed to allow model fitter to
%                 return multiple models from which the best must be selected
% Sept     2006 - Random selection of data points changed to ensure duplicate
%                 points are not selected.
% February 2007 - Jordi Ferrer: Arranged warning printout.
%                               Allow maximum trials as optional parameters.
%                               Patch the problem when non-generated data
%                               set is not given in the first iteration.
% August   2008 - 'feedback' parameter restored to argument list and other
%                 breaks in code introduced in last update fixed.
% 

function [M, inliers] = ransac(x, fittingfn, distfn, degenfn, s, t, feedback, ...
                               maxDataTrials, MaxTrials)

    % Test number of parameters
    error ( nargchk ( 6, 9, nargin ) );
    error ( nargoutchk ( 2, 2, nargout ) );
    
    if nargin < 9; maxTrials = 1000;    end; 
    if nargin < 8; maxDataTrials = 100; end; 
    if nargin < 7; feedback = 0;        end;
    
    [rows, npts] = size(x);                 
    
    p = 0.99;         % Desired probability of choosing at least one sample
                      % free from outliers

    bestM = NaN;      % Sentinel value allowing detection of solution failure.
    trialcount = 0;
    bestscore =  0;    
    N = 1;            % Dummy initialisation for number of trials.
    
    while N > trialcount
        
        % Select at random s datapoints to form a trial model, M.
        % In selecting these points we have to check that they are not in
        % a degenerate configuration.
        degenerate = 1;
        count = 1;
        while degenerate
            % Generate s random indicies in the range 1..npts
            % (If you do not have the statistics toolbox, or are using Octave,
            % use the function RANDOMSAMPLE from my webpage)
            ind = randomsample(npts, s);

            % Test that these points are not a degenerate configuration.
            degenerate = feval(degenfn, x(:,ind));
            
            if ~degenerate 
                % Fit model to this random selection of data points.
                % Note that M may represent a set of models that fit the data in
                % this case M will be a cell array of models
                M = feval(fittingfn, x(:,ind));
                
                % Depending on your problem it might be that the only way you
                % can determine whether a data set is degenerate or not is to
                % try to fit a model and see if it succeeds.  If it fails we
                % reset degenerate to true.
                if isempty(M)
                    degenerate = 1;
                end
            end
            
            % Safeguard against being stuck in this loop forever
            count = count + 1;
            if count > maxDataTrials
                warning('Unable to select a nondegenerate data set');
                break
            end
        end
        
        % Once we are out here we should have some kind of model...        
        % Evaluate distances between points and model returning the indices
        % of elements in x that are inliers.  Additionally, if M is a cell
        % array of possible models 'distfn' will return the model that has
        % the most inliers.  After this call M will be a non-cell object
        % representing only one model.
        [inliers, M] = feval(distfn, M, x, t);
        
        % Find the number of inliers to this model.
        ninliers = length(inliers);
        
        if ninliers > bestscore    % Largest set of inliers so far...
            bestscore = ninliers;  % Record data for this model
            bestinliers = inliers;
            bestM = M;
            
            % Update estimate of N, the number of trials to ensure we pick, 
            % with probability p, a data set with no outliers.
            fracinliers =  ninliers/npts;
            pNoOutliers = 1 -  fracinliers^s;
            pNoOutliers = max(eps, pNoOutliers);  % Avoid division by -Inf
            pNoOutliers = min(1-eps, pNoOutliers);% Avoid division by 0.
            N = log(1-p)/log(pNoOutliers);
        end
        
        trialcount = trialcount+1;
        if feedback
            fprintf('trial %d out of %d         \r',trialcount, ceil(N));
        end

        % Safeguard against being stuck in this loop forever
        if trialcount > maxTrials
            warning( ...
            sprintf('ransac reached the maximum number of %d trials',...
                    maxTrials));
            break
        end     
    end
    if feedback;    fprintf('\n');    end

    if ~isnan(bestM)   % We got a solution 
        M = bestM;
        inliers = bestinliers;
    else           
        M = [];
        inliers = [];
        error('ransac was unable to find a useful solution');
    end
    
    
    
    
    
    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RANDOMSAMPLE - selects n random items from an array
%
% Usage:  items = randomsample(a, n)
%
% Arguments:    a - Either an array of values from which the items are to
%                   be selected, or an integer in which case the items
%                   are values selected from the array [1:a]
%               n - The number of items to be selected.
%
%
% This function can be used as a basic replacement for RANDSAMPLE for those
% who do not have the statistics toolbox.
% Also,
%    r = randomsample(n,n) will give a random permutation of the integers 1:n 
%
% See also: RANSAC

% Strategy is to generate a random integer index into the array and select that
% item from the array.  The selected element in the array is then overwritten by
% the last element in the array and the process is then repeated except that
% when we select the next element we generate a random integer index that lies
% in the range 1 to arraylength - 1, and so on.  This ensures items are not
% repeated.

% Copyright (c) 2006 Peter Kovesi
% School of Computer Science & Software Engineering
% The University of Western Australia
% pk at csse uwa edu au    
% http://www.csse.uwa.edu.au/~pk
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in 
% all copies or substantial portions of the Software.
%
% The Software is provided "as is", without warranty of any kind.

% September   2006 



function item = randomsample(a, n)
    
    npts = length(a);

    if npts == 1   % We have a scalar argument for a
	npts = a;
	a = [1:a]; % Construct an array 1:a
    end
    
    if npts < n
	error(...
	sprintf('Trying to select %d items from a list of length %d',n, npts));
    end
    
    item = zeros(1,n);
    
    for i = 1:n
	% Generate random value in the appropriate range 
	r = ceil((npts-i+1).*rand);
	item(i) = a(r);       % Select the rth element from the list
	a(r)    = a(end-i+1); % Overwrite selected element
    end                       % ... and repeat
    
    
    
    
% FITLINE3D - Fits a line to a set of 3D points
%
% Usage:   [L] = fitline3d(XYZ)
%
% Where: XYZ - 3xNpts array of XYZ coordinates
%               [x1 x2 x3 ... xN;
%                y1 y2 y3 ... yN;
%                z1 z2 z3 ... zN]
%
% Returns: L - 3x2 matrix consisting of the two endpoints of the line
%              that fits the points.  The line is centered about the
%              mean of the points, and extends in the directions of the
%              principal eigenvectors, with scale determined by the
%              eigenvalues.
%
% Author: Felix Duvallet (CMU)
% August 2006



function L = fitline3d(XYZ)

% Since the covariance matrix should be 3x3 (not NxN), need
% to take the transpose of the points.
XYZ = XYZ';

% find mean of the points
mu = mean(XYZ, 1);

% covariance matrix
C = cov(XYZ);

% get the eigenvalues and eigenvectors
[V, D] = eig(C);

% largest eigenvector is in the last column
col = size(V, 2);  %get the number of columns

% get the last eigenvector column and the last eigenvalue
eVec = V(:, col);
eVal = D(col, col);

% start point - center about mean and scale eVector by eValue
L(:, 1) = mu' - sqrt(eVal)*eVec;
% end point
L(:, 2) = mu' + sqrt(eVal)*eVec;




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%