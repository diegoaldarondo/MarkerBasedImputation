function h5save(filepath, X, dset, varargin)
%H5SAVE Description
% Usage:
%   h5save(filepath, X)
%   h5save(filepath, X, dset)
% 
% Args:
%   filepath: path to HDF5 file
%   X: variable to save
%   dset: name or path to dataset (optional if variable name can be determined by inputname)
% 
% See also: h5write, h5att2struct, h5struct2att, inputname

if nargin < 3 || isempty(dset)
    dset = inputname(2);
    if isempty(dset)
        error('Dataset name must be specified if not saving a variable.')
    end
end

if dset(1) ~= '/'
    dset = ['/' dset];
end

h5create(filepath, dset, size(X), 'Datatype', class(X), varargin{:})
h5write(filepath, dset, X)

end
