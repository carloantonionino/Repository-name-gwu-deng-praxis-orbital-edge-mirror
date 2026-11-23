classdef LatencyRecorderEdge < matlab.DiscreteEventSystem
%LATENCYRECORDEREDGE  Record end to end latency on the edge path.
%
%   Sits immediately before the Entity Terminator. When an entity arrives it
%   reads the simulation clock, subtracts the arrival time the entity has
%   carried since generation, and hands the result to se_log.
%
%   There is a separate class per path because the MATLAB Discrete-Event
%   System block accepts a bare class name only, not constructor arguments.

    properties (Nontunable)
        % One entity at a time.
        Capacity = 1
    end

    methods (Access = protected)

        function entityTypes = getEntityTypesImpl(obj)
            entityTypes = obj.entityType('AceObs');
        end

        function [inTypes, outTypes] = getEntityPortsImpl(~)
            inTypes  = {'AceObs'};
            outTypes = {'AceObs'};
        end

        function [storageSpecs, I, O] = getEntityStorageImpl(obj)
            storageSpecs = obj.queueFIFO('AceObs', obj.Capacity);
            I = 1;
            O = 1;
        end

        function num = getNumInputsImpl(~)
            % One entity input port. Entity ports count here, and this must
            % match the size of the input connection from getEntityStorageImpl.
            num = 1;
        end

        function num = getNumOutputsImpl(~)
            % One entity output port.
            num = 1;
        end

        function [entity, events] = AceObsEntry(obj, ~, entity, ~)
            coder.extrinsic('se_log');
            entity.data.latency = obj.getCurrentTime() - entity.data.arrTime;
            se_log('add', 'edge', entity.data.latency);
            events = obj.eventForward('output', 1, 0);
        end

    end

    methods (Static, Access = protected)

        function simMode = getSimulateUsingImpl()
            % Block actions are normally compiled with MATLAB Coder, which
            % forbids calls out to ordinary functions. Interpreted execution
            % keeps full MATLAB available inside this block.
            simMode = 'Interpreted execution';
        end

        function flag = showSimulateUsingImpl()
            flag = false;
        end

    end

end
