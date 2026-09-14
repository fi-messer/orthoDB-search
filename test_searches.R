## Start doing some test searches
# Search at Drosophila level
S <- api$search("kmg", level=7215) # run a gene search for kmg
S[["cluster_ids"]] # retrieve the orthologue tree
OGS <- api$orthologs("49125at7215") # get a list of orthologues

# I have a list of orthologues in the orthoDB R6 class object format, but I want to transform it into a dataframe
length(OGS$df$data$genes) # I have 83 genes

df1 <- NULL # make an empty dataframe to store genes in

for (n in (1:(length(OGS$df$data$genes)))) {
  df <- OGS$df$data$genes[[n]]
  df1 <- bind_rows(df1, df)
}

head(df1) # I now have a dataframe containing kmg orthologues in all the Drosophila spp.

# However, my dataframe contains a lot of duplicated information and is quite messy (there are columns I don't need)
# I'll remove the unnecessary columns
drops <- c("interpro", "more_info", "how_much_more_info")
df1 <- df1[, !(names(df1) %in% drops)]
# Much better

# How to deal with the duplicated data? 
# I will get a list of species without duplicates, then use this to filter out the data I don't want from the gene search

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
