# Acari taxo conversion
Acari <- read.csv("~/GitHub/tpt-acari/output/Acari_DwC.csv", na = "NA") # read in cleaned Acari Darwin Core file
Acari$taxonomicStatus <- NULL # Acari does not contain status, so NULL it
Acari_ht <- higher_taxa_rank(Acari, Acari$taxonRank) # Acari higher taxa
Acari_taxo <- DwC2taxo(Acari, source = "TPT") # transform to taxotool format

# sanity check
original <- nrow(Acari) # number of rows in cleaned file
final <- nrow(Acari_taxo) + nrow(Acari_ht) # number of rows in converted taxo file plus number of rows in higher taxa
if(original == final) { 
  write.csv(Acari_taxo,"~/GitHub/tpt-acari/output/Acari_taxo.csv", row.names = FALSE) # write out taxo file for review
  print("yay") # print yay if no rows are missing
} else {
  Acari_not_in_taxo <- Acari[Acari$taxonID %!in% Acari_taxo$id,] # get all rows in Acari that do not match an id in taxo
  Acari_problems <- Acari_not_in_taxo[Acari_not_in_taxo$taxonID %!in% Acari_ht$taxonID,] # get all rows in above that do not match an id in Acari_ht
  Acari_problems$taxonomicStatus <- NULL # status is the most likely issue, so NULL it
  Acari_problems_taxo <- DwC2taxo(Acari_problems, source = "Acari") # transform problems to taxo format)
  Acari_taxo <- rbind(Acari_taxo, Acari_problems_taxo) # return converted problems to working file
  final <- nrow(Acari_taxo) + nrow(Acari_ht) # recalculate number of rows in converted taxo file plus number of rows in higher taxa
  if(original == final) { print("yay") # print yay if no rows are missing
  } else {
    Acari_ugh <- Acari_problems[Acari_problems$taxonID %!in% Acari_problems_taxo$id,] # get all rows in taxo that do not match an id in problems
    write.csv(Acari_ugh,"~/GitHub/tpt-acari/output/Acari_problems.csv", row.names = FALSE) # write out problems for review
  }
}

# GBIF taxo conversion
GBIF <- read_excel("~/GitHub/tpt-acari/input/GBIF_acari.xlsx") # read in GBIF file
GBIF$taxonomicStatus <- ifelse(GBIF$taxonomicStatus == "homotypic synonym", "homotypicSynonym",
                               ifelse(GBIF$taxonomicStatus == "heterotypic synonym", "heterotypicSynonym", GBIF$taxonomicStatus)) # replace non-conforming status

GBIF$class <- "Arachnida" # Acari file is missing class, add it
GBIF$taxonID <- as.numeric(GBIF$taxonID) # ensure that id column is numeric
GBIF_ht <- higher_taxa_rank(GBIF, GBIF$taxonRank) # get GBIF higher taxa (DwC2taxo removes them, this is to check rows later)
GBIF_taxo <- DwC2taxo(GBIF, source = "GBIF") # transform to taxo format

# sanity check
original <- nrow(GBIF) # number of rows in cleaned file
final <- nrow(GBIF_taxo) + nrow(GBIF_ht) # number of rows in converted taxo file plus number of rows in higher taxa
if(original == final) { 
  write.csv(GBIF_taxo,"~/GitHub/tpt-acari/output/GBIF_taxo.csv", row.names = FALSE) # write out taxo file for review
  print("yay") # print yay if no rows are missing
} else {
  GBIF_not_in_taxo <- GBIF[GBIF$taxonID %!in% GBIF_taxo$id,] # get all rows in GBIF that do not match an id in taxo
  GBIF_problems <- GBIF_not_in_taxo[GBIF_not_in_taxo$taxonID %!in% GBIF_ht$taxonID,] # get all rows in above that do not match an id in GBIF_ht
  GBIF_problems$taxonomicStatus <- NULL # status is the most likely issue, so NULL it
  GBIF_problems_taxo <- DwC2taxo(GBIF_problems, source = "GBIF") # transform problems to taxo format)
  GBIF_taxo <- rbind(GBIF_taxo, GBIF_problems_taxo) # return converted problems to working file
  final <- nrow(GBIF_taxo) + nrow(GBIF_ht) # recalculate number of rows in converted taxo file plus number of rows in higher taxa
  if(original == final) { print("yay") # print yay if no rows are missing
  } else {
    GBIF_ugh <- GBIF_problems[GBIF_problems$taxonID %!in% GBIF_problems_taxo$id,] # get all rows in taxo that do not match an id in problems
    write.csv(GBIF_ugh,"~/GitHub/tpt-acari/output/GBIF_problems.csv", row.names = FALSE) # write out problems for review
  }
}

# taxo Mite_merge
Mite_m1 <- merge_lists(GBIF_taxo, Acari_taxo) # master is GBIF, merging with Acari
Mite_mast1 <- rbind.fill(GBIF_taxo,Mite_m1$addlist,Mite_m1$noaddlist)
Mite_mast1_1 <- cast_cs_field(Mite_mast1,"canonical","source")

# sanity check
taxo_acari <- rbindlist(list(Acari_taxo, GBIF_taxo), fill = TRUE) # combine all taxo files
acari_ht <- rbindlist(list(Acari_ht, GBIF_ht), fill = TRUE) # combine all ht files
original <- nrow(Acari) + nrow(GBIF) # get original number of rows in cleaned files
final <- nrow(taxo_acari) + nrow(acari_ht) # get final number of rows in converted taxo files and add to rows in higher taxa files
ifelse(original == final, write.csv(Mite_mast1_1,"~/GitHub/tpt-acari/output/taxo_acari.csv", row.names = FALSE), # if no rows are missing write taxo file
       print("there are rows missing")) # if rows are missing, print error
