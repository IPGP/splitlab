function [xc0, yc0, best, bestmembers, vcx0, vcy0]=clusteranal(x,y, x_spacing, y_spacing, fig)
% find cluster location [xc0, yc0] of scattered data [x, y]
% [xc0, yc0] = cluster; without input arguments runs an example





if nargin<1;
%    x  = [ 0.1325,  0.2684,  0.3122,  0.3491,  0.2500,  0.2431,  0.1578,  0.2408,  0.3053,  0.2385,  0.1671,  0.1878,  0.2753,  0.2062,  0.2823,  0.5910,  0.7293,  0.6671,  0.8030,  0.7385];
%    y  = [ 0.5219,  0.5278,  0.4927,  0.6330,  0.6798,  0.5980,  0.6944,  0.7412,  0.7617,  0.8114,  0.8085,  0.7208,  0.7880,  0.6623,  0.5950,  0.2588,  0.2003,  0.4254,  0.2763,  0.3991];
% 
%    x = [0.7 0.7 0.8 0.8    0.2 0.2 0.3 0.3] ;
%    y = [0.4 0.3 0.3 0.4    0.7 0.8 0.8 0.7];
   x = [(rand(20,1)*2-1)/4+rand*10;  (rand(20,1)*2-1)+rand*10;  (rand(20,1)*2-1)+rand*10;  (rand(20,1)*2-1)+rand*10;  (rand(20,1)*2-1)+rand*10;]';
   y = [(rand(20,1)*2-1)/4+rand*10;  (rand(20,1)*2-1)+rand*10;  (rand(20,1)*2-1)+rand*10;  (rand(20,1)*2-1)+rand*10;  (rand(20,1)*2-1)+rand*10;]';
  
   x = x * 100 - 500;
   y = y * 100 - 500;
end



dx = 0.02 + x;
dy = 0.02 + y;
N  = length(x);


%%define parameters
xmax            = max(x(:));
ymax            = max(y(:));
if nargin<3
    x_spacing       = min(abs(diff(x))) ;
    y_spacing       = min(abs(diff(y))) ;
end
max_no_clusters    = 5;
minNumberInCluster = 5;

if length(x(:)) < minNumberInCluster
    error(['A minimum of ' num2str(minNumberInCluster)  ' values is required for cluster analysis'])
end


%%c  ** do cluster analysis and find number of clusters **
[xc0, yc0, vxc0, vyc0, clustidx,k] = PerformClusterAnalysis(x, dx, y, dy, N,...
    xmax, ymax, x_spacing, y_spacing, max_no_clusters,minNumberInCluster);




xid= (xc0~=0);
yid= (yc0~=0);
id = yid|xid;


 
%  disp([vxc0(xid) vyc0(yid) ])
varcluster = sqrt([vxc0(id) vyc0(id) ]);
varcluster = sqrt(sum(varcluster.^2,2)); 
[m,best]=min(varcluster);
bestmembers = clustidx(:,k) == best; %vector of logicals


if nargout==0 || nargin==5;
    figure(fig)
    clf
    T=clustidx(:,k);
    plot(x(T==1),y(T==1),'b.', x(T==2),y(T==2),'r.', x(T==3),y(T==3),'m.', x(T==4),y(T==4),'g.', x(T==5),y(T==5),'k.',...
        xc0(id),    yc0(id)    ,'bo',...
        xc0(best), yc0(best) ,'r*')

    clear cluster
    figure(fig+1)
    clf
    M = [x(:) y(:)];
    Y = pdist(M);
    Z = linkage(Y);
    T = cluster(Z,'maxclust',5);
    plot(x(T==1),y(T==1),'b.', x(T==2),y(T==2),'r.', x(T==3),y(T==3),'m.', x(T==4),y(T==4),'g.', x(T==5),y(T==5),'k.');
else
    xc0  = xc0(id);
    yc0  = yc0(id);
    vcx0 = vxc0(id);
    vcy0 = vyc0(id);
end









%% ========================================================================
function [xc0, yc0, vxc0, vyc0, cluster, k] = PerformClusterAnalysis(x0, dx0, y0, dy0, n,...
    xscale, yscale, xmin0, ymin0, max_no_clusters, minNumberInCluster)
x0(x0==xscale) = x0(x0==xscale) * .99;
x  = x0  / xscale;
dx = dx0 / xscale;
y  = y0  / yscale;   %fast axis always ranges between [-90 and 90]
dy = dy0 / yscale;

xmin = xmin0 / xscale; %normalized grid spacing
ymin = ymin0 / yscale; %normalized grid spacing



[xc, yc, vxc, vyc, cluster] = cluster_agglomerative(x, y, n, minNumberInCluster);

%%  ** calc clustering criteria **
%  ** calc k using Calinski and Harabasz (1974) method **
k1 = c_74calhar(x, y, n, xc, yc, xmin, ymin, cluster, max_no_clusters);
%  ** calc k using Duda and Hart (1973) method **
k2 = c_73dudhar(x, y, n, xc, yc, xmin, ymin, cluster, max_no_clusters);
%  ** set number of clusters to max of k1 and k2 **
k = max(k1, k2);
% disp ('  k_cal   k_dud')
% disp([k1 k2])


%%  ** unscale the cluster possitions and variances **
xc0  =        xscale *  xc(:,k);
yc0  =        yscale *  yc(:,k);
vxc0 = xscale*xscale * vxc(:,k);
vyc0 = yscale*yscale * vyc(:,k);




%% ========================================================================
function kopt = c_74calhar(x, y, n, xc, yc,  xmin, ymin, cluster, max_no_clusters)

%  ** calc x/ybar **
xbar=0.;
ybar=0.;
for  i=1:n
    xbar = xbar + x(i);
    ybar = ybar + y(i);
end

xbar = xbar / n;
ybar = ybar / n;



%  ** calc c for each number of clusters **
c(1)=0.;
c(max(n, max_no_clusters))=0.;
for kk=2:n
    tracew=0.;
    traceb=0.;
    for j=1:kk
        nc = 0;
        for  i=1:n
            if (cluster(i, kk)==j)
                tracew = tracew ...
                    + (   max(xmin, x(i)-xc(j,kk)) )^2 ...
                    + (   max(ymin, y(i)-yc(j,kk)) )^2;
                nc = nc+1;
            end
        end
        traceb = traceb + nc * (   (xc(j,kk)-xbar)^2    +      (yc(j,kk)-ybar)^2  );
        % traceb = traceb + nc * (   ( (xc(j,kk)-xbar))^2   +    ( (yc(j,kk)-ybar)  )^2   );
    end
    if tracew==0;tracew=.000001;end
    c(kk) = traceb  *  double(n-kk) / (double(kk-1) * tracew);
end


%  ** find optimum number of clusters **
c_max = c(1);
kopt  = 1;
for kk = 2:max_no_clusters 
    if (c(kk)>c_max)
        c_max = c(kk);
        kopt  = kk;
    end
end
% disp('')


%% ========================================================================
function kopt = c_73dudhar(x, y, n, xc, yc,  xmin, ymin, cluster, max_no_clusters)

first_pass = true;
exit = false;

kopt       = 1;
c(n)       = 0.;
c_critical = 3.20;
cluster1 = -1;
%c  ** for all numbers of clusters **
for ( kk=1:n-1 )
    %c	** for each cluster **
    for ( j=1:kk)
        %c	   ** for each data point **
        %c	   ** search each data point to find a single cluster which is two seperate clusters when the number of clusters is increased by one **
        first_pass = true;
        for ( i=1:n)
            if (cluster(i,kk) == j)
                if (first_pass)
                    first_pass  = false;
                    cluster1 = cluster(i,kk+1);
                    cluster12= j;
                elseif (cluster(i,kk+1) ~= cluster1)
                    cluster2 = cluster(i,kk+1);
                    idx = kk;
                    exit = true;
                    break;%i-loop
                end
            end
        end
        if exit;    break; end
    end
    if exit;    break; end
end




%------------------------------------------------------
if exit
    %c  ** calc Je1 **
    %c  ** cluster12 = number of the combined cluster when there are k clusters **
    je1 = 0.;
    nc  = 0;
    c(max(n,max_no_clusters))=0.;
    for (i=1:n)
        if (cluster(i,idx) == cluster12)
            je1 = je1...
                + (    max(xmin, x(i)-xc(cluster12,idx))  )^2 ...
                + (    max(ymin, y(i)-yc(cluster12,idx))  )^2;
            nc=nc+1;
        end
        %c  ** calc Je2 **
        %c  ** cluster1 and cluster2 = number of the seperate clusters when there
        %c	are k+1 clusters **
        je2 = 0.;
        for ( i=1:n)
            if (cluster(i,idx+1)==cluster1)
                je2 = je2 ...
                + (    max(xmin, (x(i)-xc(cluster12,idx)))  )^2 ...
                + (    max(ymin, (y(i)-yc(cluster12,idx)))  )^2;
            end
            if (cluster(i,idx+1)==cluster2)
                je2 = je2 ...
                + (    max(xmin, (x(i)-xc(cluster12,idx)))  )^2 ...
                + (    max(ymin, (y(i)-yc(cluster12,idx)))  )^2;
            end
        end

        %%c	** this is the special case for 2 parameters **
        c(idx)=(0.681690113 - je2/je1) * sqrt(nc/0.18943053);
    end

    %c  ** search for the optimum number of clusters **
    %c  ** if c(k) exceeds c_critical then the cluster should be subdivided,
    %c	giving kopt = k + 1 as the optimum number of clusters **
    for ( k=1:max_no_clusters )
        if (c(k)>c_critical)
            kopt = max(kopt, k+1);
        end
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [xc, yc, vxc, vyc, cluster] = cluster_agglomerative(x, y, n, minNumberInCluster);

cluster=nan(n,n);
xc  = zeros(n,n);
yc  = zeros(n,n);
vxc = zeros(n,n);
vyc = zeros(n,n);
d = zeros(n,n);
numClust=zeros(n,n);


%  ** initially there are n clusters **
k = n;
%  ** assign the k clusters **
for ( i=1:k)
    cluster(i,k) = i;
    xc(i,k)      = x(i);
    yc(i,k)      = y(i);
end


%  ** reduce the number of clusters from n to 1 **
%  ** by grouping the nearest neigbours **
for  k = (n-1):-1:1
    %%     ** calc the distance matrix between the k+1 clusters **
    d = diss_euclid(xc, yc, k+1, k+1);
    %%	** find minimum distance **
    [imin, jmin] = diss_min(d, k+1);
    %%     ** reasign the datapoints in cluster imin to cluster jmin **
    for (i=1:n)
        %%cluster(i, k+1) = 0;
        if (cluster(i, k+1) == imin)
            cluster(i, k) = jmin;
        else
            cluster(i, k) = cluster(i, k+1);
        end
    end


    %%    ** renumber clusters from 1-k (i.e. remove gaps in the cluster NOs) **
    cluster = clust_renumber(cluster, n, k);

    %%     ** find the average cluster positions **
    [xc, yc, vxc, vyc, numClust] = cluster_loc(x, y, cluster, k, n,minNumberInCluster, xc, yc, vxc, vyc, numClust);
 
end


% disp ('------------------------------------------------------')



%% ====================================================================
function d = diss_euclid(x, y, k, n);
for (i=2:n)
    for ( j=1:(i-1))
        d(i,j) = sqrt( (x(i,k)-x(j,k))^2  +  (y(i,k)-y(j,k))^2 );
    end
end

%% ====================================================================
function  [imin, jmin] = diss_min(d, n);

dmin = 1.e+30;
imin = 2;
jmin = 1;
%  ** find minimum distance **
for ( i=2:n)
    for ( j=1:(i-1))
        if ( d(i,j) < dmin )
            dmin = d(i,j);
            imin = i;
            jmin = j;
        end
    end
end





%% =====================================================================
function cluster =  clust_renumber(cluster,  n, k)
jump=nan;
imax = cluster(1,k);
for ( i=1:n)
    if (cluster(i,k) > imax)
        imax = cluster(i,k);
    end
end
%fprintf('%d %d %d\n',n, k, imax)
%  ** renumber the clusters from 1 to k **
%  ** for every cluster **

for ( i=1:k)
    jump = imax;
    skip = false;
    %%	** for all the data points **
    for ( j=1:n)
        if (cluster(j,k) == i)
            %%		** if cluster number exists move to next cluster number **
            skip = true;
            break;
        else
            %%		** else find the difference between cluster no. i and the nearest
            %%		   old cluster number **
            if (cluster(j,k)>i)
                jump = min(jump, cluster(j,k)-i);
            end
        end
    end

    if (~skip)
        %%	** shift all clusters numbered over i by -jump **
        for ( j=1:n)
            if ( cluster(j,k)>i)
                cluster(j,k) = cluster(j,k) - jump;
            end
        end
    end

end





%% ===================================================================
function [xc, yc, vxc, vyc, numClust] = cluster_loc(x, y, cluster, k, n,minNumberInCluster,        xc, yc, vxc, vyc, numClust)

%  ** calc the mean positions **
for ( j=1:k)
    nc(j) = 0;
    xsum  = 0.;
    ysum  = 0.;
    for ( i=1:n)
        if (cluster(i,k) == j)
            xsum = xsum + x(i);
            ysum = ysum + y(i);
            nc(j) = nc(j) + 1;
            numClust(j,k) = nc(j) ;
        end
        
    end
    xc(j,k) = xsum / nc(j);
    yc(j,k) = ysum / nc(j);
%  fprintf('%d  \n', nc(j) );
end

minNumberInCluster=5;
%  ** calc the within cluster variance for each cluster **
for ( j=1:k)
    nc(j) = 0;
    xsum  = 0.;
    ysum  = 0.;
    for ( i=1:n)
        if (cluster(i,k)==j)
            xsum = xsum + (x(i)-xc(j,k))^2;
            ysum = ysum + (y(i)-yc(j,k))^2;
            nc(j) = nc(j) + 1;
        end
    end

    if nc(j)>minNumberInCluster
        vxc(j,k) = xsum / nc(j);
        vyc(j,k) = ysum / nc(j);
    else
        vxc(j,k) = inf;
        vyc(j,k) = inf;
    end

end
