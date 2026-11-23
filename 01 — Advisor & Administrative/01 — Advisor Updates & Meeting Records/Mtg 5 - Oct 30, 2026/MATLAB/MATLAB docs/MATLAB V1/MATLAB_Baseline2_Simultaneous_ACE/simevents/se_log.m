function out = se_log(action, pathName, value)
%SE_LOG  Collect per entity results during a SimEvents run.
%
%   se_log('reset')                     clear everything before a run
%   se_log('add', 'ground', 12.5)       record one latency, called by the model
%   v = se_log('get', 'ground')         read the recorded vector after a run
%   se_log('report')                    print a short summary
%
%   A persistent store is used rather than the base workspace because block
%   actions run inside the simulation and cannot reliably assign outward.

persistent G E

if isempty(G)
    G = [];
end
if isempty(E)
    E = [];
end

out = [];

switch lower(action)

    case 'reset'
        G = [];
        E = [];

    case 'add'
        if strcmpi(pathName, 'ground')
            G(end+1, 1) = value; %#ok<AGROW>
        else
            E(end+1, 1) = value; %#ok<AGROW>
        end

    case 'get'
        if strcmpi(pathName, 'ground')
            out = G;
        else
            out = E;
        end

    case 'report'
        fprintf('\n  Recorded ground entities: %d\n', numel(G));
        fprintf('  Recorded edge entities  : %d\n', numel(E));
        if ~isempty(G)
            fprintf('  Ground mean latency     : %.4f s\n', mean(G));
        end
        if ~isempty(E)
            fprintf('  Edge mean latency       : %.4f s\n', mean(E));
        end
        fprintf('\n');

    otherwise
        error('se_log:action', ...
            'Unknown action "%s". Use reset, add, get or report.', action);
end
end
