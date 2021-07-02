# GBIF taxo conversion
GBIF <- read_excel("~/GitHub/tpt-acari/input/GBIF_acari.xlsx") # read in GBIF file
Ticks <- GBIF[which(GBIF$family == "Ixodidae"),] # ticks
df <- GBIF[which(GBIF$taxonID %!in% Ticks$taxonID),] # remove ticks

GBIF_origin <- df # keep original file for sanity check

tpt_dwc_template <- read_excel("input/tpt_dwc_template.xlsx") # read in TPT DarwinCore template
df <- rbindlist(list(df, tpt_dwc_template), fill = TRUE) # add all DwC columns

# ensure no NA in taxonomicStatus
for (i in 1:nrow(df)){
  if (is.na(df$taxonomicStatus[i])) {
    df$taxonomicStatus[i] <- "doubtful"
  }
}

# add dataset for accepted taxa without one
for (i in 1:nrow(df)){
  if (is.na(df$datasetID[i]) & df$taxonomicStatus[i] == "accepted") {
    df$datasetID[i] <- "TPT"
  }
}

# get accepted names
temp <- df[which(!is.na(df$acceptedNameUsageID)),] # get all rows with an accepted name ID
df <- df[which(is.na(df$acceptedNameUsageID)),] # remove rows with accepted name ID
for (i in 1:nrow(temp)){
temp$acceptedNameUsage[i] <- vlookup(df$canonicalName,temp$acceptedNameUsageID[i],df$taxonID) # get canonical name of matching taxon ID
}
df <- rbind(df,temp) # add back rows with accepted names

df_nodataset <- df[which(is.na(df$datasetID)),] # get taxa with no dataset ID
df_nodataset$reason <- "no dataset"
df <- df[which(!is.na(df$datasetID)),] # remove rows with no dataset ID
df_misapplied <- df[which(df$taxonomicStatus == "misapplied"),] # get taxa with taxonomic status of misapplied - what does that mean?
df_misapplied$reason <- "misapplied"
df <- df[which(df$taxonID %!in% df_misapplied$taxonID),] # remove rows with taxonomicStatus = misapplied - don't know how to treat
# check for duplicate names 
df$reason <- c(ifelse(duplicated(df$scientificName, fromLast = TRUE)  | duplicated(df$scientificName),
                        "duplicate", NA)) # Flag internal dupes
df_dupes_review <- df[which(grepl('duplicate',df$reason) == TRUE), ]  # get duplicates for review
df <- df[which(grepl('duplicate',df$reason) == FALSE), ] # remove all dupes from working file
df_dupes_keep <- df_dupes_review[which(df_dupes_review$Dataset == "NEW"),]
df_dupes_keep <- df_dupes_keep[which(!duplicated(df_dupes_keep$canonicalName)),]
df_dupes <- df_dupes_review[which(df_dupes_review$taxonID %!in% df_dupes_keep$taxonID),]
df <- rbind(df, df_dupes_keep, fill=TRUE)
df_removed <- rbindlist(list(df_dupes, df_misapplied, df_nodataset), fill = TRUE)
df$source <- "GBIF"

# Do this after final review...
df_non_dwc <- subset(df, select = c(source, taxonID, Dataset, datasetID, genericName, reason)) # get all columns that are not DwC
# remove non DwC columns from working file
df$Dataset <- NULL
df$datasetID <- NULL
df$genericName <- NULL
df$reason <- NULL
# add subfamily column for consistency
df$subfamily <- NA

# order column names
# df[,c(1,2,3,4)]. Note the first comma means keep all the rows, and the 1,2,3,4 refers to the columns.
df <- df[,c("source",
                "taxonID",
                "scientificNameID",
                "acceptedNameUsageID",
                "parentNameUsageID",
                "originalNameUsageID",
                "nameAccordingToID",
                "namePublishedInID",
                "taxonConceptID",
                "scientificName",
                "acceptedNameUsage",
                "parentNameUsage",
                "originalNameUsage",
                "nameAccordingTo",
                "namePublishedIn",
                "namePublishedInYear",
                "higherClassification",
                "kingdom",
                "phylum",
                "class",
                "order",
                "family",
                "subfamily",
                "genus",
                "subgenus",
                "specificEpithet",
                "infraspecificEpithet",
                "taxonRank",
                "verbatimTaxonRank",
                "scientificNameAuthorship",
                "vernacularName",
                "nomenclaturalCode",
                "taxonomicStatus",
                "nomenclaturalStatus",
                "taxonRemarks",
                "canonicalName"
)]

# sanity check
original <- nrow(GBIF_origin) # number of rows in cleaned file
final <- nrow(df) + nrow(df_removed) # number of rows in converted taxo file plus number of rows in higher taxa
if(original == final) { 
  write.csv(df,"~/GitHub/tpt-acari/output/GBIF_DwC.csv", row.names = FALSE) # write out transformed GBIF DwC
  write.csv(df_removed,"~/GitHub/tpt-acari/output/GBIF_removed.csv", row.names = FALSE) # write out removed rows
  write.csv(df_non_dwc,"~/GitHub/tpt-acari/output/GBIF_non_DwC.csv", row.names = FALSE) # write out removed rows  
  print("YAY")
} else {
  print("rows are missing")
}
