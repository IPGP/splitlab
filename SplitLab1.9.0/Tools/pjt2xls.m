function pjt2xls
%save SplitLab project to MicroSoft Excel format

global eq config

%% 1) detect events with results
for i = 1 : length(eq)
    x(i)=~isempty(eq(i).results);
end
res = find(x==1) ; %indices to eq-structure

%% 2) create empty variables for later storage of indices
OUT={};
%% 3) read result field
%the variables are ordered with
%  1st column: eq-index
%  2nd column: result-index
%  3rd column: Phase identifier
% for example: if g=[3 2 1] means that the second result of third
% earthquake in the project is an SKS phase (id=1) and of good quality
% (since stored in variable g)
k=0;

set(gcf,'Pointer','watch')
for i = 1:length(res)
    num = res(i);
    for j=1:length(eq(num).results)
        k = k + 1;
        %         phase = eq(num).results(j).SplitPhase;
        %% Version compatibility:
        if ~isfield(eq(num).results(j),'method')||isempty(eq(num).results(j).method)
            eq(num).results(j).method = 'Minimum Energy';
        end
        if ~isfield(eq(num).results(j),'phiEV')||isempty(eq(num).results(j).phiEV)
            eq(num).results(j).phiEV(2) = inf;
            eq(num).results(j).dtEV(2) = inf;
        end


        OUT(k,:) = {datestr(eq(num).date(1:6)),...
            eq(num).date(7),...
            eq(num).lat,...
            eq(num).long,...
            eq(num).depth,... %5
            eq(num).bazi,...
            eq(num).dis,...
            eq(num).Mw,...
            abs(eq(num).energy), ...
            eq(num).results(j).incline ,... %10
            eq(num).results(j).SplitPhase,...
            eq(num).results(j).phiSC(1), eq(num).results(j).phiSC(2),...      %11 
            eq(num).results(j).phiRC(1), eq(num).results(j).phiRC(2),...      %13 
            eq(num).results(j).phiEV(1), eq(num).results(j).phiEV(2),...      %15 
            eq(num).results(j).dtSC(1),  eq(num).results(j).dtSC(2), ...       %17 
            eq(num).results(j).dtRC(1),  eq(num).results(j).dtRC(2), ...       %19
            eq(num).results(j).dtEV(1),  eq(num).results(j).dtEV(2), ...       %21
            eq(num).results(j).filter(1),...
            eq(num).results(j).filter(2),...
            eq(num).results(j).Spick(1),...
            eq(num).results(j).Spick(2),...%25
            eq(num).results(j).Qstr,...
            eq(num).results(j).Q,...
            eq(num).results(j).SNR(1),...
            eq(num).results(j).SNR(2),...
            eq(num).results(j).method,...%30
            eq(num).results(j).remark}; 
    end
end


%%

header = {'Date'  '%s'
    'JulianDay'   '%03.0f'
    'Lat'         '%6.1f'
    'Long'        '%6.1f'
    'Depth'       '%3.0f'
    'Backazimuth' '%5.1f'
    'Distance'    '%5.1f'
    'Mw'          '%3.1f'
    'SKS-Energy'  '%0.2f'
    'Inclination' '%4.1f'
    'Phase'       '%6s'
    'PhiSC'       '%5.1f'
    'errPhiSC'   '%5.1f'
    'PhiRC'       '%5.1f'
    'errPhiRC'   '%5.1f'
    'PhiEV'       '%5.1f'
    'errPhiEV'   '%5.1f'
    'dtSC'        '%4.1f'
    'errdtSC'    '%4.1f'
    'dtRC'        '%4.1f'
    'errdtRC'    '%4.1f'
    'dtEV'        '%4.1f'
    'errdtEV'    '%4.1f'
    'lower filter (Hz)' '%05.3f'
    'upper filter (Hz)' '%05.3f'
    't1'          '%8.2f'
    't2'          '%8.2f'
    'Manual' '%8s'
    'AutoQuality' '%5.3f'
    'SNR_(RC)'    '%5.1f'
    'SNR_(SC)'    '%5.1f'
    'Method'      '%s'
    'Remark'      '%s'};


%% Checking
if isempty(OUT)
    errordlg('No results in current Project!')
    set(gcf,'Pointer','arrow')
    return
end

[fname, pname,Index] = uiputfile(...
    {'*.xls','Excel file (*.xls)';...
    '*.csv', 'Comma separated list (*.csv)';...
    '*.xml', 'XML data sheet (*.xml)'},....
    'Export results',...
    fullfile(config.savedir,[config.project(1:end-4) '.xls']));
if isequal(fname,0) || isequal(pname,0)
    return
end



%% EXPORT
if Index == 3
    sucsess = exportxml(pname, fname, header, OUT);
    if ~sucsess
        set(gcbf,'Pointer','arrow')
        return
    end
elseif Index == 2
    sucsess = exportcellcsv(pname,fname, header, OUT);
    if ~sucsess
        set(gcbf,'Pointer','arrow')
        return
    end
elseif Index == 1
    last =num2str(size(OUT,1)+1);
    try
        xlswrite(fullfile(pname,fname), OUT,   ['A2:AI' num2str(last)]);
        xlswrite(fullfile(pname,fname), header(:,1)', 'A1:AI1');
        sucsess = 1;
    catch
        %%
        set(gcf,'Pointer','arrow')
        fname = strrep (fname, '.xls', '.csv');
        errordlg({['"' lasterr '"'],'',...
            'The Microsoft Excel export functionality requires ',...
            'Excel to be installed on this computer!',
            ' ',...
            'Please export to comma-seperated-value list (.csv), which is plain text!'},...
            'Excel Error')
        return
    end
end

% View new file
if ispc
    Answer=questdlg({'File witten to disk!',fullfile(pname,fname), ' ',...
        'Do you want to review the file?'}, ...
        'Open file', ...
        'Yes','No','Yes');
    switch Answer
        case 'Yes'
            File = fullfile(pname,fname);
            if ispc
                try
                    winopen(File)
                catch
                    errordlg({'Problems opening file ', File, ...
                        'The system error message is:',...
                        ' ' ,['"' lasterr '"']})
                end
                
                
            else %UNIX, LINUX or MACINTOSH
                asso      = getpref('Splitlab','Associations');
                [p,f,ext] = fileparts(File);
                found     = strfind(asso(:,1),ext);
                index     = find(~cellfun('isempty',found))
                if strcmp (ext, '.fig');
                    commandline = 'open($1);';
                else
                    commandline   = ['!' asso{2,index}];
                end
                commandstring = strrep(commandline, '$1', File);
                try
                    eval(commandstring)
                catch
                    e=errordlg({ 'Could not run ', commandstring(2:end),' ',lasterr});
                    waitfor(e)
                end
            end
    end
else
    helpdlg({'File witten to disk!',fullfile(pname,fname)},'Sucsess')
    disp(fullfile(pname,fname))
end
set(gcbf,'Pointer','arrow')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sucsess = exportcellcsv(pname,fname, header, OUT)
try
    F = fullfile(pname,fname);



    fid = fopen(F,'w');
    
    format = repmat('%s, ', 1, size(header,1));
    format = [format(1:end-2) '\n']; %replace last comma&space with new line character
    fprintf(fid,format, header{:,1});
    
    
    format = sprintf('%s, ', header{:,2});
    format = [format(1:end-2) '\n']; %replace last comma&space with new line character
    for k = 1:size(OUT,1)
        fprintf(fid, format, OUT{k,:});
    end
    fclose(fid);
    sucsess = 1;
catch
    sucsess = 0
    errordlg(lasterr,'Export error')
end
%%
function sucsess = exportxml(pname, fname, header, OUT)
global config
errordlg('This feature is not yet available. Sorry','XML error')
sucsess = 0;
return


try
    % Create a sample XML document.
    docNode = com.mathworks.xml.XMLUtils.createDocument...
        ('root_element');
    docRootNode = docNode.getDocumentElement;
    docNode.appendChild(docNode.createComment(['Results of Splitlab Project' config.project]));
    for i=1:size(header,1)
        columnName = header(i,1);

        columnName = strrep(columnName,'-','min_');
        columnName = strrep(columnName,'+','max_');
        columnName = strrep(columnName,'(','');
        columnName = strrep(columnName,')','');
        columnName = strrep(columnName,'?','');
        columnName = strrep(columnName,' ','_');
        thisElement = docNode.createElement(columnName);
        thisdefinition = docNode.createElementDefinition(columnName);
        docNode.createElementDefinition('ANDY')
        format     = header{i,2};
        val        = {OUT{:,i}};
        for k=1:length(val)
            entry = val{k};
            thisElement.appendChild(docNode.createTextNode(sprintf(format, entry)));
            docRootNode.appendChild(thisElement);
        end




    end
    docNode.appendChild(docNode.createComment('END OF FILE'));

    % Save the sample XML document.
    xmlFileName = fullfile(pname, fname);
    xmlwrite(xmlFileName,docNode);
    sucsess =1;
catch
    errordlg({'an Error occured during XML export',lasterr},'XML error')
    sucsess =0;
end


%% This program is part of SplitLab
% © 2006 Andreas Wüstefeld, Université de Montpellier, France
%
% DISCLAIMER:
%
% 1) TERMS OF USE
% SplitLab is provided "as is" and without any warranty. The author cannot be
% held responsible for anything that happens to you or your equipment. Use it
% at your own risk.
%
% 2) LICENSE:
% SplitLab is free software; you can redistribute it and/or modifyit under the
% terms of the GNU General Public License as published by the Free Software
% Foundation; either version 2 of the License, or(at your option) any later
% version.
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
% more details.