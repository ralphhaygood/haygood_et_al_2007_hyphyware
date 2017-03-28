Haygood et al., 2007 HyPhy-ware
===============================

This repository contains materials related to the article Ralph Haygood, Olivier Fedrigo, Brian Hanson, Ken-Daigoro
Yokoyama, and Gregory A. Wray, 2007, "Promoter regions of many neural- and nutrition-related genes have experienced
positive selection during human evolution", *Nat. Genet.* **39**:1140–1144, http://dx.doi.org/doi:10.1038/ng2104.

Specifically, it contains the main text, supplementary text, and supplementary tables of the article, the HyPhy Batch
Language files used to compute the results in the article, and an example of their use.

Ever since the article was published, we (Ralph Haygood and Olivier Fedrigo) have received many requests for the HyPhy
Batch Language files. Rather than sending the files to each requester by email, now that GitHub is widely used, we're
offering this repository as a more convenient way to obtain the HyPhy-ware.

What follows assumes some knowledge of HyPhy. For an introduction to HyPhy, see
http://www.hyphy.org/w/index.php/Main_Page.


Overview
--------

For explanations of our models and methods, see the article, included here under article/, particularly Figure 1, its
caption, and the text pertaining to it.

In the article, we compare promoter regions to intronic sequences, but the HyPhy Batch Language files aren't specific to
these choices. In general, they compare a "query compartment" to a "reference compartment". The former should be
wherever you wish to detect positive selection, and the latter should be as free as possible from any kind of selection,
which might mean intronic sequences, remote intergenic sequences, or 4-fold degenerate sites in coding sequences,
depending on your situation.

A complete analysis requires two runs of HyPhy, one to fit a null model and the other to fit an alternate model. (These
could be combined into one run, but for unimportant reasons, we've kept them separate.) The null and alternate models
discussed in the article are what we call null2-fgrnd\_spec and alt2-fgrnd\_spec. (We've also worked with other models,
which aren't discussed in the article.) So there are two HyPhy Batch Language files, hyphyware/null2-fgrnd\_spec.bf and
hyphyware/alt2-fgrnd\_spec.bf.

These files do the real work, but they expect certain variables to have been initialized. For example, `tree` should
contain a Newick-format representation of the phylogeny (e.g., `"((hsap, ptro), mmul)"`). So HyPhy should be invoked
with a short HyPhy Batch Language file that first initializes the variables and then `#include`s either
null2-fgrnd\_spec.bf or alt2-fgrnd\_spec.bf.


Example
-------

As an example, the repository contains files for *MMP20*, a gene involved in tooth enamel formation that scores high not
only in our study but also in Clark et al.'s 2003 study of positive selection on coding sequences.

There are two short HyPhy Batch Language files, example/mmp20\_null2-hsap.bf for the null model and
example/mmp20\_alt2-hsap.bf for the alternate model, and two PHYLIP-format sequence alignment files,
example/mmp20\_flank5\_fid.phy for the promoter region and example/mmp20\_intrA\_for\_flank5\_fid.phy for the intronic
sequences. These alignments are what we call fiducial alignments, meaning they contain only A, C, G, and T, no missing
or ambiguous bases.

Assuming you have a shell (command, terminal, etc.) window open, HyPhy is in your path (the list of directories where
the shell looks when you ask it to run a program), and example/ is the current working directory, to fit the null model
to the alignments, do

    HyPhy mmp20_null2-hsap.bf > mmp20_null2-hsap_out

and to fit the alternate model, do

    HyPhy mmp20_alt2-hsap.bf > mmp20_alt2-hsap_out

Each run yields a results file, an output file, and a messages file. The results file, mmp20\_null2-hsap\_res for the
null model or mmp20\_alt2-hsap\_res for the alternate model, is the most interesting. It summarizes the fit, including
the log-likelihood and parameter estimates, for the best replicate among the ten replicates mmp20\_null2-hsap.bf or
mmp20\_alt2-hsap.bf tells HyPhy to perform, and it contains the standard deviation of the log-likelihoods over all the
replicates, which should be tiny. The output file, mmp20\_null2-hsap\_out for the null model or mmp20\_alt2-hsap\_out
for the alternate model, less readably summarizes the fit for each replicate in turn, and the messages file,
messages.log, rather cryptically annotates the entire run.

The repository contains samples of these files, such as example/mmp20\_null2-hsap\_res\_SAMPLE. Because the processing
involves (pseudo)random numbers, which might differ from one computing platform or HyPhy version to another (even when,
as here, the generator is initialized with the same seed), the files you generate via the commands above might differ
appreciably from the sample files. However, you should at least be able to verify that your installation of HyPhy
processed the example correctly.


Notes
-----

Our full software pipeline includes a Ruby program that sets up the input files, runs HyPhy, and looks through the
results files. It extracts the log-likelihoods and computes a *p*-value using a chi-squared distribution with one degree
of freedom, as described in the article. If fitting the null and alternate models were combined into one run of HyPhy,
this could be done there too.

There's a potentially confusing difference of notation between the article and the HyPhy Batch Language files. The
notation in the files, namely `f0`, `f1`, `f2`, `f3`, `zeta0`, and `zeta2`, was chosen early in the project, whereas the
notation in the article, namely *f*\_1, *f*\_2, *f*\_3, *zeta*\_1, *zeta*\_2, and *zeta*\_3 (where \_ indicates
subscripting and *zeta* is the Greek letter) was chosen later, with a view toward making our models easy to
understand. These notations relate as follows: *f*\_1 = `f0`, *zeta*\_1 = `zeta0`, *f*\_2 = `f1`, *zeta*\_2 = 1, *f*\_3
= `f2`+`f3`, and *zeta*\_3 = `zeta2`.


Thanks
------

We thank Sergei Kosakovsky-Pond (http://www.hyphy.org/w/index.php/Sergei_L_Kosakovsky_Pond), the primary developer of
HyPhy, for his advice toward crafting the mildly esoteric code in the HyPhy Batch Language files.


Contact
-------

Ralph Haygood (https://ralphhaygood.org/)  
ralph@ralphhaygood.org
