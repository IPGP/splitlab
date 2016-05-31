function c = list(searchstr)
% list files in directory and output as cell array
% same on each platform
% in contrast to Matlab build-in function DIR, list can handle the ?
% wildcard

qmark = findstr(searchstr, '?');
if isempty(qmark)
    %we can use the build-in function, which is faster
    d = dir(searchstr);
    c = {d.name}';
    c = c(~[d.isdir]);
else
    if ispc
        disp('')
        disp('Attention: File search on Windows is not case sentive!')
        disp('           Also, the "?" wildcard may act ambiguously.')
        disp('           Please use a maximum uniqueness for your search string')
        disp('')
        commandstr = ['dir ' searchstr ' /B /A-D']; %%all non-directories
    else
        % perhaps you have to locate the "ls" command on your machine
        % /usr/bin is the standart location
        commandstr = ['/usr/bin/ls '  searchstr ' -1 -A'];
    end
    [dummy, F] = system(commandstr);

    d = uint8(F);
    rows = find(d==10);% find newline character
    rows = [0 rows];
    % c = cell(length(rows), 1);
    c = {};

    path  = fileparts(searchstr);
    count = 1;
    for i=1:length(rows)-1
        m = rows(i)+1;   %start of line, without newline character
        n = rows(i+1)-1; %end   of line, without newline character
        file = F(m:n);
        if exist(fullfile(path, file), 'file') == 2
            c{count} = file;
            count    = count + 1;
        end
    end
end
