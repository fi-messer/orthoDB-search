#### OrthoDB Drosophila search tool
# 1:1 or 1:many version

# Load packages

remotes::install_gitlab('ezlab/orthodb_r',build_vignettes = TRUE, dependencies = TRUE)
library(OrthoDB)
library(dplyr)
library(stringr)

# User inputs

species <- c("Drosophila melanogaster", "Drosophila pseudoobscura", "Drosophila miranda", "Drosophila subobscura")

gene <- ""

simplified_output <- TRUE # Logical, produces a simplified output with only species name and LOC/CG number

output <- TRUE # Logical, writes output to csv

###################################
###################################

#### Open OrthoDB connection

api <- OrthoDB::OdbAPI$new()

#### Run the search

S <- api$search(gene, level=7215) # search for the gene

tree <- as.list(S[["cluster_ids"]]) # extract the ortholog tree for gene

OGS <- api$orthologs(tree[[1]]) # search for orthologs

# Transform the extracted data into usable output

length(OGS$df$data$genes)

OGS_df <- NULL

for (n in (1:(length(OGS$df$data$genes)))) {
  temp <- OGS$df$data$genes[[n]]
  OGS_df <- bind_rows(OGS_df, temp)
}

head(OGS_df) # OGS_df is now the output dataframe containing orthology info

# Dataframe cleanup

drops <- c("interpro", "more_info", "how_much_more_info")
OGS_df <- OGS_df[, !(names(OGS_df) %in% drops)] # Remove unnecessary columns

OGS_df$LOC_id <- OGS_df$gene_id$id
OGS_df$orthoDB_id <- OGS_df$gene_id$param
OGS_df$gene_id <- NULL # Removes the nested dataframe by renaming columns
OGS_df$taxon_id <- str_split_i(OGS_df$orthoDB_id, ":", 1) # makes a column with the taxon_id for easy data extraction with the species list

#### Extract species information for OGS_df filtering

if (exists("Dros_spp") == TRUE){
  print("Species data pre-loaded")
} else {
  print("Loading species data")
  Dros_spp <- api$species(7215)
  
  # Make species data into a usable dataframe
  ncbi_taxid <- NULL
  organism_id <- NULL
  sciname <- NULL
  strain <- NULL
  taxon_id <- NULL
  taxon_ver <- NULL
  
  for (l in (1:length(Dros_spp[["db"]]))) {
    ncbi_taxid <- rbind(ncbi_taxid, Dros_spp[["db"]][[l]]$ncbi_taxid)
    organism_id <- rbind(organism_id, Dros_spp[["db"]][[l]]$organism_id)
    sciname <- rbind(sciname, Dros_spp[["db"]][[l]]$sciname)
    strain <- rbind(strain, Dros_spp[["db"]][[l]]$strain)
    taxon_id <- rbind(taxon_id, Dros_spp[["db"]][[l]]$taxon_id)
    taxon_ver <- rbind(taxon_ver, Dros_spp[["db"]][[l]]$taxon_ver)
  }
  
  Dros_spp <- data.frame(ncbi_taxid = ncbi_taxid,
                         organism_id = organism_id,
                         sciname = sciname,
                         strain = strain,
                         taxon_id = taxon_id,
                         taxon_ver = taxon_ver)
  
  print(head(Dros_spp))
  print("Species info loaded")
  print(paste0("Species info retrieved for ", length(unique(Dros_spp$sciname)), " unique species"))
}

# Filter species data by user-provided species list
species_df <- filter(Dros_spp, sciname %in% species & taxon_ver == 0)

# subset the search data
OGS_df <- filter(OGS_df, taxon_id %in% species_df$taxon_id)

# merge the data frames
orthologs <- merge(species_df, OGS_df, by = "taxon_id", all = TRUE)

#### Make a simplified version of the output
if (simplified_output == TRUE) {
  orthologs <- orthologs[, c("sciname", "LOC_id")]
}

if (output == TRUE) {
  if (dir.exists("outputs") == FALSE) { # Checks for outputs directory and creates outputs/ if not
    dir.create("outputs")
  }
  write.csv(orthologs, paste0("outputs/", gene, "_orthologs.csv")) # writes output csv to file
}

