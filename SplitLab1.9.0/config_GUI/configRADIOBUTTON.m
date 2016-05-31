function configRADIOBUTTON(~,callbackdata)
global config

str1 = {'MinE','MinL1L2','MinL2L1','MaxL1L2','MaxL1','MinL2'};
val1 = strmatch(callbackdata.NewValue.Tag,str1,'exact'); %#ok
str2 = {'fixed','estimated'};
val2 = strmatch(callbackdata.NewValue.Tag,str2,'exact');%#ok

if ~isempty(val1)
    config.splitoption = callbackdata.NewValue.String;
end

if ~isempty(val2)
    config.inipoloption = callbackdata.NewValue.Tag;
end

end