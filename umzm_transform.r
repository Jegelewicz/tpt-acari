# add libraries
library(readxl)
library(data.table)
library(stringi)
library(taxotools)
library(dplyr)

# define function: name length
name_length <- function(x) ifelse(!is.na(x), length(unlist(strsplit(x, ' '))), 0)

# define function: is not in
'%!in%' <- function(x,y)!('%in%'(x,y))

# define right function
right = function (string, char) {
  substr(string,(char + 1),nchar(string))
}

# define left function
left = function (string,char) {
  substr(string,1,char - 1)
}

# read in file
mite_may_2020 <- read_excel("input/mite may 2020.xlsx", col_types = c("text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text"))
df <- mite_may_2020 # change filename for ease of use
# df <- df[-which(apply(df,1,function(x)all(is.na(x)))),] # remove empty rows
original_rows <- nrow(df)
tpt_dwc_template <- read_excel("input/tpt_dwc_template.xlsx") # read in TPT DarwinCore template
tpt_dwc_template[] <- lapply(tpt_dwc_template, as.character) # set all columns in template to character

# transform column headers
colnames(df) <- tolower(colnames(df)) # lower case column names

# define DwC conversion
convert2DwC <- function(df_colname) {
  x <- gsub('.*subspecies.*','infraspecificEpithet',df_colname)
  x <- gsub('.*rank.*','taxonRank',x)
  x <- gsub('.*author.*','scientificNameAuthorship',x)
  x <- gsub('.*species.*','specificEpithet',x)
  x
}

colnames(df) <- convert2DwC(colnames(df)) # convert to DarwinCore terms

df <- rbindlist(list(df, tpt_dwc_template), fill = TRUE) # add all DwC columns

df$TPTdataset <- "UMZM" # add dataset name
df$TPTID <- seq.int(nrow(df)) # add numeric ID for each name

df$kingdom <- "Animalia" # add kingdom
df$phylum <- "Arthropoda" # add phylum

# clean up
# define function: remove '\xa0' chars and non-conforming punctuation
phrase_clean <- function(x) gsub("[^[:alnum:][:blank:]&,()];", "", x)
space_clean <- function(x) gsub("  ", " ", x)

# remove remove '\xa0' chars
setDT(df)
cols_to_be_rectified <- names(df)[vapply(df, is.character, logical(1))]
df[,c(cols_to_be_rectified) := lapply(.SD, phrase_clean), .SDcols = cols_to_be_rectified]

# strip spaces from ends of strings
setDT(df)
cols_to_be_rectified <- names(df)[vapply(df, is.character, logical(1))]
df[,c(cols_to_be_rectified) := lapply(.SD, trimws), .SDcols = cols_to_be_rectified]

# strip double spaces
setDT(df)
cols_to_be_rectified <- names(df)[vapply(df, is.character, logical(1))]
df[,c(cols_to_be_rectified) := lapply(.SD, space_clean), .SDcols = cols_to_be_rectified]

# split specificEpithet when it has two terms
# multi_epithet <- df[which(lapply(df$specificEpithet, name_length) > 1),] # extract rows with a multi-name specifies
# df <- df[which(lapply(df$specificEpithet, name_length) <= 1),] # extract rows with a multi-name specifies

# for(i in 1:nrow(multi_epithet)){
#   multi_epithet$specificEpithet[i] <- left(multi_epithet$species[i], unlist(gregexpr(pattern = " ", multi_epithet$species[i]))) # place first term in specificEpithet
#   multi_epithet$infraspecificEpithet[i] <- right(multi_epithet$species[i], unlist(gregexpr(pattern = " ", multi_epithet$species[i]))) # place second term in infraspecificEpithet
# }
# 
# # strip spaces from ends of strings
# setDT(multi_epithet)
# cols_to_be_rectified <- names(multi_epithet)[vapply(multi_epithet, is.character, logical(1))]
# multi_epithet[,c(cols_to_be_rectified) := lapply(.SD, trimws), .SDcols = cols_to_be_rectified]
# 
# # strip double spaces
# setDT(multi_epithet)
# cols_to_be_rectified <- names(multi_epithet)[vapply(multi_epithet, is.character, logical(1))]
# multi_epithet[,c(cols_to_be_rectified) := lapply(.SD, space_clean), .SDcols = cols_to_be_rectified]

# df$specificEpithet <- df$species # place single term species names in specificEpithet

# df <- rbind(df,multi_epithet) # return subspecies to working file

# # create scientificNameAuthorship which meets DarwinCore standard for ICZN
# for(i in 1:nrow(df)){
#   df$scientificNameAuthorship[i] <- ifelse(is.na(df$namePublishedInYear[i]) &
#                                              is.na(df$author[i]), NA, # if both author and year are blank, insert NA
#                                            ifelse(is.na(df$namePublishedInYear[i]),df$author[i], # if author is not blank but year is, insert author
#                                                   ifelse(is.na(df$author[i]), df$namePublishedInYear[i], # if author is blank, but year is not, insert year
#                                                          paste(df$author[i], df$namePublishedInYear[i], sep = ', ')) # if both author and year are NOT blank merge and insert
#                                            )
#   )
# }
# 
# fixAuth <- function(x) ifelse(grepl('[a-z]),',x), paste(gsub(')', '',x),')',sep=''),x) # define function to fix cases like: (Jordan & Rothschild), 1922
# df$scientificNameAuthorship <- fixAuth(df$scientificNameAuthorship) # apply fix

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


# Extract rows from higher taxa that need review
flag <- c('review')
review_canonical <- higher_taxa[(higher_taxa$canonical %in% flag), ]
write.csv(review_canonical,"~/GitHub/tpt-acari/output/review_canonical.csv", row.names = FALSE) # these need review
higher_taxa <- higher_taxa[(higher_taxa$canonical %!in% flag), ] # extract review items from higher_taxa

if(nrow(review_canonical) == 0){
  print('No canonical names in higher_taxa have been flagged for review. Proceed to deduplication.')
  df <- rbind(higher_taxa, df) # add higher taxa back to df for remainder of de-duplication
} else{
  stop('Open the review_canonical file in the output folder, make adjustments as appropriate and save the revised file to input as reviewed_canonical.xlsx before proceeding')
  
  # after review add back cleaned up names
  reviewed_canonical <- read_excel("input/reviewed_canonical.xlsx") # read in cleaned review file
  higher_taxa <- rbind(higher_taxa, reviewed_canonical) # add reviewed higher_taxa back to the working file
  df <- rbind(higher_taxa, df) # add higher taxa back to df for remainder of de-duplication
}

# order column names
#df[,c(1,2,3,4)]. Note the first comma means keep all the rows, and the 1,2,3,4 refers to the columns.
df <- df[,c("TPTdataset", 
            "TPTID", 
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

# review for duplicates
dupe <- df[,c('canonicalName','taxonRank')] # select columns to check duplicates
review_dups <- df[duplicated(dupe) | duplicated(dupe, fromLast=TRUE),]
df <- anti_join(df, review_dupes, by = "TPTID") # remove duplicate rows from working file

# write and review duplicates then add back to working file
write.csv(review_dups,"~/GitHub/tpt-acari/output/review_duplicates.csv", row.names = FALSE) # these need review
print("after review of duplicates, save return file to ~/GitHub/tpt-acari/input/reviewed_duplicates.xlsx")

reviewed_duplicates <- read_excel("input/reviewed_duplicates.xlsx") # read in cleaned duplicates
df <- rbind(df, reviewed_duplicates)

write.csv(df,"~/GitHub/tpt-acari/output/UMZM_Acari.csv", row.names = FALSE) # ready for analysis