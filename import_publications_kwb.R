Sys.setlocale(category = "LC_ALL", locale = "German")

library(dplyr)
library(reticulate)


### Exported from KWB Endnote:
#bib_txt <- "KWB.txt"
#encoding <- "UTF-8"
#org <- readLines(bib_txt, encoding = "UTF-8")


### Saved original "KWB.txt" in Rstudio with
### "Save with Encoding "Windows-1252" and define encoding "latin1" for import
### now works
bib_txt <- "KWB_windows1252.txt"
encoding <- "latin1"

### Import all (same cannot due to parsing errors:
### "The name list field author cannot be parsed"
kwb_bib_all <- RefManageR::ReadBib(bib_txt, 
                                   .Encoding = encoding,
                                   check = FALSE)

## Not working as not all required data are provided for the references
# RefManageR::WriteBib(kwb_bib_all, file = "temp.bib", biblatex = TRUE)

kwb_bib_all_df <- as.data.frame(kwb_bib_all)

nrow(kwb_bib_all_df)

### Import all (same cannot due to parsing errors:
### "The name list field author cannot be parsed"

kwb_bib_valid <-  RefManageR::ReadBib(bib_txt,
                      .Encoding = encoding)

kwb_bib_valid_df <- as.data.frame(kwb_bib_valid)

nrow(kwb_bib_valid_df)

nrow(kwb_bib_valid_df)/nrow(kwb_bib_all_df)


check_technical_report <- function(bib_df,
                                   default_institution = "Kompetenzzentrum Wasser Berlin gGmbH") { 
  

  idx_TechReport <- which(bib_df$bibtype == "TechReport")
  
  if(length(idx_TechReport)>0) {
      print(sprintf("Replacing  missing 'institution' %d entries for 'TechnicalReport'
with %s", length(idx_TechReport), default_institution))
      no_institution_idx <- is.na(bib_df$institution[idx_TechReport]) 
      bib_df$institution[idx_TechReport] <- default_institution 
    
  } else {
   "No missing entries for 'institution' for 'TechnicalReport'"  
  }
  
  bib_df
}

## filter out conference reports in "Misc" not exported correctply
kwb_bib_valid_df_noMisc <-  kwb_bib_valid_df[kwb_bib_valid_df$bibtype != "Misc",] 
nrow(kwb_bib_valid_df_noMisc)                       


# RefManageR::WriteBib(RefManageR::as.BibEntry(kwb_bib_valid_df_noMisc),
#                      file = "publications_kwb.bib") 

###############################################################################
### Step 2: Import .bibtex file to publications with Python 
###############################################################################

## Download Anaconda with Python 3.7 from website (if not installed)
#browseURL("https://www.anaconda.com/download/")

python_path <- "C:/Users/mrustl.KWB/AppData/Local/Continuum/anaconda3"
conda_path <- paste(python_path, "Scripts/conda.exe", sep = "/")
Sys.setenv(RETICULATE_PYTHON = python_path)

reticulate::use_python(python_path)

### Define conda environment name with "env"
env <- "academic"

reticulate::conda_create(envname = env,conda = conda_path)
reticulate::use_condaenv(env,conda_path)

### Install required Python library "academic" 
### for details see:
# browseURL("https://github.com/sourcethemes/academic-admin")

reticulate::py_install(packages = "academic", 
                       envname = env, 
                       pip = TRUE, pip_ignore_installed = TRUE) 


## Should existing publications in content/publication folder be overwritten?
overwrite <- FALSE

option_overwrite <- ifelse(overwrite, "--overwrite", "")

### Create and run "import_bibtex.bat" batch file
cmds <- sprintf('call "%s" activate "%s"\ncd "%s"\nacademic import --bibtex "%s"  %s', 
                normalizePath(file.path(python_path, "Scripts/activate.bat")), 
                env,
                normalizePath(getwd()),
                "publications_kwb.bib",
                option_overwrite)

writeLines(cmds,con = "import_bibtex_kwb.bat")

# repeat a few times due to errors:
for (i in 1:10) {
  shell("import_bibtex_kwb.bat")
}
### Now check the folder "content/publication". Your publications should be added
### now!


bad_pub_ids <- c(380,426)


delete_pubs_with_problems <- function() {
bad_pub_ids <- NA_integer_
hugo_log <- blogdown::hugo_cmd(stdout = TRUE)
pubs_with_problems <- detect_error_pub_id(hugo_log)
while(!is.null(pubs_with_problems)) {
message("Building site..,")
hugo_log <- blogdown::hugo_cmd(stdout = TRUE)
message("Detecting errors..,")
pubs_with_problems <- detect_error_pub_id(hugo_log)
pubids <- paste(as.character(pubs_with_problems), collapse=",")
message(sprintf("%d ids with problems detected:\n%s",
                length(pubs_with_problems), 
                pubids))
message(sprintf("Deleting publication(s): %s", pubids))
delete_publications(pubs_with_problems)
bad_pub_ids <- c(bad_pub_ids, pubs_with_problems)
}
return(bad_pub_ids)
}

bad_pub_ids <- delete_pubs_with_problems()
writeLines(sprintf("RN-%s", bad_pub_ids_saved), "bad_pub_ids.txt")

detect_error_pub_id <- function(hugo_log) {
  ids <- stringr::str_extract(hugo_log, "publication\\\\(rn-[0-9]+)\\\\index.md")
  if(any(!is.na(ids))) {
    ids <- ids[!is.na(ids)] %>% 
      stringr::str_extract_all("[0-9]+", simplify = TRUE) %>% 
      as.numeric()
    if(is.na(ids)) ids <- NULL
  } else {
  message("everything ok")
  ids <- NULL
  } 
  return(ids)
}

delete_publications <- function(pub_ids) {
for(pub_id in pub_ids) {
  pub_dir <- sprintf("content/publication/rn-%d", 
                     pub_id)
  if(dir.exists((pub_dir))) {
fs::dir_delete(pub_dir)
}
}}
# delete_publication(c(380,426))
# blogdown::build_site()
