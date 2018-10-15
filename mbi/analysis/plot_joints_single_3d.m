function h = plot_joints_single_3d(ax,pts,segments, markerSize, lineWidth)

if isfield(segments,'segments'); segments = segments.segments; end
if nargin < 4 || isempty(markerSize); markerSize = 20; end
if nargin < 5 || isempty(lineWidth); lineWidth = 2; end
x = 1:3:size(pts,2);
y = 2:3:size(pts,2);
z = 3:3:size(pts,2);
h = gobjects(numel(segments.joints_idx),1);
for i = 1:numel(segments.joints_idx)
    ids = segments.joints_idx{i};
    xpts = pts(:,x(ids));
    ypts = pts(:,y(ids));
    zpts = pts(:,z(ids));
    h(i) = plot3(ax, xpts,ypts,zpts,'.-', ...
        'Color',segments.color{i},'MarkerSize',markerSize,'LineWidth',lineWidth);
    
%     plotpts(pts(segments.joints_idx{i},:),'.-', ...
%         'Color',segments.color{i},'MarkerSize',markerSize,'LineWidth',lineWidth);
%     h(i) = plotpts(pts(segments.joints_idx{i},:),'.-', ...
%         'Color',segments.color{i},'MarkerSize',markerSize,'LineWidth',lineWidth);
end

if nargout < 1; clear h; end
end