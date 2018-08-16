classdef SdClass  < matlab.mixin.Copyable
    
    properties
        lambda
        lambdaEmission
        srcPos
        detPos
        frequency
        timeDelay
        timeDelayWidth
        momentOrder
        correlationTimeDelay
        correlationTimeDelayWidth
        srcLabels
        detLabels
    end
    
    
    methods
        
        % -------------------------------------------------------
        function obj = SdClass(SD)
            
            if nargin>0
                obj.lambda = SD.Lambda;
                obj.lambdaEmission  = [];
                obj.srcPos  = SD.SrcPos;
                obj.detPos  = SD.DetPos;
                obj.frequency  = 1;
                obj.timeDelay  = 0;
                obj.timeDelayWidth  = 0;
                obj.momentOrder = [];
                obj.correlationTimeDelay = 0;
                obj.correlationTimeDelayWidth = 0;
                for ii=1:size(SD.SrcPos)
                    obj.srcLabels{ii} = ['S',num2str(ii)];
                end
                for ii=1:size(SD.DetPos)
                    obj.detLabels{ii} = ['D',num2str(ii)];
                end
            else
                obj.lambda          = [];
                obj.lambdaEmission  = [];
                obj.srcPos  = [];
                obj.detPos  = [];
                obj.frequency  = 1;
                obj.timeDelay  = 0;
                obj.timeDelayWidth  = 0;
                obj.momentOrder = [];
                obj.correlationTimeDelay = 0;
                obj.correlationTimeDelayWidth = 0;
                obj.srcLabels = {};
                obj.detLabels = {};
            end

        end

        % -------------------------------------------------------
        function obj = Load(obj, fname, parent)
            
            if ~exist(fname, 'file')
                return;
            end
              
            obj.lambda                    = hdf5read_safe(fname, [parent, '/lambda'], obj.lambda);
            obj.lambdaEmission            = hdf5read_safe(fname, [parent, '/lambdaEmission'], obj.lambdaEmission);
            obj.srcPos                    = hdf5read_safe(fname, [parent, '/srcPos'], obj.srcPos);
            obj.detPos                    = hdf5read_safe(fname, [parent, '/detPos'], obj.detPos);
            obj.frequency                 = hdf5read(fname, [parent, '/frequency']);
            obj.timeDelay                 = hdf5read(fname, [parent, '/timeDelay']);
            obj.timeDelayWidth            = hdf5read(fname, [parent, '/timeDelayWidth']);
            obj.momentOrder               = hdf5read_safe(fname, [parent, '/momentOrder'], obj.momentOrder);
            obj.correlationTimeDelay      = hdf5read(fname, [parent, '/correlationTimeDelay']);
            obj.correlationTimeDelayWidth = hdf5read(fname, [parent, '/correlationTimeDelayWidth']);
            obj.srcLabels                 = deblank(h5read_safe(fname, [parent, '/srcLabels'], obj.srcLabels));
            obj.detLabels                 = deblank(h5read_safe(fname, [parent, '/detLabels'], obj.detLabels));
            
        end

        
        % -------------------------------------------------------
        function Save(obj, fname, parent)
            
            if ~exist(fname, 'file')
                fid = H5F.create(fname, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
                H5F.close(fid);
            end     
            
            hdf5write_safe(fname, [parent, '/lambda'], obj.lambda);
            hdf5write_safe(fname, [parent, '/lambdaEmission'], obj.lambdaEmission);
            hdf5write_safe(fname, [parent, '/srcPos'], obj.srcPos);
            hdf5write_safe(fname, [parent, '/detPos'], obj.detPos);
            hdf5write(fname, [parent, '/frequency'], obj.frequency, 'WriteMode','append');
            hdf5write(fname, [parent, '/timeDelay'], obj.timeDelay, 'WriteMode','append');
            hdf5write(fname, [parent, '/timeDelayWidth'], obj.timeDelayWidth, 'WriteMode','append');
            hdf5write_safe(fname, [parent, '/momentOrder'], obj.momentOrder);
            hdf5write(fname, [parent, '/correlationTimeDelay'], obj.correlationTimeDelay, 'WriteMode','append');
            hdf5write(fname, [parent, '/correlationTimeDelayWidth'], obj.correlationTimeDelayWidth, 'WriteMode','append');
            hdf5write_safe(fname, [parent, '/srcLabels'], obj.srcLabels);
            hdf5write_safe(fname, [parent, '/detLabels'], obj.detLabels);
                        
        end
        
    end
    
end