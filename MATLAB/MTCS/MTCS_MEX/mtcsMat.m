function [weights,ML, L0] = mtcsMat(PHI,v,a,b,eta,maxiter)
% MTCS Multi-Task Compressive Sensing
%
% Syntax:
%   [weights,ML, L0] = mtcs(PHI,v,a,b,eta)
%
% Input:
%   PHI:        Projection matrix. Cell structure, One cell for one task.
%   v:          CS measurements. Cell structure, One cell for one task.
%   a,b:        Parameters of Gamma prior on noise variance
%   eta:        Threshold for stopping the algorithm (default: 1e-8)
%   maxiter:    Maximum number of iteration (default: 10000)
% Output:
%   weights:    Sparse weights for all the tasks. One column for one task
%   ML:         The increase of the log joint mariginal likelihood for each
%               iteration 
%   L0:         Inital marginal log likelihood
%
% References:
%   Shihao Ji, David Dunson and Lawrence Carin, "Multi-Task Compressive
%   Sesning" (Preprint, 2007). 
%
%   The algorithm is an extension of the fast RVM algorithm [Tipping &
%   Faul, 2003] in two-fold: 
%   (i)  the noise variance is marginalized and 
%   (ii) it is for multi-task CS, with single-task CS as a special case
%
% Version 1.0: Real Data
% Version 2.0: Real and Complex Data
% Version 3.0: Multiple Observations
%              More efficient implementation by using BSXFUN (BSXOPS) 
%              instead of REPMAT
% 
% Wan Chunru
% 
% 2015-11-18

% debugmode for displaying debug info
% debugmode>=1  :        basic information
% debugmode>=10 :        detailed information
debugmode=0;             

if nargin<5, eta=1e-8; end
if nargin<6, maxiter=10000; end

%% General Notes
% 
% This function extensively use the bsxfun (through bsxops) for simplicity
% and efficiency of coding .
%
% We use multidimensional/cell arrays in MTCS extensively.
%
% The following Multidimensional arrays are used and bsxfun (bsxops) are
% used for singleton expansion of the mD arrays.
%
%                   j,    l,    i
% S/s/PHI2          m  x  1  x  NT
% Q/q/PHIv          m  x  L  x  NT
% G                 1  x  L  x  NT
% g                 m  x  L  x  NT
% Ki                1  x  1  x  NT
%
% The following are organized as cell array
%                               {i}
% Sigma             mt x  mt x  NT
% mu                mt x  L  x  NT
%
% v                 ni x  L  x  NT
% PHI               ni x  m  x  NT
%
% General notes on the use of index variable
%
% (1) The index $ i \in \{1, 2, \cdots, NT \}$ ranges over all tasks
% (2) The index $ l \in \{1, 2, \cdots, L  \}$ ranges over all observations
% (3) The index $ j \in \{1, 2, \cdots, m  \}$ is used to index the single
%     basis function for which $\alpha_j$ is to be updated
% (4) The index $ k \in \{1, 2, \cdots, m_t\}$ denotes the index within the
%     current bases that corresponds to j
% (5) The index $ n \in \{1, 2, \cdots, m  \}$ ranges over all basis
%     functions, including those not currently utilized in the mode. [This
%     is the index $l$ in the original reference.
%
% A coefficeient that has different values for real and complex tasks:
%   Real:       cTask=false;        rc=2;
%   Complex:    cTask=true;         rc=1;

bsxops(1);      % turn on bsxops

%% Find the number of targets (number of cells of the observation data)
% 
% Eq(1):
% $$v_i = \PHI_i \theta_i + \nu_i, i=1,\cdots, M $$
% 
% The dimeionsios of variables: 
% $$v_i: n_i \times 1;  \Phi_i: n_i \times m;  \nu_i: n_i \times 1 $$

% v and PHI correspond to $v_i$ and \Phi_i$ in Eq(1)
% NT corresponds to $M$ in Eq(1)
if iscell(v)
    % Single/multiple targets for cell array of $v$
    % If $v$ is cell structure,  each cell element is for one task
    NT = length(v);         % number of targets (M in the paper)
else
    % Single target for array input of $v$
    % Convert the array into cell
    NT = 1;                 % single target
    PHI = {PHI};            % convert to cell to be a special case of 
    v = {v};                % multi-task CS problem
end

if debugmode
    fprintf(1,'This is a %d-task learning.\n',NT);
end


%% Find the size of each individual task and ensure the compatibility
%
% In the same time, we also find if the problem is Real or Complex

% Size of CS projection matrices and observation matrices
% $\Phi_i:  n_i \times m$, for $i=1, \cdots, m$    [Ni x Mi ]
% $\v_i:    n_i \times l$, for $i=1, \cdots, m$    [Ni x L  ]
Ni=zeros(NT, 1);                % n_i, i=1, ..., M 
Mi=zeros(NT, 1);                % m_i, i=1, ..., M 
Nv=zeros(NT, 1);                % n_i, i=1, ..., M 
Mv=zeros(NT, 1);                % l_i, i=1, ..., M 

% Real of Complex: (cTask)
% cTask:    false:  Real
%           true:   Complex
cTask=false;                 

for i = 1:NT                    % loop over tasks
    % size of the projection matrix (or dictionary) for each task
    [Ni(i),Mi(i)] = size(PHI{i});       % $\Phi_i: n_i \times m_i $
    % size of the observation matrix v: $n_i \times L$
    % L--> Nob
    [Nv(i), Mv(i)] = size(v{i});            % $v_i:    n_i \times L $
    
    % it will be a cTask if any PHI or v is not real
    cTask=cTask || ~isreal(PHI{i}) || ~isreal(v{i});
end

if debugmode
    if cTask
        fprintf(1,'This is a Complex learning.\n');
    else
        fprintf(1,'This is a Real learning.\n');
    end
end

% Ensure that $Phi_i$ are compatiable for multi-tasks
% $\Phi_i$:  $ n_i \times m $
m=Mi(1);                     % m is the length of the weight vector
if any( Mi ~= m )
    error('The sizes of the underlying signals should be the same!\n');
end

% Ensure that $v_i$ are compatiable for multi-observations
Nob=Mv(1);                     % Nob: number of observation (L)
if any( Mv ~= Nob )
    error('The number of observations for each task should be the same!\n');
end

% Ensure that $\Phi{i}$ and $v_i$ are compatiable 
if any( Nv ~= Ni )
    error('The observaion and projection matrices should be compatible!\n');
end

if debugmode>=10
    fprintf('m=%d,  NT=%d,  Nob=%d\n', m, NT, Nob);
end

%% Initialize 
% Initially, there is no basis function has been selected. We denote the
% current selected bases as $\bar_{Phi})i$.  In the reference paper, there
% is a confusion of using $\Phi_i$ for all the bases or for selected bases.
%
% Notation: We will use variables PhiB, alphaB for the already selected
% bases (B) and hyperparameters in Matlab code. We will use alphaC to
% indicated the candataes (C) for selection.
%
% Special note for empty selected base:
% If the selected basis is empty, it means: 
%   $\bar_{Phi})i$ is empty, or PhiB=[];
% It can be equivalently indicated by 
%   $\alpha_j=\infty, \mbox{for }j=1, \cdots, m$
%   or alphaB=[];
%
% With no basis selected, we have from Eq(32) that
% $$ B_i = I + \Phi_i A^{-1} \Phi_i^H = I $$
% $$ \Sigma_i = (\Phi_i^H \Phi_i + A)^{-1} = 0  $$ 
%
% Now we consider to select the first basis function.  This is based on the
% increament to the objective function in Eq(37) if a candidate basis
% $\alpha_j$ is selected. Therefore, we have to evaluate the
% $\ell(\alpha_j)$ in eq(37).

% Adding a new basis will change the likelihood.  We will find out which
% basis added will cause largest increase of the likelihood.  So that we
% can select an initial alpha.

% Coefficient for real or complex (rc) tasks  
if ~cTask
    rc=2;      % real
else
    rc=1;       % complex
end

% Define variable Ki 
%   Real:       $ K_i=n_i+2*a $,   
%   Complex:    $ K_i=n_i+a   $
Kivec =  Ni+rc*a;            % vector version
Ki=zeros(1, 1, NT);                 % 1 x 1 x NT (mD array)
Ki(1,1,:) = Kivec;                  % mD array (for bsxfun)

% Evaluate some quantities for later use This is for all bases (regardless
% of being selected or not) and tasks (specified by PHI), see Eq(38). 
% 
% Singleton dimension is allowed as we will use BSXFUN (BSXOPS) instead of
% REPMAT
PHI2=zeros(m, 1, NT);       % PHI2(i,j) = PHI{i}(:,j)' * PHI{i}(:,j)
PHIv=zeros(m, Nob, NT);     % PHIv(i,j,l) = PHI{i}(:,j)' * v{i}(:,l)
G=zeros(1, Nob, NT);        % G(i,l) = v{i}(:,l)' * v{i}(:,l) + rc*b

for i = 1:NT
    % Eq(43) with $B_i^{-1}=I$ before any basis is included
    % For all basis functions (including those not used in current model)
    
    % PHI2(i, j) = PHI{i}(:,j)' * PHI{i}(:,j)   [j-->n]
    %              ni x 1         ni x 1        scaler for given j
    % We compute PHI2(i, :) (for all j) in one go below
    PHI2(:,1,i) = sum(abs(PHI{i}).^2)';         % [mx1]
    
    % PHIv(i,j,l) = PHI{i}(:,j)' * v{i}(:,l)
    % m x L         ni x m         ni x L       for given i and all j and l
    % For given i, PHIv is a matrix of size [mxL]               
    PHIv(:,:,i) = PHI{i}' * v{i};
    % m x L       ni x m    nixL                for given i
    
    % G(i,l) = v{i}(:,l)' * v{i}(:,l) + (2-cTask)*b
    %          ni x 1       ni x 1              scaler for given l
    % We compute G(i,:) (for all l) in one go below
    G(1,:,i) = sum(abs(v{i}).^2)+rc*b; 
    % 1xL          1xL                          for given i
end

% Initialize S, Q, G(initalized above)
% Eq(43) with B_i=I
S=PHI2;
Q=PHIv;

% Initialize s, q, g 
%
% Note that when no basis is selected, i.e. $\alpha_j=\infty$ (as in the
% case above), we have $s_{i,j}=S_{i,j}, q_{i,j,l}=Q_{i,j,l},
% g_{i,j,l}=G_{i,l}$. [see the line after eq(44)]
s=S;                        % m x 1 x NT
q=Q;                        % m x L x NT
g=repmat(G, [m 1 1]);       % 1 x L x NT => m x L x NT

% Compute $\alpha_j$
%
% Now we consider to add a single basis $\Phi_{i,j}$, i.e PHI{i}(:, j).
% Compute $\alpha_j$ in eq(40) if $j$th basis is selected for j=1:m
% Note that this is an approximation of optimal \alpha_j
%
% All the candidates of alpha_j, j=1,.., m
%   alphaC = NT*Nob./sum(sum((Ki.*abs(q).^2./g-s)./(s.*(s-abs(q).^2./g)), 2),3);
% Eq(40):  alphaC is [mx1]
tmp=abs(q).^2./g;
alphaC=NT*Nob./sum(sum((Ki.*tmp-s)./(s.*(s-tmp)), 2), 3);

% Evaluate the marginal likelihood $\cal{L}(\alpha) in Eq(37)
% with $B_{i, -j}=I$
%
% The initial likelihood before the selection of basis in Eq(37) or Eq(31)
L0 =Nob*sum(a*log(b)-log(rc*pi)*Ni/rc+gammaln(Ni/rc+a)-gammaln(a))+ ...
        -1/rc*sum(sum(Ki.*log(G/rc),2),3);

if debugmode>=10
    fprintf('L0=%f\n', L0);
end

% Compute the likelihood change due to the basis selected in Eq (48)
% log marginal likelihood for all candidate bases
% mlC=rc*sum(log(alphaC./(alphaC+s))-Ki.*log(1-abs(q).^2./g./(alphaC+s)), 2);
% Note: log(alphaC./(alphaC+s))--> -log(1+s./alphaC)
%       mlC: [mx1] for all candidate bases
mlC=1/rc*sum(sum(-log(1+s./alphaC)-Ki.*log(1-tmp./(alphaC+s)), 2), 3);
% mlC is a vector [mx1] after the double summation

% Select the basis to maximize (approximately) the marginal likelihood and
% ensure $\alpha>0$.  This may not be possible sometimes.  Then an empty
% weights and ML will be returned.
goodalpha=false;        % flag for good alpha (+ve alpha, large ML change)
for j=1:m 
    % search at most m times (to avoid endless loop)
    [ML,index] = max(mlC);       
    % alpha correponds to the current selected single basis

    alpha = alphaC(index);         
    if alpha > 0  
        goodalpha=true;
        break;
    else
        mlC(index) = -inf;       % discard this basis and keep searching
    end
end

% Return zero weights and empty ML if no good alpha can be found
weights	= zeros(m,NT,Nob);
if ~goodalpha
    ML=[];
    warning('No basis can be selected.');
    return
end

fprintf('Iter=%-5d DeltaL=%f\n', 1, ML);

if debugmode>=10
    fprintf('Iter=%-5d DeltaL=%f\n', 1, ML);
    fprintf('  The basis selected (idx): %d\n', index);
    fprintf('  Adding\n');
end

% Compute initial mu, Sig, S, Q, G for selected basis and alpha with the
% selected basis (index) and alpha.  This is equavelant to adding a basis
% (from no basis).  So Eq(48-53) will apply.
phiB=cell(NT,1);            % selected basis for each task
SigB=cell(NT,1);            % $\Sigma_i$ for selected bases for each task
muB=cell(NT,1);             % $\mu_i$ for selected bases for each task
for i = 1:NT
    % selected basis for each task [idx--> j--> index]
    idx=index;                          
    phij = PHI{i}(:,idx);                       % \Phi{i,j}
        
    % Update $\Sigma$ and $\mu$ based on the single basis selected
    %
    % $Sigma_{i,(jj)$, $\mu_{i,j,l}$  and $e_{ij} after Eq(53)
    Sigijj=real(1/(alpha+S(idx,1,i)));          % it should be real
    % muijl: 1 x L x NT,   with mt=1 currently 
    muijl = Sigijj*Q(idx,:,i);                  % \mu_{i,j,l} for all l
    % eij is phij since \Sigma_i=0 currently
    eij = phij;                                 % e_{i,j} [mx1]
    
    % Eq(30) or (49) for a single selected basis
    % $ \Sigma_i = ( A + \Phi_i^H \Phi_i)^{-1} $
    % SigB{i} = 1/(alpha+phiB{i}'*phiB{i});   
    % Or $\Sigma_{i,(jj)$ after Eq(53)
    SigB{i}=Sigijj;
    
    % Eq(29) or Eq (50) for a single selected basis
    % $ \mu_i = \Sigma_i \Phi_i^T v_i
    % $ \mu_i = \Sigma_i \Phi_i^H v_i
    % Or $\mu_{ijl}$ after Eq(53)
    muB{i} = muijl;                 % muB: mt x L x NT (mt=1 now)
    
    % Update S, Q, G 
    % Note that $\Sigma_{i,(jj)}$ is the same as Sig{i} above and it is 
    % a scalar at this moment (before any basis selected)
    %
    % $e_{i,j}=\Phi_{i,j}-\Phi_i \Sigma_i \Phi_i^H \Phi_{i,j}=\Phi_{i,j}$
    % since $\Sigma_i=0$ initially (alpha-->infty) or no basis has been
    % selected
    comm2 = PHI{i}'*eij;           % \Phi_{i,n}^H e_{i,j} in (51)-(52)
    %mx1    (nixm)'(nix1)           with mt=1 for now
    
    S(:,1,i) = S(:,1,i)-Sigijj*abs(comm2).^2;                   % Eq(51)
    % mx1      mx1              mx1             for given i
    
    Q(:,:,i) = Q(:,:,i) - comm2 * muijl;                        % Eq(52)
    % mxL      mxL        mx1     1xL          for given i
    
    %G(1,:,i) = G(1,:,i) - Sigijj*abs(v{i}' * eij  ).^2;      % Eq(53)
    G(1,:,i) = G(1,:,i) - Sigijj*abs( eij' * v{i} ).^2;      % Eq(53)
    % 1xL      1xL                    nix1   nixL
    
    phiB{i} = phij;             % $j$th basis selected
end

%clear PHI2 left;

%% Iterations
% With the initial basis (index), alphaB, muB, SigmaB, S, Q, G computed, we
% are ready to do the iteration
%
% index, alphaB: the basis and corresponding precision parameter to be
% selected over the iteration, starting from one basis we have just
% initialized.

for count = 2:maxiter
    % update s, q, g,  Eq(44)
    s=S;                        % m x 1 x NT
    q=Q;                        % m x L x NT
    g=repmat(G, [m 1 1]);       % 1 x L x NT => m x L x NT
    
    % Update s, q, g for the bases selected
    % Eq(44) for selected basis (index) only
    %
    % alpha, index: correspond to current selected bases [mtx1]
    % s(index,1,:) = alpha.*S(index,1,:)./(alpha-S(index,:));
    % s(index,1,:) = S(index,1,:)./(1-S(index,:)/alpha);
    tmpsq=1-S(index,1,:)./alpha;       % [mtx1xNT]./[mtx1]
    s(index,1,:)=S(index,1,:)./tmpsq;
    % mtx1xNT    mtx1xNT      mtx1xNT
    
    % q(index,:,:) = alpha.*Q(index,:,:)./(alpha-S(index,:));
    % q(index,:,:) = Q(index,:,:)./(1-S(index,:)/alpha);
    q(index,:,:) = Q(index,:,:)./tmpsq;
    % mtxLxNT      mtxLxNT       mtx1xNT 
    
    %g(index,:) = G(index,:)+Q(index,:).^2./(alphaB-S(index,:));
    g(index,:,:) = G(1,:,:) + abs(Q(index,:,:)).^2./(alpha-S(index,1,:));
    % mtxLxNT      1xLxNT         mtxLxNT            mtx1  mtx1xNT   
    
    %% Determine the update option: adding, re-estimating, or deleting
    %
    % Compute alpha for all candidates
    %
    % Eq(40): $\alph_j$ for $j=1,...,m$ 
    % This is to say that, based on the current selected basis functions,
    % we estimate the hyperparameter $\alpha_j$ if $j$th basis is going to
    % be selected next.
    
    theta=(NT*Nob)./sum(sum(...
        (Ki.*abs(q).^2./g-s)./(s.*(s-abs(q).^2./g)) ,2),3);

    % choice the next alpha that maximizes marginal likelihood
    % initialize the maximum likelighood (m x 1) for all candidates (with
    % positive theta)
    deltaL = repmat(-inf,[m,1]);
    
    % We only consider the positive $\alpha_j$ (theta(j) for the selection
    % of next basis. All the possible candidates are:  
    ig0 = find(theta>0);     % index for alpha greater than 0
    
    % For Re-estimating a basis function 
    %
    % Condition: bases with theta>0 and bases already selected
    %
    % alpha:  the existing hyperparameters [length(alpha)=length(index)]
    % index:  the index set for the existing basis functions
    % ig0:    the index set for postive $\tilde{\alpha}_j$
    % which:  ire=index(which) so that alpha(which) are the old alpha to be
    %         re-estimated
    % 
    % There might be multiple candidates for re-estimating if length(ire)>1
    [ire,which] = intersect(index, ig0);        % ire=index(which)
    if ~isempty(ire)
        % new estimate: $\tilde{\alpha}_j$ in Eq(54)
        alpha1 = theta(ire);        % bases considered for re-estimating
        % old estimate: $\alpha_j$
        alpha0 = alpha(which);

        % Eq(54) (sum over l and i)
        deltaL(ire)=1/rc*sum(sum(...          
            (Ki-1).*log(1+S(ire,1,:).*(1./alpha1-1./alpha0))+...
            Ki.*log(((alpha0+s(ire,1,:)).*g(ire,:,:)-abs(q(ire,:,:)).^2)...
            ./(((alpha1+s(ire,1,:)).*g(ire,:,:)-abs(q(ire,:,:)).^2) ...
            .*(alpha1./alpha0))) ,2), 3);
    end
    
    % For adding a new basis
    %
    % Condition: bases with theta>0 and bases not selected for re-estimating
    %           
    % setdiff(ig0, ire): find the values in ig0 that are not in ire
    iad = setdiff(ig0,ire);
    if ~isempty(iad)
        % Eq (48)
        alpha1 = theta(iad);      	% bases consider for adding
        deltaL(iad,:)=1/rc*sum(sum(...
            -log(1+s(iad,1,:)./alpha1)...
            -Ki.*log(1-abs(q(iad,:,:)).^2./g(iad,:,:)./(alpha1+s(iad,1,:))),...
            2), 3);
    end
    
    % For deleting a basis
    %
    % Condition: bases with theta<0 and already selected
    %
    % is0: the set for alpha equal or less than 0
    is0 = setdiff((1:m),ig0);
    % ide: candidates to be deleted
    [ide, which] = intersect(index, is0);       % ide=index(which)
    if ~isempty(ide)
        % Eq(60)
        alpha1 = alpha(which);    	% bases consider for deleting
        deltaL(ide,:)=1/rc*sum(sum(...
            -log(1-S(ide,1,:)./alpha1)...
            -Ki.*log(1+abs(Q(ide,:,:)).^2./(G.*(alpha1-S(ide,1,:)))), ...
            2), 3);
    end
    
    if debugmode
        if ~isreal(deltaL)
            warning('ML contain complex numbers.')
        end
    end
    
    % compute the maximum likelihood
    % idx is the basis selected for update
    [maxML,idx] = max(real(deltaL));
    
    if maxML>0,
        ML(count)=maxML;
    else
        break;         % stop iteration if no increament on ML
    end
    
    fprintf('Iter=%-5d  DeltaL=%f\n', count, ML(count));
    
    if debugmode>=10
        fprintf('Iter=%-5d  DeltaL=%f\n', count, ML(count));
        fprintf('  The basis selected (idx): %d\n', idx);
    end

    % check if terminates?
    if (count>2) && abs(ML(count)-ML(count-1)) < (max(ML)-ML(count))*eta
        break;
    end
    
    %% Update
    % idx is the basis selected for update that gives max increase of
    % log marginal likelihood
    
    % check if the basis to be selected (idx) is already in the current
    % bases
    which = find(index==idx);       
    
    if theta(idx) > 0               
        % re-estimate or add if selected candidate has positive theta
        if ~isempty(which)         
                fprintf('  Re-estimating\n');

            % re-estimating if idx is already in selected bases so far
            alpha_sel = theta(idx);     % scalar
            for i = 1:NT
                % which-->k
                
                % $ \Sigma_{i,(kk)} $
                Sigikk = SigB{i}(which,which);      % scalar    
                % $ \mu_{i,k,l}
                muikl = muB{i}(which,:);            % 1xL
                % $ \Signma_{i,k} $  is $k$-th column of $\Sigma_i$
                Sigik = SigB{i}(:,which);           % mtx1
                
                % $ \gamma_{i,k} $ before Eq(54)
                gik = 1/(Sigikk + 1/(alpha_sel-alpha(which)));  
                %                    new       old
                
                % $ \mu_{i,l} $
                muB{i} = muB{i}-gik*Sigik*muikl;                % Eq(56)
                % mtxL   mtxL       mtx1  1xL 
                
                % $ \Sigma_i$ 
                SigB{i} = SigB{i}-gik*(Sigik*Sigik');           % Eq(55)
                %         mtxmt        mtx1  mtx1
                
                comm = PHI{i}'*(phiB{i}*Sigik);
                %mx1    nixm     nixmt   mtx1
                
                S(:,1,i) = S(:,1,i) + gik*abs(comm.^2);       	% Eq(57)
                %mx1       mx1                mx1
                
                Q(:,:,i) = Q(:,:,i) + gik*comm*muikl;         	% Eq(58)
                % mxL      mxL            mx1  1xL
                
                % Eq(59)
                G(1,:,i) = G(1,:,i)+gik*abs(Sigik'*PHIv(index,:,i)).^2; 
                %1xL       1xL              mtx1       mtxL
                
                qwetrty=1;
            end
            % update alpha
            alpha(which) = alpha_sel;
        else
            % adding if idx is not in selected bases so far
                fprintf('  Adding\n');
                
            alpha_sel = theta(idx);
            for i = 1:NT
                % idx-->j
                phij = PHI{i}(:,idx);                       % \Phi{i,j}
                Sigijj = 1/(alpha_sel+S(idx,1,i));          % \Sigma_{i,jj}
                muijl = Sigijj*Q(idx,:,i);                  % \mu_{i,j,l}
                % 1xL
                
                comm1 = SigB{i}*(phiB{i}'*phij);
                %mtx1    mtxmt    nixmt    nix1  
                
                eij = phij-phiB{i}*comm1;                   % e_{i,j}
                %nix1  nix1  nixmt  mtx1
                
                offd = -Sigijj*comm1;                       % off diagonal
                %mtx1          mtx1
                
                % Eq(49)
                SigB{i}=[SigB{i}+Sigijj*(comm1*comm1'), offd; offd', Sigijj];
                
                % Eq(50)
                muB{i} =     [muB{i}-comm1 * muijl; muijl];
                %(mt+1)xL     mtxL   mtx1    1xL    1xL
                
                comm2 = PHI{i}'*eij;
                %mx1    nixm    nix1
                
                S(:,1,i) = S(:,1,i)-Sigijj*abs(comm2).^2;   	% Eq(51)
                % mx1       mx1                 mx1

                Q(:,:,i) = Q(:,:,i) - comm2*muijl;             	% Eq(52)
                % mxL        mxL       mx1  1xL
                
                G(1,:,i) = G(1,:,i)-Sigijj*abs(eij'*v{i}).^2;    % Eq(53)
                % 1xL      1xL                nix1   nixL 
                
                % add the new basis
                phiB{i} = [phiB{i},phij];
            end         
            index = [index; idx];               %#ok<AGROW>
            alpha = [alpha; alpha_sel];         %#ok<AGROW>
        end
    else
        if ~isempty(which)              % deleting

                fprintf('  Deleting\n');

            for i = 1:NT
                Sigikk = SigB{i}(which,which);         	% \Sigma_{i,kk}
                muikl = muB{i}(which,:);                % \mu_{i,k,l}
                Sigik = SigB{i}(:,which);              	% \Sigma_{i,k}
                
                SigB{i} = SigB{i}-Sigik*Sigik'/Sigikk;      % Eq(61)
                % mtxmt   mtxmt   mtx1  mtx1               
                
                for j=1:length(index)
                    for k=which:length(index)-1
                        SigB{i}(j,k) = SigB{i}(j,k+1);
                    end
                end
                for j=which:length(index)-1
                    for k=1:length(index)-1
                        SigB{i}(j,k) = SigB{i}(j+1,k);
                    end
                end
                SigB{i}(:,length(index)) = [];                  	% Remove column
                SigB{i}(length(index),:) = [];
                
%                 SigB{i}(:,which) = [];                  	% Remove column
%                 SigB{i}(which,:) = [];                      % Remove row
                
                muB{i} = muB{i}-muikl.*Sigik/Sigikk;      	% Eq(62)
                % mtxL   mtxL   mtxL  mtx1  
                
                for j=which:length(index)-1
                    for k=1:Nob
                        muB{i}(j,k) = muB{i}(j+1,k);
                    end
                end
                muB{i}(length(index),:) = [];
                
                %muB{i}(which,:) = [];                         % Remove element
                
                comm = PHI{i}'*(phiB{i}*Sigik);
                %mx1   nixm     nixmt    mtx1
                
                S(:,1,i) = S(:,1,i)+abs(comm).^2/Sigikk;    % Eq(63)
                % mx1      mx1          mx1
                
                Q(:,:,i) = Q(:,:,i) + comm *muikl/Sigikk;   	% Eq(64)
                % mxL       mxL       m*mt   mtxL
                
                G(1,:,i) = G(1,:,i) + abs(Sigik'*PHIv(index,:,i)).^2/Sigikk;  % Eq(65)
                %1xL       1xL            mtx1   mtxL
                
%                 phiB{i}(:,which) = [];
                
                for j=1:Ni(i)
                    for k=which:length(index)-1
                        phiB{i}(j,k) = phiB{i}(j,k+1);
                    end
                end
                phiB{i}(:,length(index)) = [];
                
            end
            %
            index(which) = [];
            alpha(which) = [];
        end
    end

end
% output
for k = 1:NT
    weights(index,k,:) = muB{k};
end

if debugmode>=10
    fprintf('Iteration ended.\n\n');
end
