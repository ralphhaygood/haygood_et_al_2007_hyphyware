/* Set control parameters. */
LIKELIHOOD_FUNCTION_OUTPUT = 5;
MAXIMUM_ITERATIONS_PER_VARIABLE = 10000;

/* Initialize (pseudo)random-number generator. */
SetParameter(RANDOM_SEED, random_seed, 0);

/* Set up query compartment data subset. */
DataSet quer_data_subset = ReadDataFile(quer_seq_file);
DataSetFilter quer_data_subset_filt = CreateFilter(quer_data_subset, 1);
HarvestFrequencies(quer_pis, quer_data_subset, 1, 1, 1);

/* Set up reference compartment data subset. */
DataSet ref_data_subset = ReadDataFile(ref_seq_file);
DataSetFilter ref_data_subset_filt = CreateFilter(ref_data_subset, 1);
HarvestFrequencies(ref_pis, ref_data_subset, 1, 1, 1);

/* Set up model. */
global kappa_inverse;

/* Set up query compartment submodel. */
global f0;
f0 :< 1;
global f_aux;
f_aux :< 1;
site_class_freqs = {{f0, (1.0-f0)*f_aux, (1.0-f0)*(1.0-f_aux)}};
site_class_vals = {{0, 1, 2}};
category site_class = (3, site_class_freqs, MEAN, , site_class_vals, 0, 2);
global zeta0;
zeta0 :< 1;
global zeta_bgrnd;
zeta_bgrnd := ((site_class == 0)+(site_class == 2))*zeta0 + (site_class == 1);
global zeta_fgrnd;
zeta_fgrnd := (site_class == 0)*zeta0 + ((site_class == 1)+(site_class == 2));
quer_mat = {{*, kappa_inverse*t, t, kappa_inverse*t}
            {kappa_inverse*t, *, kappa_inverse*t, t}
            {t, kappa_inverse*t, *, kappa_inverse*t}
            {kappa_inverse*t, t, kappa_inverse*t, *}};
Model quer_submod = (quer_mat, quer_pis, 1);

/* Set up reference compartment submodel. */
ref_mat = {{*, kappa_inverse*t, t, kappa_inverse*t}
           {kappa_inverse*t, *, kappa_inverse*t, t}
           {t, kappa_inverse*t, *, kappa_inverse*t}
           {kappa_inverse*t, t, kappa_inverse*t, *}};
Model ref_submod = (ref_mat, ref_pis, 1);

/* Fit model to data sets. */
log_Ls = {fit_repl_count, 1};
for (repl_i = 0; repl_i < fit_repl_count; repl_i = repl_i+1) {
  kappa_inverse = Random(0.0, 10.0);
  f0 = Random(0.0, 1.0);
  f_aux = Random(0.0, 1.0);
  zeta0 = Random(0.0, 1.0);
  UseModel(quer_submod);
  Tree quer_hyphy_tree = tree;
  UseModel(ref_submod);
  Tree ref_hyphy_tree = tree;
  ReplicateConstraint("this1.?.t := zeta_bgrnd*this2.?.t", quer_hyphy_tree, ref_hyphy_tree);
  ExecuteCommands("quer_hyphy_tree."+fgrnd_branch_name+".t := zeta_fgrnd*ref_hyphy_tree."+fgrnd_branch_name+".t;");
  LikelihoodFunction L = (quer_data_subset_filt, quer_hyphy_tree, ref_data_subset_filt, ref_hyphy_tree);
  Optimize(MLEs, L);
  log_L = MLEs[1][0];
  log_Ls[repl_i] = log_L;
  if (repl_i == 0 || best_log_L < log_L) {
    best_repl_i = repl_i;
    best_log_L = log_L;
    best_MLEs = MLEs;
  }
  fprintf(stdout, "REPL ", repl_i, "\n");
  fprintf(stdout, "log_L:", Format(log_L, 0, 16));
  fprintf(stdout, L, "\n\n");
}
sum = 0.0;
for (repl_i = 0; repl_i < fit_repl_count; repl_i = repl_i+1) sum = sum+log_Ls[repl_i];
mean_log_L = sum/fit_repl_count;
if (fit_repl_count > 1) {
  sum = 0.0;
  for (repl_i = 0; repl_i < fit_repl_count; repl_i = repl_i+1) sum = sum + (log_Ls[repl_i]-mean_log_L)^2;
  stdev_log_L = Sqrt(sum/(fit_repl_count-1));
} else
  stdev_log_L = 0.0;

/* Write results. */
fprintf(res_file, "BEST REPL: ", best_repl_i, "\n");
fprintf(res_file, "BEST LOG-L: ", Format(best_log_L, 0, 6), "\n");
best_kappa_inverse = best_MLEs[0][0];
fprintf(res_file, "BEST kappa: ", 1.0/best_kappa_inverse, "\n");
best_f0 = best_MLEs[0][4];
fprintf(res_file, "BEST f0: ", best_f0, "\n");
best_f_aux = best_MLEs[0][5];
best_f1 = (1.0-best_f0)*best_f_aux;
fprintf(res_file, "BEST f1: ", best_f1, "\n");
best_f2 = (1.0-best_f0)*(1.0-best_f_aux);
fprintf(res_file, "BEST f2: ", best_f2, "\n");
best_zeta0 = best_MLEs[0][6];
fprintf(res_file, "BEST zeta0: ", best_zeta0, "\n");
Tree dummy_hyphy_tree = tree;
branch_names = BranchName(dummy_hyphy_tree, -1);
for (branch_i = 0; branch_i < Columns(branch_names)-1; branch_i = branch_i+1) {
  best_branch_t = best_MLEs[0][1+branch_i];
  fprintf(res_file, "BEST ", branch_names[branch_i], ".t: ", best_branch_t, "\n");
}
best_zeta_bgrnd_factor = (best_f0+best_f2)*best_zeta0 + best_f1;
best_zeta_fgrnd_factor = best_f0*best_zeta0 + (best_f1+best_f2);
quer_pi_a = quer_pis[0];
quer_pi_c = quer_pis[1];
quer_pi_g = quer_pis[2];
quer_pi_t = quer_pis[3];
best_quer_branch_factor = 2.0*((quer_pi_a*quer_pi_g + quer_pi_c*quer_pi_t) + (quer_pi_a*quer_pi_c + quer_pi_a*quer_pi_t + quer_pi_c*quer_pi_g + quer_pi_g*quer_pi_t)*best_kappa_inverse);
for (branch_i = 0; branch_i < Columns(branch_names)-1; branch_i = branch_i+1) {
  best_branch_t = best_MLEs[0][1+branch_i];
  if (branch_names[branch_i] != fgrnd_branch_name)
    fprintf(res_file, "BEST ", branch_names[branch_i], " QUER LENGTH: ", best_zeta_bgrnd_factor*best_quer_branch_factor*best_branch_t, "\n");
  else
    fprintf(res_file, "BEST ", branch_names[branch_i], " QUER LENGTH: ", best_zeta_fgrnd_factor*best_quer_branch_factor*best_branch_t, "\n");
}
ref_pi_a = ref_pis[0];
ref_pi_c = ref_pis[1];
ref_pi_g = ref_pis[2];
ref_pi_t = ref_pis[3];
best_ref_branch_factor = 2.0*((ref_pi_a*ref_pi_g + ref_pi_c*ref_pi_t) + (ref_pi_a*ref_pi_c + ref_pi_a*ref_pi_t + ref_pi_c*ref_pi_g + ref_pi_g*ref_pi_t)*best_kappa_inverse);
for (branch_i = 0; branch_i < Columns(branch_names)-1; branch_i = branch_i+1) {
  best_branch_t = best_MLEs[0][1+branch_i];
  fprintf(res_file, "BEST ", branch_names[branch_i], " REF LENGTH: ", best_ref_branch_factor*best_branch_t, "\n");
}
fprintf(res_file, "STDEV OF LOG-LS: ", stdev_log_L, "\n");
