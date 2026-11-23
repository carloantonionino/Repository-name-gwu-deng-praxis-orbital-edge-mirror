function se_report_error(ME, depth)
%SE_REPORT_ERROR  Print a MATLAB exception and every nested cause.
%
%   Simulink wraps several problems in one MException whose top level says
%   only "Error due to multiple causes". The real reasons sit in ME.cause,
%   sometimes nested several levels down. This walks the whole tree.

if nargin < 2
    depth = 0;
end
pad = repmat(' ', 1, 4 + depth * 4);

fprintf('%sMESSAGE   : %s\n', pad, cleanup(ME.message));
if ~isempty(ME.identifier)
    fprintf('%sIDENTIFIER: %s\n', pad, ME.identifier);
end

for i = 1:numel(ME.cause)
    fprintf('%s--- cause %d of %d ---\n', pad, i, numel(ME.cause));
    se_report_error(ME.cause{i}, depth + 1);
end
end

% ------------------------------------------------------------------------
function s = cleanup(s)
% Strip the HTML hyperlinks Simulink embeds in messages.
s = regexprep(s, '<a\s+href="[^"]*">', '');
s = strrep(s, '</a>', '');
s = strrep(s, sprintf('\n'), ' ');
end
