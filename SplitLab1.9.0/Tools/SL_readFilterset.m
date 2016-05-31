
function SL_readFilterset(varargin)


global config


deffname='SL_DefaultFilterSettings.dat';
[defpname, dummy]= fileparts(mfilename('fullpath'));
if nargin==0
    [fname, pname] = uigetfile('*.dat', 'Select FilterParameterFile', fullfile(defpname, deffname));
    if ~pname
        return
    end
else
    [pname, fname, ext]= fileparts(varargin{1});
    fname = [fname ext];
end




try
    config.filterset = dlmread(fullfile(pname,fname), '\t', 1, 0);
    if length(unique( config.filterset(:,1))) ~= size(config.filterset,1)
        error('The filter file does contain multiple definitions for one or more keys!')
    end
    config.filtersetFile = fullfile(pname, fname);

catch
    errordlg({['Sorry the specified file ' fullfile(pname,fname) '  does apparently not to match the required format.'] ,' ', lasterr, ' ', 'The default filterset will be used instead'})
    try
        config.filterset = dlmread( fullfile(defpname, deffname), '\t', 1, 0);
        config.filtersetFile = fullfile(defpname, deffname);
    catch
        errordlg('There seems to be something wrong with the default filter file. Use internal settings instead.')
        config.filterset = [
            0     0        inf     3
            1     0.01     0.1     3
            2     0.02     0.2     3
            3     0.02     0.3     3
            4     0.01     0.3     3
            5     0.01     0.4     3
            6     0.02     1.0     3
            7     0.01     0.15    3
            8     0.02     0.25    3
            9     0.01     1.0     3];
        config.filtersetFile ='';
    end

end

