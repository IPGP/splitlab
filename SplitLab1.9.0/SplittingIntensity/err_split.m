function [err] = err_split(pp,compT,rmsR)
epsilon=1e-4;
npt = length(compT);

Et = diag(compT*transpose(compT));
err = Et(:)-0.25*rmsR(:).^2.*pp(:).^2;
err(:) = sqrt(err(:)/npt)+epsilon;
