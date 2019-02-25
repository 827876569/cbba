close all; clear; clc;

for i=1:10
    tasks(i) = Task(i, 1, [i i]', 100, 0.1);
end

NuLt = 0;

tasks(1).x = [11 11]';
tasks(2).id = 20;

agents(1) = Agent(1, 100, [1 2], 1, [0 0]');
agents(2) = Agent(2, 100, [1 2], 1, [13 13]');
agents(3) = Agent(3, 100, [1 2], 1, [5 5]');

A = zeros(length(agents));

for i=1:length(agents)
    agents(i).add_task(tasks);
    NuLt = NuLt + agents(i).Lt;
    
    % Adjacency Matrix Generation
    for k=(i+1):length(agents)
        if (norm(agents(k).x - agents(i).x) <= 15)
            agents(i).s(k) = 0;
            agents(k).s(i) = 0;
            A(i,k) = 1;
            A(k,i) = 1;
        else
            A(i,k) = 0;
            A(k,i) = 0;
        end
    end
end

dt = 0.1;
Tb = 10;

for t=0:dt:Tb

    fprintf('T = %.1f \t=======================================>>\n', t);
    for i=1:length(agents)
        nmin = min(length(tasks),NuLt);
        
        agents(i).bundle(t, nmin);
        for k=1:length(agents)
            if (A(i,k) == 1)
                agents(i).auction(agents(k).id, agents(k).y, agents(k).z, agents(k).s, t);
            end
        end
        
        
        fprintf('Agent-%d:', i);
        for j=1:length(agents(i).p)
            fprintf('\t%d', agents(i).p(j));
        end
        fprintf('\n');
    end
    
    fprintf('\n');
    pause(dt);
end

