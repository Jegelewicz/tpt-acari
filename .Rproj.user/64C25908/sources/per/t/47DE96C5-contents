# read in files
Acari <- read.csv("~/GitHub/tpt-acari/output/Acari_DwC.csv", na = "NA") # read in cleaned Acari Darwin Core file
Acari$taxonomicStatus <- NULL
# Acari$taxonomicStatus <- ifelse(is.na(Acari$taxonomicStatus),"undefined",NMNH$taxonomicStatus) # fill in taxonomic status
Acari_ht <- higher_taxa_rank(Acari, Acari$taxonRank) # NMNH higher taxa
# Acari_species <- species_rank(Acari, Acari$taxonRank) # NMNH species taxa
Acari_taxo <- DwC2taxo(Acari, source = "TPT") # transform to taxotool format

GBIF <- read.csv("~/GitHub/tpt-acari/input/GBIF_acari.csv") # read in GBIF file
GBIF <- GBIF[which(lapply(GBIF$familyy))]

GBIF$taxonomicStatus <- ifelse(GBIF$taxonomicStatus == "homotypic synonym", "homotypicSynonym",
                               ifelse(GBIF$taxonomicStatus == "heterotypic synonym", "heterotypicSynonym", GBIF$taxonomicStatus)) # replace non-conforming status



GBIF_ht <- higher_taxa_rank(GBIF, GBIF$taxonRank) # GBIF higher taxa
# GBIF_species <- species_rank(GBIF, GBIF$taxonRank) # GBIF species taxa
# GBIF <- compact_ids(GBIF,id="taxonID",accid="acceptedNameUsageID") # deal with letters and long ids
GBIF_taxo <- DwC2taxo(GBIF, source = "GBIF") # transform to taxo format

# taxo_siphonaptera <- rbindlist(list(NMNH_taxo, FMNH_taxo, Lewis_taxo, CoL_taxo), fill = TRUE) # combine all taxo files
# siphonaptera_ht <- rbindlist(list(NMNH_ht, FMNH_ht, Lewis_ht, CoL_ht), fill = TRUE) # combine all ht files

#sanity check
original <- nrow(Acari) + nrow(GBIF)
final <- nrow(Acari_taxo) + nrow(Acari_ht) + nrow(GBIF_taxo) + nrow(GBIF_ht)
ifelse(original == final, print("yay"),print("ugh"))

# if yay write out the taxo file
write.csv(df,"~/GitHub/tpt-acari/output/taxo_Acari.csv", row.names = FALSE) # taxo file

# if ugh, find the problem
# merge_probs(GBIF, GBIF$taxonID, GBIF_taxo$id, GBIF_ht$taxonID)
not_in_taxo <- GBIF[GBIF$taxonID %!in% GBIF_taxo$id,] # get all rows in original data (dat) with (datcol) that does not match (taxocol)
problems <- not_in_taxo[not_in_taxo$taxonID %!in% GBIF_ht$taxonID,] # get all rows in above that do not match  original higher geography (htcol)
not_in_taxo <- Acari[Acari$taxonID %!in% Acari_taxo$id,] # get all rows in original data (dat) with (datcol) that does not match (taxocol)
not_in_ht <- not_in_taxo[not_in_taxo$taxonID %!in% Acari_ht$taxonID,] # get all rows in above that do not match  original higher geography (htcol)
problems <- rbind(problems, not_in_ht)

# Mite_merge
Mite_m1 <- merge_lists(GBIF_taxo, Acari_taxo) # master is UNMZ, merging with GBIF
Mite_mast1 <- rbind.fill(GBIF_taxo,Mite_m1$addlist,Mite_m1$noaddlist)
Mite_mast1_1 <- cast_cs_field(Mite_mast1,"canonical","source")

write.csv(Mite_mast1_1,"~/GitHub/tpt-acari/output/taxo_Acari.csv", row.names = FALSE) # taxo file
