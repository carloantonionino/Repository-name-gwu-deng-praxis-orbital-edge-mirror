function S = des_read_keyvalue(fname)
%DES_READ_KEYVALUE  Read a two column CSV of name,value into a struct.

fid = fopen(fname, 'r');
if fid < 0
    error('des:file', 'Cannot open %s. Keep the data folder beside the code.', fname);
end
fgetl(fid);
C = textscan(fid, '%s%f', 'Delimiter', ',');
fclose(fid);
keys = C{1};
vals = C{2};
S = struct();
for i = 1:numel(keys)
    S.(strtrim(keys{i})) = vals(i);
end
end
