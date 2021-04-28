# read in files
Acari <- read.csv("~/GitHub/tpt-acari/output/Acari_DwC.csv", na = "NA") # read in cleaned Acari Darwin Core file
Acari$taxonomicStatus <- NULL
# Acari$taxonomicStatus <- ifelse(is.na(Acari$taxonomicStatus),"undefined",NMNH$taxonomicStatus) # fill in taxonomic status
Acari_ht <- higher_taxa_rank(Acari, Acari$taxonRank) # NMNH higher taxa
# Acari_species <- species_rank(Acari, Acari$taxonRank) # NMNH species taxa
taxo_acari <- DwC2taxo(Acari, source = "UMZM") # transform to taxotool format

#sanity check
original <- nrow(Acari)
final <- nrow(taxo_acari) + nrow(Acari_ht)
ifelse(original == final, print("yay"),print("ugh"))

# if yay write out the taxo file
write.csv(df,"~/GitHub/tpt-acari/output/taxo_Acari.csv", row.names = FALSE) # taxo file

# if ugh, find the problem
CoL_not_in_taxo <- CoL[CoL$taxonID %!in% CoL_taxo$id,] # get all rows in CoL that do not match an id in taxo
problems <- CoL_not_in_taxo[CoL_not_in_taxo$taxonID %!in% CoL_ht$taxonID,] # get all rows in above that do not match an id in CoL_ht
