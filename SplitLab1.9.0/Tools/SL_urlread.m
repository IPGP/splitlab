function str = SL_urlread(address)
% Read URL and returns string with \n line ending, displaying waitbar

%% see:
%% http://www.mathworks.com/access/helpdesk/help/techdoc/index.html?/access/helpdesk/help/techdoc/matlab_external/f16555.html
if nargin==0
    address='http://www.ldeo.columbia.edu/~gcmt/projects/CMT/catalog/NEW_QUICK/qcmt.ndk';
end

h = waitbar(.0,'Getting file info');
url = java.net.URL(address);
conn = url.openConnection();
fsize = conn.getContentLength();
conn.getInputStream().close();
pause(.2)


waitbar(.02,h, 'Opening connection');
is = openStream(url);
pause(.2)
waitbar(.04,h, 'Prepare Stream')
isr = java.io.InputStreamReader(is);
pause(.2)
waitbar(.06,h, 'Prepare Buffer')
br = java.io.BufferedReader(isr);
pause(.2)

% Read and display lines of text.
% The final statements read the initial lines of HTML text from the site,
% displaying only the first 4 lines that contain meaningful text. Within
% the MATLAB for statements, the BufferedReader method readLine reads each
% line of text (terminated by a return and/or line feed character) from
% the site.

s=1;
l=0;
Bytes=0;
thisBytes=0;
p1=1;
waitbar(.08,h,'Reading data...')
str = repmat(char(0),1,fsize);
tic;
while ~isempty(s)
    l=l+1;
    s = readLine(br);
    p2=length(s) +p1;
    str(p1:p2)=[char(s) char(10)];
    p1=p2+1;
    
    Bytes = length(s) +Bytes;
    thisBytes = length(s) +thisBytes;
    if toc>0.2%mod(l,500)==0 || 
        dt=toc;
        
        speed = thisBytes/1024/dt;
        waitbar(Bytes/fsize,h,   sprintf('read %8.3f kB of data @ %8.2fkB/s', Bytes/1024 , speed ))
        tic;
        thisBytes=0;
        pause(.1)
    end
    
    
end
str(p1-1:end)=[];
waitbar(1,h,sprintf(' %4d lines read, %.3f kB of data',l, Bytes/1024))
pause(1.5)
close(h);
