#### OrthoDB Drosophila search tool

# species of interest

# gene(s) of interest
species <- NULL
species <- c("melanogaster", "pseudoobscura", "persimilis", "miranda")

gene <- "4805191"

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

#### Extract species information for OGS_df filtering

if (is.data.frame(Dros_spp) == TRUE){
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
# check whether the full species name is listed or not
i <- 1
for (s in species) {
  if (grepl("Drosophila", s, ignore.case = TRUE) == FALSE) {
    species[[i]] <- paste0("Drosophila ", s)
    i <- i +1
  } else {
    print(paste0(s, " correct format"))
  }
} 

species

print(filter(Dros_spp, sciname == c(species)))
