% Runs algorithms convergence. No loops to speed up parfor computations

%% Constant parameters
eps = 0.01;
num_trials = 50;
num_iter = 100;
precision = 1e-6;
write_precision = 6;
graph_size = 100;
prob = 0.5;
num_cut_finder_trials = 10000;

rank_tol_one = 1e-4;
rank_tol_two = 1e-6; 

p = 0.01;
q = 0.8;

folder = 'rank_cut_results/';
mkdir(folder);

%% Choose methods
do_irls = false;
do_grad = true;
do_singval = true;
do_logdet = true;

%% Run simulations

disp('Running p=0.01 and q=0.8');

% Saves results for mean convergence of proposed algorithms
% Tries different parameters and size. Requires Parallel Computing Toolbox

%% Preliminaries
disp(strcat('Running for size=', int2str(graph_size), ...
    ' and prob=', int2str(100 * prob)));
general_name = strcat('s', int2str(graph_size), '_pr', ...
    int2str(100 * prob));

% methods are hard-coded below due to parfor restrictions
colnames = {'rank', 'cut_mean', 'cut_std'};
results_sdp = zeros(num_trials, 4);  

if do_irls
    results_irls = zeros(num_trials, 4);  
end

if do_grad
    results_grad = zeros(num_trials, 4);  
end

if do_singval
    results_singval = zeros(num_trials, 4);  
end
   
if do_logdet
    results_logdet = zeros(num_trials, 4);  
end

%% Simulations
for i = 1:num_trials 
    disp(i);
    %% Run the same matrix for each method
    laplacian_matrix = get_laplacian('random', prob, graph_size);

    [sdp_matrix, cut, sdp_optval, cut_optval] = ...
        solve_maxcut_sdp(laplacian_matrix, 10, true);
    
    results_sdp(i, 1) = rank(sdp_matrix, rank_tol_one);
    results_sdp(i, 2) = rank(sdp_matrix, rank_tol_two);
    [~, ~, results_sdp(i, 3), results_sdp(i, 4)] = ...
        compute_cut_randomized(laplacian_matrix, ...
        sdp_matrix, num_cut_finder_trials);

    %% IRLS
    if do_irls
        [matrix, ~] = solve_maxcut_irls(...
            laplacian_matrix, sdp_optval, cut_optval, ...
            sdp_matrix, p, eps, num_iter, precision, false, true); 
        
        results_irls(i, 1) = rank(matrix, rank_tol_one);
        results_irls(i, 2) = rank(matrix, rank_tol_two);
        [~, ~, results_irls(i, 3), results_irls(i, 4)] = ...
            compute_cut_randomized(laplacian_matrix, ...
            matrix, num_cut_finder_trials);
    end
    
    %% Schatten grad
    if do_grad
        [matrix, ~] = solve_maxcut_grad(...
            laplacian_matrix, sdp_optval, cut_optval, ...
            sdp_matrix, p, eps, num_iter, precision, false, true);
        
        results_grad(i, 1) = rank(matrix, rank_tol_one);
        results_grad(i, 2) = rank(matrix, rank_tol_two);
        [~, ~, results_grad(i, 3), results_grad(i, 4)] = ...
            compute_cut_randomized(laplacian_matrix, ...
            matrix, num_cut_finder_trials);
    end
        
    %% Singular values grad
    if do_singval
        [matrix, ~] = solve_maxcut_singval(...
            laplacian_matrix, sdp_optval, cut_optval, ...
            sdp_matrix, q, eps, num_iter, precision, false, true);
        
        results_singval(i, 1) = rank(matrix, rank_tol_one);
        results_singval(i, 2) = rank(matrix, rank_tol_two);
        [~, ~, results_singval(i, 3), results_singval(i, 4)] = ...
            compute_cut_randomized(laplacian_matrix, ...
            matrix, num_cut_finder_trials);
    end
        
    %% Log-det
    if do_logdet
        [matrix, ~] = solve_maxcut_logdet(...
            laplacian_matrix, sdp_optval, cut_optval, ...
            sdp_matrix, eps, num_iter, precision, false, true);
        
        results_logdet(i, 1) = rank(matrix, rank_tol_one);
        results_logdet(i, 2) = rank(matrix, rank_tol_two);
        [~, ~, results_logdet(i, 3), results_logdet(i, 4)] = ...
            compute_cut_randomized(laplacian_matrix, ...
            matrix, num_cut_finder_trials);
    end
    
    disp(strcat(int2str(i), ' done'));
end

disp('Write started');
%% Write results
dlmwrite(strcat(folder, 'sdp_', general_name), ...
    results_sdp, ...
    'precision', write_precision); 
    
if do_irls
    dlmwrite(strcat(folder, 'irls_', general_name, ...
        '_p', int2str(10 * p)), ...
        results_irls, ...
        'precision', write_precision); 
end

if do_grad
    dlmwrite(strcat(folder, 'grad_', general_name, ...
        '_p', int2str(10 * p)), ...
        results_grad, ...
        'precision', write_precision); 
end
   
if do_singval
    dlmwrite(strcat(folder, 'singval_', general_name, ...
        '_q', int2str(10 * q)), ...
        results_singval, ...
        'precision', write_precision); 
end

if do_logdet
    dlmwrite(strcat(folder, 'logdet_', general_name), ...
        results_logdet, 'precision', write_precision); 
end

disp('Results written');        

