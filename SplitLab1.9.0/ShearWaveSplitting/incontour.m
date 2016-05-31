function [minmaxCol, minmaxRow] = incontour(Ematrix,Ecrit)
% find contourinterval which contains the minimum energy value
% If more than one contour exist or the contour contiues between the limits
% of fast axis (-90 and 90) its simple way of determine the errorbar. This
% function duplicates the Energy map to surely have (at least) one closed
% interval

E = [Ematrix;Ematrix(2:end,:)];%small indices indicatre original matrix
S = size(Ematrix,1);

[row,col] = find(E==min(Ematrix(:)));%two minima since copied matrix

low  = floor(S/2);
high = ceil(S*3/2);
row       = row(low<row & row<high); %takevalue in centre of new matrix
col       = min(col); %is the same for both matrix parts

C         = contourc(E, [Ecrit Ecrit]);
if isempty(C)
    minmaxCol = [1 inf];
    minmaxRow = [-inf inf];
else
    %disassociate Contour matrix and see if minimum is within contour polygon
    n = 1;
    lastcontour = 0;%surely one contour...
    while ~lastcontour
        nContours = C(2,n)+n;
        xv = C(1,n+1:nContours);
        yv = C(2,n+1:nContours);
        xv = [xv , xv(1)]; %close polygon
        yv = [yv , yv(1)];

        if inpolygon(col,row, xv, yv);
            %plot(xv,yv,'b',col,row,'k*')
            break
        end

        if nContours == size(C,2)
            lastcontour =1;
            minmaxCol = [1 inf];
            minmaxRow = [-inf inf];
            return
        else
            n=nContours+1;
        end
    end

    minmaxCol = round([min(xv) max(xv)]);
    minmaxRow = round([min(yv) max(yv)]);
    minmaxRow = mod(minmaxRow, S);
end
