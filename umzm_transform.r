# read in file
mite_may_2020 <- read_excel("input/mite may 2020.xlsx", col_types = c("text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text"))
df <- mite_may_2020 # change filename for ease of use
original_rows <- nrow(df)
tpt_dwc_template <- read_excel("input/tpt_dwc_template.xlsx") # read in TPT DarwinCore template
tpt_dwc_template[] <- lapply(tpt_dwc_template, as.character) # set all columns in template to character

# transform column headers
colnames(df) <- tolower(colnames(df)) # lower case column names

colnames(df) <- convert2DwC(colnames(df)) # convert to DarwinCore terms

df <- rbindlist(list(df, tpt_dwc_template), fill = TRUE) # add all DwC columns

df$source <- "TPT" # add dataset name
df$taxonID <- seq.int(nrow(df)) # add numeric ID for each name

df$kingdom <- "Animalia" # add kingdom
df$phylum <- "Arthropoda" # add phylum

df <- char_fun(df,phrase_clean) # remove xa0 characters
df <- char_fun(df,trimws) # trim white space
df <- char_fun(df,space_clean) # change double spaces to single

# cast canonical name
df$canonicalName <- NA # create column for canonicalName

# extract higher taxa for next set of review
higher_taxa <- df[which(lapply(df$infraspecificEpithet, name_length) == 0 & lapply(df$specificEpithet, name_length) == 0),]
df <- df[which(lapply(df$infraspecificEpithet, name_length) != 0 | lapply(df$specificEpithet, name_length) != 0),]

# generate canonical name for species and below
df <- cast_canonical(df,
                     canonical="canonicalName", 
                     genus = "genus", 
                     species = "specificEpithet",
                     subspecies = "infraspecificEpithet")

# generate taxonRank for species and below
for(i in 1:nrow(df)){
  df$taxonRank[i] <- 
    ifelse(!is.na(df$infraspecificEpithet[i]), "subspecies",
           ifelse(!is.na(df$specificEpithet[i]), "species",
                  "review"))
}

# canonical names for taxa ranked subgenus and above - get the lowest ranking term and put it here!
for(i in 1:nrow(higher_taxa)){
  higher_taxa$canonicalName[i] <- ifelse(!is.na(higher_taxa$subgenus[i]), paste(higher_taxa$subgenus[i]),
                                         ifelse(!is.na(higher_taxa$genus[i]), paste(higher_taxa$genus[i]),
                                                ifelse(!is.na(higher_taxa$subtribe[i]), paste(higher_taxa$subtribe[i]),
                                                       ifelse(!is.na(higher_taxa$tribe[i]), paste(higher_taxa$tribe[i]),
                                                              ifelse(!is.na(higher_taxa$subfamily[i]), paste(higher_taxa$subfamily[i]),
                                                                     ifelse(!is.na(higher_taxa$family[i]), paste(higher_taxa$family[i]),
                                                                            ifelse(!is.na(higher_taxa$superfamily[i]), paste(higher_taxa$superfamily[i]),
                                                                                   ifelse(!is.na(higher_taxa$hyporder[i]), paste(higher_taxa$hyporder[i]),
                                                                                          ifelse(!is.na(higher_taxa$infraorder[i]), paste(higher_taxa$infraorder[i]),
                                                                                                 ifelse(!is.na(higher_taxa$suborder[i]), paste(higher_taxa$suborder[i]),
                                                                                                        ifelse(!is.na(higher_taxa$order[i]), paste(higher_taxa$order[i]),
                                                                                                               ifelse(!is.na(higher_taxa$superorder[i]), paste(higher_taxa$superorder[i]),
                                                                                                                      ifelse(!is.na(higher_taxa$subclass[i]), paste(higher_taxa$subclass[i]),
                                                                                                                             ifelse(!is.na(higher_taxa$class[i]), paste(higher_taxa$class[i]),
                                                                                                                                    ifelse(!is.na(higher_taxa$phylum[i]), paste(higher_taxa$phylum[i]),
                                                                                                                                           ifelse(!is.na(higher_taxa$kingdom[i]), paste(higher_taxa$kingdom[i]), "review"))))))))))))))))
}

# generate taxonRank for subgenus and above
for(i in 1:nrow(higher_taxa)){
  higher_taxa$taxonRank[i] <- 
    ifelse(!is.na(higher_taxa$subgenus[i]), "subgenus",
      ifelse(!is.na(higher_taxa$genus[i]), "genus",
             ifelse(!is.na(higher_taxa$subtribe[i]), "subtribe",
                    ifelse(!is.na(higher_taxa$tribe[i]), "tribe",
                        ifelse(!is.na(higher_taxa$subfamily[i]), "subfamily",
                            ifelse(!is.na(higher_taxa$family[i]), "family",
                                   ifelse(!is.na(higher_taxa$superfamily[i]), "superfamily",
                                          ifelse(!is.na(higher_taxa$hyporder[i]), "hyporder",
                                                 ifelse(!is.na(higher_taxa$infraorder[i]), "infraorder",
                                                        ifelse(!is.na(higher_taxa$suborder[i]), "suborder",
                                                               ifelse(!is.na(higher_taxa$order[i]), "order",
                                                                      ifelse(!is.na(higher_taxa$superorder[i]), "superorder",
                                                                             ifelse(!is.na(higher_taxa$subclass[i]), "subclass",
                                                                                    ifelse(!is.na(higher_taxa$class[i]), "class",
                                                                                           ifelse(!is.na(higher_taxa$phylum[i]), "phylum",
                                                                                                  ifelse(!is.na(higher_taxa$kingdom[i]), "kingdom",
                                                                                                         "review"))))))))))))))))
}

# cast scientific name for species and below
df$scientificName[i] <- for(i in 1:nrow(df)){
  if(!is.na(df$genus[i])){
    scn <- df$genus[i]
  }
  if(!is.na(df$subgenus[i])){
    scn <- paste(scn," (",df$subgenus[i],")",sep = "")
  }
  if(!is.na(df$specificEpithet[i])){
    scn <- paste(scn,df$specificEpithet[i], sep = " ")
  }
  if(!is.na(df$infraspecificEpithet[i])){
    scn <- paste(scn,df$infraspecificEpithet[i], sep = " ")
  }
  if(!is.na(df$scientificNameAuthorship[i])){
    scn <- paste(scn,trimws(df$scientificNameAuthorship[i]), sep = " ")
  }
  df$scientificName[i] <- scn
}

# cast scientific name for genus and above
higher_taxa$scientificName <- ifelse(is.na(higher_taxa$scientificNameAuthorship), higher_taxa$canonicalName, paste(higher_taxa$canonicalName, higher_taxa$scientificNameAuthorship, sep = " "))

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

# # review for duplicates
# dupe <- df[,c('canonicalName')] # select columns to check duplicates
# review_dups <- df[duplicated(dupe) | duplicated(dupe, fromLast=TRUE),]
# df <- anti_join(df, review_dups, by = "TPTID") # remove duplicate rows from working file

# # write and review duplicates then add back to working file
# write.csv(review_dups,"~/GitHub/tpt-acari/output/review_duplicates.csv", row.names = FALSE) # these need review
# print("after review of duplicates, save return file to ~/GitHub/tpt-acari/input/reviewed_duplicates.xlsx")
# 
# reviewed_duplicates <- read_excel("input/reviewed_duplicates.xlsx") # read in cleaned duplicates
# df <- rbind(df, reviewed_duplicates)

write.csv(df,"~/GitHub/tpt-acari/output/Acari_DwC.csv", row.names = FALSE) # ready for analysis
