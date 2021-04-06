# tpt-acari
Code for cleaning and merging Acari taxonomy for the Terrestrial Parasite Tracker

## Taxonomy Cleaning for Terrestrial Parasite Tracker Taxonomy

The R script in this repository was designed for cleaning taxonomic classifications received from various sources for the Terrestrial Parasite Tracker Thematic Collections Netowrk (TPT) Taxonomy Reource.

### Input
Input is required to be csv and is expected to include at least the following columns:
 - kingdom
 - phylum
 - class
 - order
 - family
 - genus
 - species (specific epithet)
 - taxon Author name (may be combined with or separate from published year)
 - taxon published year

Other information may be included in the file, including ranks between the standard ranks listed above and subspecific epithets.
**NOTE** All taxonomy fields are expected to include a single term, "species" is really "specific epithet" and "subspecies" is really "infraspecific epithet".

