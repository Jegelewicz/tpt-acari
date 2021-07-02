# Teresa's merge

UMZM <- read.csv("~/GitHub/tpt-acari/output/Acari_DwC.csv", na = "NA") # read in cleaned Lewis review file
GBIF <- read.csv("~/GitHub/tpt-acari/output/GBIF_DwC.csv", na = "NA") # read in cleaned GBIF review file

# Names in sources other than UMZM
GBIF_not_UMZM <- GBIF[which(GBIF$canonicalName %!in% UMZM$canonicalName),]
write.csv(GBIF_not_UMZM,"~/GitHub/tpt-acari/output/Not in UMZM.csv", row.names = FALSE) # names not in Lewis

# UMZM names in sources other than UMZM
# GBIF_in_UMZM <- GBIF[which(GBIF$canonicalName %in% UMZM$canonicalName),]
# GBIF_in_UMZM$source <- "UMZM, GBIF"

UMZM_not_GBIF <- UMZM[which(UMZM$canonicalName %!in% GBIF$canonicalName),] # get names in UMZM but not GBIF
UMZM_in_GBIF <- UMZM[which(UMZM$canonicalName %in% GBIF$canonicalName),] # get names in UMZM and GBIF
UMZM_in_GBIF$source <- "UMZM, GBIF"

df <- rbind.fill(GBIF_not_UMZM,UMZM_in_GBIF,UMZM_not_GBIF)

# order column names
#df[,c(1,2,3,4)]. Note the first comma means keep all the rows, and the 1,2,3,4 refers to the columns.
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
            "subclass",
            "superorder",
            "order", 
            "suborder",
            "infraorder",
            "hyporder",
            "superfamily",
            "family",	
            "subfamily",
            "tribe",
            "subtribe",
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

df <- df[
  with(df, order(df$order, df$family, df$genus, df$subgenus, df$specificEpithet, df$infraspecificEpithet)),
] # sort by taxonomic classes

write.csv(df,"~/GitHub/tpt-acari/output/acari_merged.csv", row.names = FALSE) # names in UMZM

# temp <- GBIF_in_UMZM[which(duplicated(GBIF_in_UMZM$canonicalName)),] # look for dup canonicals
# write.csv(temp,"~/GitHub/tpt-acari/output/more_dupes.csv", row.names = FALSE)

# # remove BOLD Names
# GBIF_BOLD <- df1[which(startsWith(df1$scientificName, "BOLD:")),] # get the BOLD names
# df1 <- df1[which(startsWith(df1$scientificName, "BOLD:") == FALSE),] # remove BOLD names
# 
# df1$suggested <- NA # initialize suggestion column
# 
# # match up species with subspecies
# dfsub <- df[which(df$specificEpithet == df$infraspecificEpithet),] # get the original subspecies
# dfsub$spec <- paste(dfsub$genus,dfsub$specificEpithet, sep = " ") # remove the infraspecific epithet
# 
# for (i in 1:nrow(df1)){
#   if (df1$canonicalName[i] %in% dfsub$spec){
#     df1$suggested[i] <- paste(df1$genus[i],df1$specificEpithet[i],df1$specificEpithet[i], sep = " ")    
#   } else {
#     df1$suggested[i] <- NA
#   }
# }
# 
# # match up subspecies with species
# for (i in 1:nrow(df1)){
#   if (is.na(df1$suggested[i])){
#     if (!is.na(df1$infraspecificEpithet[i])){
#       # if (df1$specificEpithet[i] == df1$infraspecificEpithet[i]){
#       pick <- paste(df1$genus[i],df1$infraspecificEpithet[i], sep = " ")
#       df1$suggested[i] <- vlookup(df$canonicalName,pick,df$canonicalName)
#       # }
#     }
#   }
# }
# 
# # Match genera
# df2 <- df1[which(is.na(df1$suggested)),] # Get stuff without suggestions
# df1 <- df1[which(!is.na(df1$suggested)),] # remove stuff without suggestions from working file
# 
# df$pick <- right(df$canonicalName," ")
# df$pickauth <- gsub("[()]","",df$scientificNameAuthorship)
# 
# for (i in 1:nrow(df2)){
#   pick <- right(df2$canonicalName[i]," ")
#   pickauth <- gsub("[()]","",df2$scientificNameAuthorship[i])
#   temp <- df[which(df$pick == pick),]
#   df2$suggested[i] <- vlookup(temp$canonicalName,gsub("[()]","",df2$scientificNameAuthorship[i]),temp$pickauth)
# }
# 
# df$pick <- NULL # remove temporary column
# df$pickauth <- NULL # remove temporary column
# 
# df1 <- rbind(df1,df2) # return suggested names

write.csv(all_names,"~/GitHub/tpt-acari/output/merged_names.csv", row.names = FALSE) # all names