function stationLookUp(src,evt)
global config

thisstation  = config.stnname;

load IRISstations02May2009.mat

%compare input station name with list of stations in IRIS file
i = find(strcmpi(C{2}, thisstation));
if isempty(i)
    errordlg('Sorry, no matching station found in database','No Station','modal')
    return
end
    
s=repmat(' | ',length(i),1);

start = char(C{3}(i));
start = start(:,1:10);
str=[char(C{1}(i))  s char(C{2}(i)) s start s char(C{4}(i)) s num2str(C{5}(i),'%10.3f') s num2str(C{6}(i),'%10.3f')];


[selection,ok] = listdlg('PromptString','Select a station:',...
                'ListSize',[350 100],...
                'SelectionMode','single',...
                'ListString',str);
            
if ~ok
    return
end


%% now set station parameters in base config
id = i(selection);
       [y1, m1, d1] = datevec(C{3}(id),'yyyy-mm-dd');
        
        if datenum(datevec(C{4}(id),'yyyy-mm-dd'))>now;         
            [y2, m2, d2] = datevec(now);
        else
            [y2, m2, d2] = datevec(C{4}(id),'yyyy-mm-dd');
        end
        if y1<1976
            y1=1976;
            d1=1;
            m1=1;
        end
        twin= num2str([d1 m1 y1 d2 m2 y2]);        
        comment = strrep(char(C{8}(id)),'''','');
        evalin('base',...
            ['config.twin=['   num2str(twin) ']; '...
            'config.project='''  thisstation '.pjt'' ;'...
            'config.slat='   num2str(C{5}(id)) '; '...
            'config.slong='   num2str(C{6}(id)) '; '...
            'config.selev='    num2str(C{7}(id)) '; '...
            'config.stnname='''  char(C{2}(id)) '''; '...
            'config.comment=''' comment '''; '...
            'config.netw='''    char(C{1}(id)) '''; '])
        splitlab;


