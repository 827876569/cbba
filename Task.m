classdef Task < handle
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id
        type
        x
        Rj
        lambda
    end
    
    methods(Static)
        function [obj, n_obj] = find_by_id(tasks, id)
            for i = 1:length(tasks)
                if (tasks(i).id == id)
                    obj = tasks(i);
                    n_obj = i;
                    break
                end
            end
        end
    end
    
    methods
        
        % Constructor Method
        function this = Task(id, type, x, Rj, lambda)
            if (nargin == 3)
                lambda = 0.5;
            end
            
            this.id = id;
            this.type = type;
            this.x = x;
            this.Rj = Rj;
            this.lambda = lambda;
        end
        
        % Score Calculation Method
        function val = score(this, dt)
            val = this.Rj*exp(-this.lambda*(dt));
        end
    end
    
end

