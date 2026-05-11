function h = xlinemulti(x, varargin)
% xlinemulti  Draw vertical lines at multiple x positions.
% Usage: xlinemulti(x)
%        xlinemulti(x, label)
%        xlinemulti(x, label, Name, Value, ...)
%        h = xlinemulti(...)

x = x(:)';
h = gobjects(1, numel(x));
for i = 1:numel(x)
    h(i) = xline(x(i), varargin{:});
end
end
