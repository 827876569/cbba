classdef Agent < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id
        x       % Position of Agent         - Double[2]
        v       % Velocity of Agent         - Double[2]
        v_max   % Maximum Speed             - Double
        b       % Path (Historical)         - Int[]
        p       % Path (Ordered)            - Int[]
        y       % Winning Bid List
        z       % Winning Agent List
        s       % Update time vector
        
        b_cap   % Capable Task Type List    - Int[]
        Lt      % Maximum Number of Path    - Int
        
        sp

        
        tasks   % Task lists                - Task[]
        tasks_id
    end
    
    methods
        function this = Agent(id, Lt, b_cap, v_max, x, v)
            if (nargin == 5)
                v = [0 0]';
            end
            
            this.id = id;
            this.Lt = Lt;
            this.b_cap = b_cap;
            this.v_max = v_max;
            this.x = x;
            this.v = v;
            
            this.b = [];
            this.p = [];
            this.y = [];
            this.z = [];
            this.sp = 0;
            this.s = [];
            
            this.tasks = [];
            this.tasks_id = [];
        end
        
        function arr = perm(this, j_id)
            arr = zeros(length(this.p));
            if (nargin == 2)
                for m=1:(length(this.p)+1)
                    i = 1;
                    for n=1:(length(this.p)+1)
                        if m==n
                            arr(m,n) = j_id;
                        else
                            arr(m,n) = this.p(i);
                            i = i+1;
                        end
                    end
                end
            end
        end
        
        function val = tj(this, pn)
            %Task.find_by_id(this.tasks, pn(1))
            task_i = Task.find_by_id(this.tasks, pn(1));
            val = norm(task_i.x - this.x) ./ this.v_max;
            for i = 2:length(pn)
                task_j = Task.find_by_id(this.tasks, pn(i));
                val = val + (norm(task_j.x - task_i.x) ./ this.v_max);
                task_i = task_j;
            end
        end
        
        function val = nmin(this)
            val = 0;
            for i=1:length(this.tasks)
                if (this.z ~= 0)
                    val = val + 1;
                end
            end
        end
        
        function bundle(this, tau, nmin)
            
            % TODO: Change with Nmin conditionals
            if (length(this.b) < this.Lt)
                if (this.nmin() >= nmin)
                   return
                end
                this.sp = 0;
                pjn = [];
                for m = 1:length(this.p)
                    pjn = [pjn this.p(m)];
                    %Task.find_by_id(this.tasks, this.p(m))
                    task_m = Task.find_by_id(this.tasks, this.p(m));
                    this.sp = this.sp + task_m.score(tau + this.tj(pjn));
                end
                
                spj = zeros(1,length(this.tasks));
                pj = [];
                
                for j = 1:length(this.tasks)
                    j_id = this.tasks(j).id;
                    
                    is_duplicate = 0;
                    for m = 1:length(this.p)
                        if (this.p(m) == j_id)
                            is_duplicate = 1;
                        end
                    end
                    
                    if (is_duplicate == 1)
                        spj(j) = 0;
                        pj(j,:) = [this.p j_id];
                    else
                        pj_perm = this.perm(j_id);
                        spjn = zeros(1, size(pj_perm,1));

                        for m = 1:size(pj_perm,1)
                            pjn = [];

                            for n = 1:size(pj_perm,2)
                                pjn = [pjn pj_perm(m,n)];
                                %Task.find_by_id(this.tasks, pj_perm(m,n))
                                task_n = Task.find_by_id(this.tasks, pj_perm(m,n));
                                spjn(m) = spjn(m) + task_n.score(tau + this.tj(pjn));
                            end
                        end

                        [spj(j), n_pj] = max(spjn);
                        pj(j,:) = pj_perm(n_pj,:);
                    end
                end
                
                cij = spj - this.sp;
                hij = (cij > this.y);
                [max_cij, Ji] = max(cij .* hij);
                
                if (max_cij > 0)
                    this.b = [this.b this.tasks(Ji).id];
                    this.p = pj(Ji,:);

                    this.y(Ji) = cij(Ji);
                    this.z(Ji) = this.id;
                end
            end
        end
        
        function auction(this, idk, yk, zk, sk, tau)
            this.s(idk) = tau;
            
            idi = this.id;
            yi = this.y;
            zi = this.z;
            si = this.s;
            
            % TODO validasi ukuran yk
            for j = 1:length(this.tasks)
                j_id = this.tasks(j).id;
                %fprintf('[%d:%d%d]',j_id,zk(j),zi(j));
                
                switch (zk(j))
                    case idk
                        switch (zi(j))
                            case idi
                                if (yk(j) > yi(j))
                                    % UPDATE
                                    this.y(j) = yk(j);
                                    this.z(j) = zk(j);
                                    this.release(j_id);
                                end
                            case idk
                                % UPDATE
                                this.y(j) = yk(j);
                                this.z(j) = zk(j);
                                this.release(j_id);
                            case 0
                                % UPDATE
                                this.y(j) = yk(j);
                                this.z(j) = zk(j);
                                this.release(j_id);
                            otherwise
                                idm = zi(j);
                                if ((sk(idm) > si(idm)) || (yk(j) > yi(j)))
                                    % UPDATE
                                    this.y(j) = yk(j);
                                    this.z(j) = zk(j);
                                    this.release(j_id);
                                end
                        end
                    case idi
                        switch (zi(j))
                            case idi
                                % LEAVE
                            case idk
                                % RESET
                                this.y(j) = 0;
                                this.z(j) = 0;
                                this.release(j_id);
                            case 0
                                % LEAVE
                            otherwise
                                idm = zi(j);
                                if (sk(idm) > si(idm))
                                    % RESET
                                    this.y(j) = 0;
                                    this.z(j) = 0;
                                    this.release(j_id);
                                end
                        end
                    case 0
                        switch (zi(j))
                            case idi
                                % LEAVE
                            case idk
                                % UPDATE
                                this.y(j) = yk(j);
                                this.z(j) = zk(j);
                                this.release(j_id);
                            case 0
                                % LEAVE
                            otherwise
                                idm = zi(j);
                                if (sk(idm) > si(idm))
                                    % UPDATE
                                    this.y(j) = yk(j);
                                    this.z(j) = zk(j);
                                    this.release(j_id);
                                end
                        end
                    otherwise
                        idm = zk(j);
                        
                        switch (zi(j))
                            case idi
                                if ((sk(idm) > si(idm)) && (yk(j) > yi(j)))
                                    % UPDATE
                                    this.y(j) = yk(j);
                                    this.z(j) = zk(j);
                                    this.release(j_id);
                                end
                            case idk
                                if (sk(idm) > si(idm))
                                    % UPDATE
                                    this.y(j) = yk(j);
                                    this.z(j) = zk(j);
                                    this.release(j_id);
                                else
                                    % RESET
                                    this.y(j) = 0;
                                    this.z(j) = 0;
                                    this.release(j_id);
                                end
                            case idm
                                if (sk(idm) > si(idm))
                                    % UPDATE
                                    this.y(j) = yk(j);
                                    this.z(j) = zk(j);
                                    this.release(j_id);
                                end
                            case 0
                                if (sk(idm) > si(idm))
                                    % UPDATE
                                    this.y(j) = yk(j);
                                    this.z(j) = zk(j);
                                    this.release(j_id);
                                end
                            otherwise
                                idn = zi(j);
                                if ((sk(idm) > si(idm)) && (sk(idn) > si(idn)))
                                    % UPDATE
                                    this.y(j) = yk(j);
                                    this.z(j) = zk(j);
                                    this.release(j_id);
                                end
                                if ((sk(idm) > si(idm)) && (yk(j) > yi(j)))
                                    % UPDATE
                                    this.y(j) = yk(j);
                                    this.z(j) = zk(j);
                                    this.release(j_id);
                                end
                                if ((sk(idn) > si(idn)) && (si(idm) > sk(idm)))
                                    % RESET
                                    this.y(j) = 0;
                                    this.z(j) = 0;
                                    this.release(j_id);
                                end
                        end
                end
            end
        end
        
        function release(this, j_id)
%             [~, j] = Task.find_by_id(this.tasks, j_id);
%             this.y(j) = 0;
%             this.z(j) = 0;
            for i=1:length(this.b)
                if (this.b(i) == j_id)
                    this.b(i) = [];
                    break
                end
            end
            for i=1:length(this.p)
                if (this.p(i) == j_id)
                    this.p(i) = [];
                    break
                end
            end
        end
        
        function add_task(this, tasks)
            this.tasks = [this.tasks tasks];
            for i=(length(this.y) + 1):length(this.tasks)
                this.y(i) = 0;
                this.z(i) = 0;
                this.tasks_id(i) = tasks(i).id;
            end
        end
        
    end
    
end

