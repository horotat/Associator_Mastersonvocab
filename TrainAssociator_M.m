% Trains the Associator for 1 epoch 
% Each epoch includes only one type of training (S, P, R or L)
% Updates the weights after each sweep (after training with each word)

function W = TrainAssociator_M(L, W, P, D, epoch) 

mode = P.modes(epoch);
sequence = 1:size(D.trainingsems,1);
if isnan(D.tr_prob(1)) == 0
    randomsample = rand(1, size(D.trainingsems,1));
    for i = 1:numel(randomsample)
        x = find(D.tr_prob>= randomsample(i));
        sequence(i) = x(1);
    end        
end

%% Mode S->S (S)

if strcmp(mode, 'S')

    for sweep = sequence

        % Activations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        input_sem = D.trainingsems(sweep,:);        
        L = ActivateAssociator(L, W, P, 'S', input_sem);

        % Back-propagation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Calculate delta
        
        target_SO = input_sem;
        L(3).delta = P.delta(L(3).state, target_SO, 'output', P.temperatures(1), P.offset); % SO
        L(2).delta = P.delta([L(2).state, P.bias], L(3).delta, W(2).state, P.temperatures(1), P.offset); % SH

        % Apply weight change

        for i = 1:2
            W(i).momentumterm = P.momentums(1) * W(i).change;
        end
        W(2).change = incr(P.learningrates(1), [L(2).state, P.bias], L(3).delta) + W(2).momentumterm; % SHSO
        W(1).change = incr(P.learningrates(1), [L(1).state, P.bias], L(2).delta(1:end-P.usebias)) + W(1).momentumterm; % SISH
        for i = 1:2
            W(i).state = W(i).state + W(i).change*D.wc_modulator(sweep); % Update weights
        end

        % Annul nonexistent connections
        
        for i = 1:2
            W(i).state(W(i).eliminated) = 0;
        end

    end 
    
end

%% Mode P->P (P)

if strcmp(mode, 'P')

    for sweep = sequence

        % Activations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        input_phon = D.trainingphons(sweep,:);
        L = ActivateAssociator(L, W, P, 'P', input_phon);
        
        % Back-propagation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Calculate delta
        
        target_PO  = input_phon;
        L(6).delta = P.delta(L(6).state, target_PO, 'output', P.temperatures(2), P.offset); % PO
        L(5).delta = P.delta([L(5).state, P.bias], L(6).delta, W(4).state, P.temperatures(2), P.offset); % PH

        % Apply weight change

        for i = 3:4
            W(i).momentumterm = P.momentums(2) * W(i).change;
        end
        W(4).change = incr(P.learningrates(2), [L(5).state, P.bias], L(6).delta) + W(4).momentumterm; % PHPO
        W(3).change = incr(P.learningrates(2), [L(4).state, P.bias], L(5).delta(1:end-P.usebias)) + W(3).momentumterm; % PIPH
        for i = 3:4
            W(i).state = W(i).state + W(i).change*D.wc_modulator(sweep); % Update weights
        end

        % Annul nonexistent connections
        
        for i = 3:4
            W(i).state(W(i).eliminated) = 0;
        end

    end 
    
end

%% Mode S->P (R)

if strcmp(mode, 'R')

    for sweep = sequence

        % Activations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        input_sem = D.trainingsems(sweep,:);
        L = ActivateAssociator(L, W, P, 'R', input_sem);  
            
        % Back-propagation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Calculate delta
        
        input_phon = D.trainingphons(sweep,:);
        target_PH = P.transferfn([input_phon, P.bias] * W(3).state, P.temperatures(2), P.offset); % PH
        
        L(5).delta = P.delta(L(5).state, target_PH, 'output', P.temperatures(3), P.offset); % PH
        L(7).delta = P.delta([L(7).state, P.bias], L(5).delta, W(6).state, P.temperatures(3), P.offset); % AR

        % Apply weight change

        for i = 5:6
            W(i).momentumterm = P.momentums(3) * W(i).change;
        end
        W(6).change = incr(P.learningrates(3), [L(7).state, P.bias], L(5).delta) + W(6).momentumterm; % ARPH
        W(5).change = incr(P.learningrates(3), [L(2).state, P.bias], L(7).delta(1:end-P.usebias)) + W(5).momentumterm; % SHAR
        for i = 5:6
            W(i).state = W(i).state + W(i).change*D.wc_modulator(sweep); % Update weights
        end

        % Annul nonexistent connections
        
        for i = 5:6
            W(i).state(W(i).eliminated) = 0;
        end

    end 
    
end

%% Mode P->S (L)

if strcmp(mode, 'L')

    for sweep = sequence

        % Activations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        input_phon = D.trainingphons(sweep,:);
        L = ActivateAssociator(L, W, P, 'L', input_phon);         

        % Back-propagation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Calculate delta

        input_sem = D.trainingsems(sweep,:);  
        target_SH = P.transferfn([input_sem, P.bias] * W(1).state, P.temperatures(1), P.offset); % SH
        
        L(2).delta = P.delta(L(2).state, target_SH, 'output', P.temperatures(4), P.offset); % SH
        L(8).delta = P.delta([L(8).state, P.bias], L(2).delta, W(8).state, P.temperatures(4), P.offset); % AR

        % Apply weight change

        for i = 7:8
            W(i).momentumterm = P.momentums(4) * W(i).change;
        end
        W(8).change = incr(P.learningrates(4), [L(8).state, P.bias], L(2).delta) + W(8).momentumterm; % PHAL
        W(7).change = incr(P.learningrates(4), [L(5).state, P.bias], L(8).delta(1:end-P.usebias)) + W(7).momentumterm; % ALSH
        for i = 7:8
            W(i).state = W(i).state + W(i).change*D.wc_modulator(sweep); % Update weights
        end

        % Annul nonexistent connections
        
        for i = 7:8
            W(i).state(W(i).eliminated) = 0;
        end

    end 

end
