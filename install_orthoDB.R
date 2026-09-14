## Install and test run OrthoDB

remotes::install_gitlab('ezlab/orthodb_r',build_vignettes = TRUE, dependencies = TRUE)
library(dplyr)

api <- OrthoDB::OdbAPI$new()

T = api$tree(33208)

# Search for "p450" at Drosophila (7215) level.
# Take the first 10 results returned.
S <- api$search("p450", level=7215, take=10)

# Look at a table of the p450 gene groups in Drosophila
S[["df"]][["bigdata"]]

# Make the same search but skip the first 2 and take 2 results.
S <- api$search("p450", level=7215, take=2, skip=2)

# The list of cluster ids
S$cluster_ids

# get all genes from in a given cluster id
OGS <- api$orthologs("1959143at33208")

# retrieve information on given gene
G <- api$gene_search("7227_0:00085a")

# Load all species at Drosophila level (7215).
# Note passing NULL,0 or 1 will retrieve the full species DB.
DB <- api$species(7215)

# Find all OrthoDB taxids that are 7215
DB$find_taxid(7215)
DB$db
DB$db[[1]]$ncbi_taxid
