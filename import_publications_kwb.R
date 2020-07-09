
remotes::install_github("kwb-r/kwb.pubs@dev")
library(kwb.pubs)

### Update KWB authors 
authors_config <- kwb.pubs::get_authors_config()
authors_config$lastname <- gsub("tatis muvdi", "tatis-muvdi", authors_config$lastname)

authors_metadata <- kwb.pubs::add_authors_metadata(authors_config)

construct_authorname <- function (firstname, lastname) 
{
  author_firstname <- unlist(lapply(seq_along(firstname), function(idx) {
    tmp <- firstname[idx] %>% stringr::str_trim() %>% stringr::str_split("-|\\s+") %>% 
      unlist() %>% stringr::str_sub(1, 1) %>% stringr::str_to_upper() #%>% 
      #replace_umlauts()
    paste0(sprintf("%s.", tmp), collapse = " ")
  }))
  author_lastname <- lastname %>% stringr::str_trim() %>% stringr::str_replace_all("\\s+", 
                                                                                   " ") %>% stringr::str_to_title() #%>% replace_umlauts()
  sprintf("%s, %s", author_lastname, author_firstname)
}

authors_metadata$author_name <- construct_authorname(authors_metadata$firstname, 
                                                     lastname = authors_metadata$lastname)


authors_metadata$author_name <- gsub("Schubert.*", "Schubert, R.-L.", authors_metadata$author_name)

authors_metadata$fullname <- authors_metadata$author_name

working_at_kwb <- ! authors_metadata$lastname %in% c("ro\u00DFbach", "gnir\u00DF")

authors_metadata <- authors_metadata[working_at_kwb,]

kwb.pubs::add_authors_index_md(authors_metadata, overwrite = TRUE)
kwb.pubs::add_authors_avatar(authors_metadata, overwrite = TRUE)

## Fix avatars for "newcomers" (with own photos, where default values for 
## cropping were not a good choice!)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "habibi",],
                             x_off = 300, width = 380, height = 480)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "toutian",],
                             x_off = 360, y_off = 40, width = 300, height = 400)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "rose",],
                             x_off = 290, y_off = 10, width = 380, height = 400)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "knoche",],
                             x_off = 100)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "conzelmann",],
                             x_off = 230, y_off = 40, height = 250)

fs::dir_delete(path = "content/en/authors")
fs::dir_copy(path = "content/authors", "content/en/authors", overwrite = TRUE)
## currently the same content as in "en" (should be changed to "de"
## required to add a new "config" file)
fs::dir_delete(path = "content/de/authors")
fs::dir_copy(path = "content/authors", "content/de/authors", overwrite = TRUE)
fs::dir_delete(path = "content/authors")


library(dplyr)
library(reticulate)
  
remotes::install_github("pixgarden/xsitemap")

sites <- xsitemap::xsitemapGet("https://www.kompetenz-wasser.de")
projects_site <- sites[sites$origin == "de/project-sitemap.xml",]
project_ids_site <- stringr::str_split_fixed(projects_site$loc, "/", n = 7)[,6]
project_ids_site <- project_ids_site[order(project_ids_site)]

endnote_list <- kwb.endnote::create_endnote_list(endnote_xml = "KWB-documents_20200708.xml")
endnote_df <- kwb.endnote::create_references_df(endnote_list)
#endnote_df <- endnote_df[endnote_df$rec_number %in% updated_ids,]
confidential_pubs_idx <- endnote_df$rec_number[which(endnote_df$caption == "confidential")]

is_public_report <- endnote_df$ref_type_name == "Report" & (endnote_df$caption != "confidential" | is.na(endnote_df$caption))

public_report_ids <- endnote_df$rec_number[is_public_report]

project_ids_dms <- strsplit(x = endnote_df$label[!is.na(endnote_df$label)], 
                            split = ",\\s+") %>% 
  unlist() %>% 
  kwb.pubs::get_unique_project_names()

project_ids_dms_public <- strsplit(x = endnote_df$label[!is.na(endnote_df$label) & endnote_df$caption != "confidential" | is.na(endnote_df$caption)], 
                            split = ",\\s+") %>% 
  unlist() %>% 
  kwb.pubs::get_unique_project_names()



#project_ids_dms <- readLines("project-id.txt")

site <- tibble::tibble(project_ids = project_ids_site)
site1 <- cbind(site, source_website = "yes")
dms <- tibble::tibble(project_ids  = project_ids_dms) %>% 
  dplyr::mutate(project_ids = dplyr::if_else(project_ids == "ufo_wwv", 
                                             "wwv", 
                                             project_ids))

dms1 <- cbind(dms, source_dms = "yes")


ids_all <- dplyr::full_join(site, dms) %>%
  dplyr::arrange(project_ids) %>%  
  dplyr::left_join(site1) %>%  
  dplyr::left_join(dms1) 

all_projects <- ids_all[ids_all$project_ids != "reef2w-2",]
all_projects$project_ids

fs::dir_delete(path = "content/de/project/")
fs::dir_delete(path = "content/en/project/")
### Relax and take a coffee (takes ~ 5 minutes)
kwb.pubs::create_projects(all_projects$project_ids)
fs::dir_copy(path = "content/de/project", "content/en/project", overwrite = TRUE)

### to do: add "links" to KWB project factsheets (add in R package kwb.pubs)



readr::write_csv2(ids_all, "project-ids_website_dms.csv",na = "")

### Import all (same cannot due to parsing errors:
### "The name list field author cannot be parsed"
#options(encoding="windows-1252")
options(encoding="UTF-8-BOM")
tmp <- bib2df::bib2df("KWB-documents_2020708_with-abstracts_caption-label.txt")
tmp$URL <- NA_character_
#tmp$BIBTEXKEY <- gsub("RN", "", tmp$BIBTEXKEY)
tmp$en_id <- as.numeric(gsub("RN", "", tmp$BIBTEXKEY))
#tmp <- tmp[tmp$en_id %in% updated_ids,]
tmp <- tmp[order(tmp$en_id),]
is_public <- is.na(tmp$ACCESS) | tmp$ACCESS == "public"
tmp$ACCESS[is_public] <- "public"
tmp <- tmp[is_public,]

is_public_report <- endnote_df$ref_type_name == "Report" & (endnote_df$caption != "confidential" | is.na(endnote_df$caption))
public_report_ids <- endnote_df$rec_number[is_public_report]
public_reports <- endnote_df[is_public_report,c("rec_number", "urls_pdf01")]


### path PDF files of exported Endnote DB (needs to be same as .XML and .txt files!)
dms_dir <- fs::path_abs("../../dms/2020-07-08/KWB-documents_20191205.Data/PDF")

public_reports$urls_pdf01 <- gsub(pattern = "internal-pdf:/",
                                  replacement = dms_dir,
                                  public_reports$urls_pdf01)

fs::dir_create("static/pdf")

fs::file_copy(path = public_reports$urls_pdf01, 
              new_path = file.path(fs::path_abs("static/pdf"), 
                                   basename(public_reports$urls_pdf01)), overwrite = TRUE)

tmp <- dplyr::left_join(tmp,public_reports, by = c(en_id = "rec_number")) %>%  
  dplyr::mutate(URL = ifelse(!is.na(.data$urls_pdf01), 
                             sprintf("../../../pdf/%s", basename(.data$urls_pdf01)),
                             NA_character_)) %>%  
  dplyr::select(- .data$en_id, - .data$urls_pdf01)

#endnote_df$urls_pdf01[tmp$en_id %in% public_report_ids]

tmp$MONTH <- format(as.Date(tmp$MONTH), format = "%m")
dates <- as.Date(tmp$DATE, format = "%Y-%m-%d")
tmp$DATE <- dates
valid_dates_idx <- which(is.na(tmp$MONTH) & !is.na(dates))
tmp$MONTH[valid_dates_idx] <- format(dates[valid_dates_idx], format = "%m")

options(encoding="UTF-8")
bib2df::df2bib(tmp, file = "publications_kwb.bib", append = FALSE)

fs::dir_delete(path = list.dirs("content/publication/"))
fs::dir_delete(path = list.dirs("content/de/publication/")[-1])
fs::dir_delete(path = list.dirs("content/en/publication/")[-1])


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

#reticulate::conda_create(envname = env)#,conda = conda_path)
reticulate::use_condaenv(env,conda_path)

### Install required Python library "academic" 
### for details see:
# browseURL("https://github.com/sourcethemes/academic-admin")

#reticulate::py_install(packages = "academic", 
#                       envname = env, 
#                       pip = TRUE, pip_ignore_installed = TRUE) 
# Manually replace with own modification: 
# https://github.com/mrustl/academic-admin/commit/ea5c6a23d5b8cb482c2dd5afe15e71c1a049afbe
# (re-mapping pub_id = "0" -> "proceedings" and "9" -> "misc")

## Should existing publications in content/publication folder be overwritten?
overwrite <- TRUE

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
#for (i in 1:10) {
  shell("import_bibtex_kwb.bat")
#}
### Now check the folder "content/publication". Your publications should be added
### now!

### Add Project ids 
kwb.pubs::add_projects_to_pub_index_md(endnote_df, col_project = "label")



kwb_authors <- setNames(lapply(authors_metadata$dir_name, "["), 
                        nm = authors_metadata$author_name)

tmp$AUTHOR_KWB <- lapply(tmp$AUTHOR, FUN = function(authors) {
  if(any(!is.na(authors))) {
    kwb.utils::multiSubstitute(authors, replacements = kwb_authors)
  } else {message("no author entry")}
})

tmp$hugo_authors <- lapply(tmp$AUTHOR_KWB, function(authors) {
  sprintf("authors: [ %s ]", paste0('"', authors, '"', collapse = ", "))
  }
  )

tmp$id <- as.numeric(stringr::str_extract(tmp$BIBTEXKEY,
                                          pattern = "[0-9]+"))
saveRDS(tmp, "publications_kwb.Rds")


pub_md_paths <- kwb.pubs::get_publication_index_md_paths(lang = "de")



replace_kwb_authors_in_pub_index_md <- function (path, 
                                                 file_encoding = "UTF-8",
                                                 dbg = TRUE) {
  
  id <- as.numeric(stringr::str_extract(basename(dirname(path)), 
                                        pattern = "[0-9]+"))
  
  
  authors <- unlist(tmp$AUTHOR_KWB[tmp$id == id])
  
  if(!is.null(authors)) {
  
  pub_index_txt <- kwb.fakin::read_lines(path, 
                                         fileEncoding = file_encoding)
  idx <- which(stringr::str_detect(pub_index_txt, pattern = "^author"))
  if (idx > 0) {
    if(dbg) message(sprintf("Replacing KWB authors in '%s'", path))
    pub_index_txt[idx] <- unlist(tmp$hugo_authors[tmp$id == id])
    kwb.pubs::write_lines(pub_index_txt, path, file_encoding)
  }
  }
}
  


sapply(pub_md_paths, function(path) replace_kwb_authors_in_pub_index_md(path))



### Replace auto-generated publish date with "record_last_modified" (in "UTC")

path_en_db <- "../../dms/2020-07-08/KWB-documents_20191205.Data/sdb/sdb.eni"
contents <- kwb.pubs::read_endnote_db(path_en_db)

en_refs <- kwb.pubs::add_columns_to_endnote_db(contents$refs)
#en_refs$publication <- stringr::str_replace_all(en_refs$publication, pattern = '"', '\\"')
en_refs$publication <- sprintf("\'%s\'", en_refs$publication)

kwb.pubs::replace_dates_in_pub_index_md(md_paths = pub_md_paths, 
                                        endnote_db_refs = en_refs)
kwb.pubs::replace_publishDates_in_pub_index_md(md_paths = pub_md_paths, 
                                               endnote_db_refs = en_refs)
kwb.pubs::replace_publications_in_pub_index_md(md_paths = pub_md_paths, 
                                               endnote_db_refs = en_refs)


fs::dir_copy(path = "content/publication", "content/de/publication", overwrite = TRUE)
fs::dir_copy(path = "content/de/publication", "content/en/publication", overwrite = TRUE)
fs::dir_delete(path = "content/publication")

authors <- unique(unlist(tmp$AUTHOR))
authors[order(authors)]




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
  
  
  valid_pubs <- stringr::str_replace(kwb.file:::remove_common_root(dirname((citations))), "rn-", "RN")
  
  tmp[!tmp$BIBTEXKEY %in% valid_pubs,]
  
  sapply(citations, function(citation) {
    new_cite <- file.path(dirname(citation), "cite.bib")
    if(citation != new_cite) {
      fs::file_move(citation, new_path = new_cite)
    } else {
      message(sprintf("Citation '%s' already up-to-date!"))  
    }
  })
  
}

if (FALSE) {
 
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
  

}
