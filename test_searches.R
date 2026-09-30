#### Start doing some test searches
#### Search at Drosophila level
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

# Also going to make the double dataframe situation neater
df1$LOC_id <- df1$gene_id$id
df1$orthoDB_id <- df1$gene_id$param
df1$gene_id <- NULL
# much cleaner

#### How to deal with the duplicated data? 
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

#### Use the species list to filter the gene search output

# use species list taxon_id to filter the results based on matching the gene search dataframe geneid$param

grep(species$taxon_id[1], df1$orthoDB_id) # returns indices of matched pattern

test <- NULL
for (t in (species$taxon_id)) {
  test <- rbind(test, df1[grep(t, (df1$orthoDB_id)),]) # make a database of just the species I want
}

# make a new column in the gene search output of the taxon_id
df1$taxon_id <- NULL
for (n in 1:(length(taxon_id))) {
  for (d in 1:length(df1$orthoDB_id)) {
    if (grepl((taxon_id[n]), df1$orthoDB_id[d]) == TRUE) { # logical, is the taxon id the same as in df1$gene_id$param
      df1$taxon_id[d] <- taxon_id[n] # print the taxon id to a new column in df1
    }
  }
}

# Now I have the correct taxon id for each line in the search output, I can combine it with my species list

TEST2 <- merge.data.frame(species, df1, by = "taxon_id", all.x = TRUE, all.y = FALSE)
# This makes a large dataframe with all of the information in it.
# Make a simplified version
TEST3 <- TEST2 |> select("taxon_id", "sciname", "description", "LOC_id", "orthoDB_id")

#### Filter based on a particular set of species
list <- c("drosophila pseudoobscura", "Drosophila miranda", "Drosophila affinis")
TEST3 %>% filter(sciname %in% list) # works well if you type out the full name, doesn't allow for wrong case or missing values

# Try a grep method, should allow for more flexibility in species input
i <- 1
for (l in list) {
  vectors[[i]] <- grep(l, TEST3$sciname, value = FALSE, ignore.case = TRUE)
  i <- i + 1
  print(vectors)
} # loop writes list of row numbers for species in list
final_output <- TEST3[vectors, ] # use list of row numbers to filter the large dataframe to just the search species.
