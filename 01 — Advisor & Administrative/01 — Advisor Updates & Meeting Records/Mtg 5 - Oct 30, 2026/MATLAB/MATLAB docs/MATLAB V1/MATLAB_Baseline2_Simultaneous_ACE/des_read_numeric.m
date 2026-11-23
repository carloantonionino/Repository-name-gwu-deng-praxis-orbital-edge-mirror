function M = des_read_numeric(fname, ncols)
%DES_READ_NUMERIC  Read a header line plus all-numeric rows from a CSV file.
%   Deliberately uses textscan so it behaves the same on every MATLAB release.

fid = fopen(fname, 'r');
if fid < 0
    error('des:file', 'Cannot open %s. Keep the data folder beside the code.', fname);
end
fgetl(fid);                                  % discard the header line
C = textscan(fid, repmat('%f', 1, ncols), 'Delimiter', ',', ...
             'CollectOutput', true, 'EmptyValue', NaN);
fclose(fid);
M = C{1};
if isempty(M)
    error('des:file', 'No data rows found in %s.', fname);
end
end
