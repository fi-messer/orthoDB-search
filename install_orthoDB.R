## Install and test run OrthoDB

# Preferred installation method

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

# Search at Drosophila level
S <- api$search("kmg", level=7215)
S[["cluster_ids"]]
OGS <- api$orthologs("49125at7215")
df <- OGS$df$data$genes[[1]]
df2 <- OGS$df$data$organism

length(OGS$df$data$genes)
(1:(length(OGS$df$data$genes)))
df1 <- NULL

for (n in (1:(length(OGS$df$data$genes)))) {
  df <- OGS$df$data$genes[[n]]
  df1 <- bind_rows(df1, df)
}

# Gives list of genes for each spp. but many are duplicated. 
# Table is also messy, clean it up

drops <- c("interpro", "more_info", "how_much_more_info")
df1 <- df1[, !(names(df1) %in% drops)]

# How to deal with the duplicated data? Maybe easier to deal with it once I've pulled out just the data I want?

# Now I'll add in some easier to understand species data. In the gene_id$param column, the first half is made up of the species id
# e.g. 7291_1:00116e
# Get a list of species ids
DB <- api$species(7215)

# Look at a single species id
DB[["db"]][[1]]

# Try to make it into a dataframe
ncbi_taxid <- NULL
organism_id <- NULL
sciname <- NULL
strain <- NULL
taxon_id <- NULL
taxon_ver <- NULL

for (l in (1:length(DB[["db"]]))) {
  ncbi_taxid <- rbind(ncbi_taxid, DB[["db"]][[l]]$ncbi_taxid)
  organism_id <- rbind(organism_id, DB[["db"]][[l]]$organism_id)
  sciname <- rbind(sciname, DB[["db"]][[l]]$sciname)
  strain <- rbind(strain, DB[["db"]][[l]]$strain)
  taxon_id <- rbind(taxon_id, DB[["db"]][[l]]$taxon_id)
  taxon_ver <- rbind(taxon_ver, DB[["db"]][[l]]$taxon_ver)
}

species <- data.frame(ncbi_taxid = ncbi_taxid,
                      organism_id = organism_id,
                      sciname = sciname,
                      strain = strain,
                      taxon_id = taxon_id,
                      taxon_ver = taxon_ver)

# species is now a dataframe containing info for all 83 species listed (although some are duplicates, which I will sort out now)

unique(species$sciname) # how many unique species are in the list? = 49
sum(species$taxon_ver == 0) # is the number of taxon_ver = 0 the same as the number of unique spp? yes

species <- species %>% filter(taxon_ver == 0) # have removed duplicates from the species database

