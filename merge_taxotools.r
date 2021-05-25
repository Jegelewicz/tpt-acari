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
GBIF_Ixodida <- GBIF[which(GBIF$order == "Ixodida"),] # get ticks which are treated elsewhere
GBIF <- GBIF[which(GBIF$order != "Ixodida"),] # remove ticks which are treated elsewhere
GBIF_misapplied <- GBIF[which(GBIF$taxonomicStatus == "misapplied"),] # get taxa with taxonomic status of misapplied - what does that mean?
GBIF <- GBIF[which(GBIF$taxonomicStatus != "misapplied"),] # remove rows with taxonomicStatus = misapplied - don't know how to treat
# check for duplicate names 
GBIF$dupe_dataset <- c(ifelse(duplicated(GBIF$canonicalName, fromLast = TRUE)  | duplicated(GBIF$canonicalName),
                                           "GBIF", NA)) # Flag internal dupes
GBIF_dupes_review <- GBIF[which(grepl('GBIF',GBIF$dupe_dataset) == TRUE), ]  # get duplicates for review
GBIF <- GBIF[which(grepl('GBIF',GBIF$dupe_dataset) == FALSE), ] # remove all dupes from working file
write.csv(GBIF_dupes_review,"~/GitHub/tpt-acari/output/GBIF_duplicates.csv", row.names = FALSE) # write out duplicates file for review
GBIF <- GBIF[which(!duplicated(GBIF$canonical)),] # deduplicated list

GBIF_ht <- higher_taxa_rank(GBIF, GBIF$taxonRank) # get GBIF higher taxa (DwC2taxo removes them, this is to check rows later)
GBIF_taxo <- DwC2taxo(GBIF, source = "GBIF", statuslist = c("Accepted", "Synonym", "Valid", "heterotypicSynonym",
                      "homotypicSynonym", "doubtful", "proparte synonym", "misapplied")) # transform to taxo format

# sanity check
original <- nrow(GBIF) # number of rows in cleaned file
final <- nrow(GBIF_taxo) + nrow(GBIF_ht) # number of rows in converted taxo file plus number of rows in higher taxa
if(original == final) { 
  write.csv(GBIF_taxo,"~/GitHub/tpt-acari/output/GBIF_taxo.csv", row.names = FALSE) # write out taxo file for review
  print("yay") # print yay if no rows are missing
  } else {
  GBIF_not_in_taxo <- GBIF[GBIF$taxonID %!in% GBIF_taxo$id,] # get all rows in GBIF that do not match an id in taxo
  print("rows are missing see GBIF_not_in_taxo") # print yay if no rows are missing
  }

# taxo Mite_merge
Mite_m1 <- merge_lists(GBIF_taxo, Acari_taxo, "all") # master is GBIF, merging with Acari

# sanity check
taxo_acari <- rbindlist(list(Acari_taxo, GBIF_taxo), fill = TRUE) # combine all taxo files
acari_ht <- rbindlist(list(Acari_ht, GBIF_ht), fill = TRUE) # combine all ht files
original <- nrow(Acari) + nrow(GBIF) # get original number of rows in cleaned files
final <- nrow(taxo_acari) + nrow(acari_ht) # get final number of rows in converted taxo files and add to rows in higher taxa files
ifelse(original == final, write.csv(Mite_mast1_1,"~/GitHub/tpt-acari/output/taxo_acari.csv", row.names = FALSE), # if no rows are missing write taxo file
       print("there are rows missing")) # if rows are missing, print error

Acari_checklist <- taxo2doc(Mite_m1,
                                   mastersource="GBIF",
                                   duplicatesyn=FALSE,
                                   outformat="html_document",
                                   outdir="C:/Users/Teresa/OneDrive/Documents/GitHub/tpt-acari/output/",outfile="Mite_taxolist.html")
