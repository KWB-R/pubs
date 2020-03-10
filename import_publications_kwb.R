Sys.setlocale(category = "LC_ALL", locale = "German")

library(dplyr)
library(reticulate)

sites <- xsitemap::xsitemapGet("https://www.kompetenz-wasser.de")
projects_site <- sites[sites$origin == "de/project-sitemap.xml",]
project_ids_site <- stringr::str_split_fixed(projects_site$loc, "/", n = 7)[,6]
project_ids_site <- project_ids_site[order(project_ids_site)]

project_ids_dms <- readLines("project-id.txt")

site <- tibble::tibble(project_ids = project_ids_site)
site1 <- cbind(site, source_website = "yes")
dms <- tibble::tibble(project_ids  = readLines("project-id.txt"))

dms1 <- cbind(dms, source_dms = "yes")


ids_all <- dplyr::full_join(site, dms) %>%
  dplyr::arrange(project_ids) %>%  
  left_join(site1) %>%  
  left_join(dms1) 

project_ids_clean <- kwb.utils::multiSubstitute(ids_all$project_ids, 
                                                replacements = list("digitalwatercity" = "dwc", 
                                                                    "networks$" = "networks4", 
                                                                    "ufo-wwv" = "wwv")) %>% 
  unique() 



writeLines(project_ids_clean[order(project_ids_clean)], con = "project-ids.txt")

readr::write_csv2(ids_all, "project-ids_website_dms.csv",na = "")

### Exported from KWB Endnote:
#bib_txt <- "KWB.txt"
#encoding <- "UTF-8"
#org <- readLines(bib_txt, encoding = "UTF-8")


write_lines <- function (text, file, fileEncoding = "", ...)
{
  if (is.character(file)) {
    con <- if (nzchar(fileEncoding)) {
      file(file, "wt", encoding = fileEncoding)
    }
    else {
      file(file, "wt")
    }
    on.exit(close(con))
  }
  else {
    con <- file
  }
  writeLines(text, con, ...)
}

### Saved original "KWB.txt" in Rstudio with
### "Save with Encoding "Windows-1252" and define encoding "latin1" for import
### now works
#bib_txt_path <- "KWB-documents_20191205_no-abstracts.txt"
bib_txt_path <- "KWB-documents_20191205_with-abstracts.txt"
readr::guess_encoding(bib_txt_path)
bib_txt_utf8 <- kwb.fakin::read_lines(bib_txt_path, encoding = "UTF-8", fileEncoding = "UTF-8-BOM")

starts <- which(startsWith(bib_txt_utf8, "@"))

bib_txt_utf8_path <- "KWB_documents_20190709_utf-8.txt"

write_lines(bib_txt_utf8, bib_txt_utf8_path, fileEncoding = "UTF-8")  


encoding = "UTF-8"

# contents <- lapply(starts[-1L], function(i) {
#   
#   print(i)
#   
#   write_lines(bib_txt_utf8[seq_len(i-1)], bib_txt_utf8_path, fileEncoding = "UTF-8")  
# 
#   try(RefManageR::ReadBib(bib_txt_utf8_path, .Encoding = encoding, check = FALSE))
# })


# for(i in starts[-1L]) {
#   
#   print(bib_txt_utf8[i])
#   
#   write_lines(bib_txt_utf8[seq_len(i-1)], bib_txt_utf8_path, fileEncoding = "UTF-8")  
#   
#   try(RefManageR::ReadBib(bib_txt_utf8_path, .Encoding = encoding, check = FALSE))
# }

#readr::write_lines(bib_txt_utf8, bib_txt_utf8_path)

# bib_txt_latin1 <- kwb.fakin::read_lines(bib_txt_path, encoding = "latin1", fileEncoding = "UTF-8-BOM")
# bib_txt_latin1_path <- "KWB_documents_20190709_latin1.txt"
# writeLines(text = bib_txt_latin1, bib_txt_latin1_path)

### Import all (same cannot due to parsing errors:
### "The name list field author cannot be parsed"
encoding = "UTF-8"
kwb_bib_all <- RefManageR::ReadBib(bib_txt_utf8_path, 
                                   .Encoding = encoding,
                                   check = FALSE)



tmp <- lapply(kwb_bib_all, function(x) try(capture.output(x))) 

is_simple_error <- function(x) inherits(x, "simpleError")

is_error <- sapply(lapply(tmp , function(x) attr(x,"condition")), 
                   is_simple_error)

bib_errors_txt <- gsub(pattern = ".*:\\s+\n\\s+", replacement = "", x = unlist(tmp[is_error]))
stringr::str_extract(bib_errors_txt, "^RN[0-9]{1,4}")
bib_errors_df <- tibble::tibble("endnote_record-number" = stringr::str_extract(bib_errors_txt, "^RN[0-9]{1,4}") %>%  
                                  stringr::str_remove("RN") %>%  as.integer(),
                                error_text = stringr::str_extract(bib_errors_txt, pattern = "A bibentry.*")) %>% 
  dplyr::arrange(.data$`endnote_record-number`)

## Not working as not all required data are provided for the references
# RefManageR::WriteBib(kwb_bib_all, file = "temp.bib", biblatex = TRUE)

kwb_bib_all_df <- as.data.frame(kwb_bib_all)

nrow(kwb_bib_all_df)

### Import all (same cannot due to parsing errors:
### "The name list field author cannot be parsed"

kwb_bib_valid <-  RefManageR::ReadBib(bib_txt_utf8_path,
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

## filter out conference reports in "Misc" or "Unpublished" not exported correctply
# kwb_bib_valid_df_noMisc_unpublished <-  kwb_bib_valid_df[!kwb_bib_valid_df$bibtype %in% c("Misc", "Unpublished"),] 
# kwb_bib_valid_df_noMisc_unpublished[kwb_bib_valid_df_noMisc_unpublished$bibtype == "PhdThesis",]
# nrow(kwb_bib_valid_df_noMisc_unpublished)                       
# 
# 
# RefManageR::WriteBib(RefManageR::as.BibEntry(kwb_bib_valid_df_noMisc_unpublished),
#                      file = "publications_kwb.bib") 


RefManageR::WriteBib(RefManageR::as.BibEntry(kwb_bib_valid_df),
                     file = "publications_kwb.bib") 

###############################################################################
### Step 2: Import .bibtex file to publications with Python 
###############################################################################

## Download Anaconda with Python 3.7 from website (if not installed)
#browseURL("https://www.anaconda.com/download/")

#python_path <- "C:/Users/mrustl.KWB/AppData/Local/Continuum/anaconda3"
python_path <- "C:/ProgramData/Anaconda3"
conda_path <- paste(python_path, "Scripts/conda.exe", sep = "/")
Sys.setenv(RETICULATE_PYTHON = python_path)

reticulate::use_python(python_path)

### Define conda environment name with "env"
env <- "academic"

reticulate::conda_create(envname = env)#,conda = conda_path)
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

update_citations <- function(pub_dir = "content/publication") {
  
  stopifnot(fs::dir_exists(pub_dir))
  
  citations <- list.files(pub_dir, pattern = ".bib$", 
                          recursive = TRUE, 
                          full.names = TRUE)
  
  sapply(citations, function(citation) {
    new_cite <- file.path(dirname(citation), "cite.bib")
    if(citation != new_cite) {
      fs::file_move(citation, new_path = new_cite)
    } else {
      message(sprintf("Citation '%s' already up-to-date!"))  
    }
  })
  
}
