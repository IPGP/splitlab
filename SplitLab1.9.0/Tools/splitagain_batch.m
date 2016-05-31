function splitagain_batch

d = dir('*.pjt');

for i=1:length(d)
    load(d(i).name,'-mat');
    fprintf('\nWorking on file: %s...\n',d(i).name)
    splitagain
end
