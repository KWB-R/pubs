cran_deps <- c("bib2df", "blogdown", "dplyr", "fs", "readxl", "remotes", "reticulate", "tibble")
install.packages(cran_deps, repo = "https://cran.rstudio.com")
remotes::install_github("kwb-r/kwb.pubs@dev", upgrade = "always")
remotes::install_github("kwb-r/kwb.site@dev", upgrade = "always")
remotes::install_github("kwb-r/kwb.endnote@dev", upgrade = "always")
remotes::install_github("pixgarden/xsitemap")


path_list <- list(en_root_dir = "//medusa/kwb$/Dokument-Managementsystem",
                  en_export_root_dir = "//medusa/processing/dms/endnote_export/latest", 
                  en_name = "KWB-documents",
                  en_file = "<en_name>.enl",
                  en_data_dir = "<en_root_dir>/<en_name>.Data",
                  en_pdf = "<en_data_dir>/PDF",
                  en_sdb_ini = "<en_data_dir>/sdb/sdb.eni",
                  en_export_xml = "<en_export_root_dir>/<en_name>.xml",
                  en_export_bibtex = "<en_export_root_dir>/<en_name>_with-abstracts_caption-label.txt",
                  en_export_bibtex_changed_only = "<en_export_root_dir>/<en_name>_with-abstracts_caption-label_changed-only.txt"
)



### at KWB
paths <- kwb.utils::resolve(path_list)

at_kwb <- file.exists(paths$en_sdb_ini) 
if(! at_kwb) {
### off KWB
local_root <- fs::path_abs(file.path(kwb.utils::get_homedir(), "dms"))
paths <- kwb.utils::resolveAll(path_list, 
    en_root_dir = fs::path_join(parts = c(local_root, "kwb-documents/latest")),
    en_export_root_dir = fs::path_join(parts = c(local_root, "endnote_export/latest"))
    )
}


library(kwb.pubs)

### Update KWB authors 
authors_config <- kwb.pubs::get_authors_config()

authors_metadata <- kwb.pubs::add_authors_metadata(authors_config)
 
authors_metadata$fullname <- authors_metadata$author_name
 
researchers_at_kwb <- ! authors_metadata$lastname %in% c("evel")
 
authors_metadata <- authors_metadata[researchers_at_kwb,]

## to do: add argument "lang" to kwb.pubs:::create_author_dir() to specify 
## "de" / "en" subfolder
kwb.pubs::add_authors_index_md(authors_metadata[authors_metadata$lastname=="jährig",], 
                               overwrite = TRUE)

## add "transparent" avatar for jette (to improve "ui")
avatar_path <- kwb.pubs::add_authors_avatar(authors_metadata[authors_metadata$lastname=="jährig",], 
                                            overwrite = TRUE)

magick::image_blank(300,300, color = "none") %>%  
  magick::image_transparent(color="white") %>% 
  magick::image_write(path = "content/en/authors/jaehrig/avatar.jpg")

fs::file_copy(avatar_path, "./content/de/authors/jaehrig/avatar.jpg")
fs::file_copy(avatar_path, "./content/en/authors/jaehrig/avatar.jpg")
fs::dir_delete("./content/authors")
              
## Fix avatars for "newcomers" (with own photos, where default values for 
## cropping were not a good choice!)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "habibi",],
                             x_off = 300, width = 380, height = 480,
                             overwrite = TRUE)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "toutian",],
                             x_off = 360, y_off = 40, width = 300, height = 400, 
                             overwrite = TRUE)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "rose",],
                             x_off = 290, y_off = 10, width = 380, height = 400,
                             overwrite = TRUE)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "knoche",],
                             x_off = 100,
                             overwrite = TRUE)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "conzelmann",],
                             x_off = 230, y_off = 40, height = 250,
                             overwrite = TRUE)
kwb.pubs:::add_author_avatar(authors_metadata[authors_metadata$lastname == "rabe",],
                             width = 500, x_off = 150, y_off = 0, height = 500,
                             overwrite = TRUE)


fs::dir_delete(path = "content/en/authors")
fs::dir_copy(path = "content/authors", "content/en/authors", overwrite = TRUE)
## currently the same content as in "en" (should be changed to "de"
## required to add a new "config" file)
fs::dir_delete(path = "content/de/authors")
fs::dir_copy(path = "content/authors", "content/de/authors", overwrite = TRUE)
fs::dir_delete(path = "content/authors")


library(dplyr)
library(reticulate)
  

get_project_ids_site <- function() {
  sites <- xsitemap::xsitemapGet("https://www.kompetenz-wasser.de")
  
  projects_site <- sites[sites$origin == "de/project-sitemap.xml",]

  project_ids_site <- stringr::str_split_fixed(projects_site$loc, "/", n = 7)[,6]
  project_ids_site <- project_ids_site[order(project_ids_site)]

  project_ids_site  
}

project_ids_site <- get_project_ids_site()

endnote_list <- kwb.endnote::create_endnote_list(endnote_xml = paths$en_export_xml)
endnote_df <- kwb.endnote::create_references_df(endnote_list)
condition_indices <- which(endnote_df$caption == "confidential" & endnote_df$ref_type_name == "Report")
confidential_pubs_idx <- endnote_df$rec_number[condition_indices]

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


get_project_md <- function(project_id, 
                           lang = "",
                           hugo_root_dir = ".") {
  
  link_name <- if(lang == "en") {
    "Project Website"
  } else {
    "Projektseite"
  }
  md_path <- sprintf("%s/content%sproject/%s/index.md",
        hugo_root_dir, 
        ifelse(lang == "", "", sprintf("/%s/", lang)), 
        project_id)
  

  if(!fs::file_exists(md_path)) {
    message(sprintf("No '.md' file found at: %s", md_path))
    md_path <-  NA_character_
  } else {
    md_path <- fs::path_abs(md_path)
  }
  
  tibble::tibble(id = project_id, 
                 lang = lang, 
                 link_name = link_name, 
                 md_path = md_path)
}

get_projects_md <- function(project_ids_site,
                            hugo_root_dir = ".") {
 
  dplyr::bind_rows(lapply(project_ids_site, 
                                       get_project_md, 
                                       lang = "de",
                                       hugo_root_dir = hugo_root_dir)) %>% 
  dplyr::bind_rows(dplyr::bind_rows(lapply(project_ids_site, 
                                           get_project_md, 
                                           lang = "en",
                                           hugo_root_dir = hugo_root_dir)))
}


add_backlinks_to_projects <- function(projects,
                          encoding = "UTF-8",
                          dbg = TRUE) {
  sapply(seq_len(nrow(projects)), function(i) {
    project <- projects[i,]
    if (!is.na(project$md_path)) {
      kwb.utils::catAndRun(
        messageText = sprintf("Adding backlink to project: %s",
                              project$md_path),
        expr = {
          proj_md <- readLines(project$md_path, encoding = encoding)
          line_url_code <- grep("^url_code:", proj_md)
          proj_md_new <- c(
            proj_md[seq_len(line_url_code - 1)],
                    "links:",
            sprintf("- name: %s", project$link_name),
            sprintf("  url: https://kompetenz-wasser.de/%s/project/%s",
                    project$lang,
                    project$id),
                    "  icon_pack: fas",
                    "  icon: home",
                    "",
            proj_md[line_url_code:length(proj_md)]
          )
          
          kwb.pubs::write_lines(
            text = proj_md_new,
            file = project$md_path,
            fileEncoding = encoding
          )
        }, dbg = dbg)} else {
      message(sprintf("No project md file exists for '%s'", project$id))
    } 
    }
    )
}

add_title_to_projects <- add_title_to_projects <- function(projects,
                                                           encoding = "UTF-8",
                                                           dbg = TRUE) {
  sapply(seq_len(nrow(projects)), function(i) {
    project <- projects[i,]
    if (!is.na(project$md_path)) {
      kwb.utils::catAndRun(
        messageText = sprintf("Adding title to project: %s",
                              project$md_path),
        expr = {
          proj_md <- readLines(project$md_path, encoding = encoding)
          idx <- grep("^title:", proj_md)
          proj_md_new <- c(
            proj_md[seq_len(idx)-1],
            sprintf('title: "%s"', project$title),
            proj_md[(idx+1):length(proj_md)]
          )
          
          kwb.pubs::write_lines(
            text = proj_md_new,
            file = project$md_path,
            fileEncoding = encoding
          )
        }, dbg = dbg)} else {
          message(sprintf("No project md file exists for '%s'", project$id))
        } 
  }
  )
}



projects_metadata <- kwb.site::clean_projects("https://kwb-r.github.io/kwb.site/projects_de.json")

prj <- tibble::tibble(project_ids = stringr::str_remove(projects_metadata$url, "https://www.kompetenz-wasser.de/de/project/") %>%  stringr::str_remove("/"), 
              shortname = projects_metadata$id)

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
  dplyr::left_join(dms1) %>% 
  dplyr::left_join(prj)

all_projects <- ids_all[ids_all$project_ids != "reef2w-2",]
all_projects <- ids_all[!ids_all$project_ids %in% c("flusshygiene\rdemoware", "ism\reva", "carismo\rcodigreen\rhtc-berlin", "ogre\rflusshygiene", "prepared\rwsstp", "reef2w-2"),]
readr::write_csv2(all_projects, "project-ids_website_dms.csv",na = "")

fs::dir_delete(path = "content/de/project/")
fs::dir_delete(path = "content/en/project/")
### Relax and take a coffee (takes ~ 5 minutes)
kwb.pubs::create_projects(all_projects$project_ids)
fs::dir_copy(path = "content/de/project", "content/en/project", overwrite = TRUE)

### to do: add "links" to KWB project factsheets (add in R package kwb.pubs)

## projects on "website"
project_ids_site <- get_project_ids_site() 
projects <- get_projects_md(project_ids_site) %>% 
  dplyr::left_join(all_projects %>%  
                     dplyr::select(project_ids, shortname) %>%  
                     dplyr::rename(id = project_ids, title = shortname))
add_backlinks_to_projects(projects)
add_title_to_projects(projects)

## projects only in "DMS"
terms_projects <- kwb.nextcloud::download_files(paths = "/projects/dms/term-lists/TermsListLabelsWebsite.xlsx")
prj_only_dms <- readxl::read_xlsx(terms_projects) %>% 
  dplyr::filter(is.na(source_website) & !is.na(source_dms) ) %>% 
  dplyr::rename(id = project_ids, 
                title = shortname)

projects <- get_projects_md(prj_only_dms$id) %>%
  dplyr::left_join(prj_only_dms)
add_title_to_projects(projects)


### Import all (same cannot due to parsing errors:
### "The name list field author cannot be parsed"

bib2df <- function (file, separate_names = FALSE) {
bib <- bib2df:::bib2df_read(file)
bib <- bib2df:::bib2df_gather(bib)
bib <- bib2df:::bib2df_tidy(bib, separate_names)
return(bib)
}

con <- file(paths$en_export_bibtex_changed_only, encoding = "UTF-8-BOM")
tmp <- bib2df(file = con)
close(con)

tmp$URL <- NA_character_
tmp$BIBTEXKEY <- gsub("RN", "", tmp$BIBTEXKEY)
tmp$en_id <- as.numeric(gsub("RN", "", tmp$BIBTEXKEY))
#tmp <- tmp[tmp$en_id %in% updated_ids,]
tmp <- tmp[order(tmp$en_id),]
is_public <- is.na(tmp$ACCESS) | tmp$ACCESS == "public" 
tmp$ACCESS[is_public] <- "public"
tmp <- tmp[is_public | (tmp$ACCESS == "confidential" & tmp$CATEGORY != "TECHREPORT"),]

is_public_report <- endnote_df$ref_type_name == "Report" & (endnote_df$caption != "confidential" | is.na(endnote_df$caption))
public_report_ids <- endnote_df$rec_number[is_public_report]
public_reports <- endnote_df[is_public_report,c("rec_number", "urls_pdf01")]




### path PDF files of exported Endnote DB (needs to be same as .XML and .txt files!)

public_reports_selected <- public_reports[public_reports$rec_number %in% tmp$en_id,]

public_reports_selected$urls_pdf01 <- gsub(pattern = "internal-pdf:/",
                                  replacement = paths$en_pdf,
                                  public_reports_selected$urls_pdf01)

public_reports_selected <- public_reports_selected[!is.na(public_reports_selected$urls_pdf01),]

fs::dir_create("static/pdf")

fs::file_copy(path = public_reports_selected$urls_pdf01, 
              new_path = file.path(fs::path_abs("static/pdf"), 
                                   basename(public_reports_selected$urls_pdf01)), overwrite = TRUE)

tmp <- dplyr::left_join(tmp,public_reports_selected, by = c(en_id = "rec_number")) %>%  
  dplyr::mutate(URL = ifelse(!is.na(.data$urls_pdf01), 
                             sprintf("/pdf/%s", basename(.data$urls_pdf01)),
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
reticulate::use_condaenv(env, conda_path)

### Install required Python library "academic" 
### for details see:
# browseURL("https://github.com/sourcethemes/academic-admin")

# reticulate::py_install(packages = "academic", 
#                        envname = env, 
#                        pip = TRUE, pip_ignore_installed = TRUE) 
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
  shell(cmd = "import_bibtex_kwb.bat")
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

tmp$id

fs::dir_copy("content/publication", "content/de/publication", overwrite = TRUE)
pub_md_paths <- kwb.pubs::get_publication_index_md_paths(lang = "de")

pub_md_paths <- stringr::str_subset(pub_md_paths, pattern = paste(tmp$id, collapse = "|"))
                     
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

contents <- kwb.pubs::read_endnote_db(paths$en_sdb_ini)

en_refs <- kwb.pubs::add_columns_to_endnote_db(contents$refs)

### added "publication" replacement due to https://github.com/KWB-R/kwb.pubs/issues/8
en_refs$publication <- stringr::str_replace_all(en_refs$publication, pattern = '"', '\\\\"')
en_refs$publication <- sprintf("\"%s\"", en_refs$publication)

kwb.pubs::replace_dates_in_pub_index_md(md_paths = pub_md_paths, 
                                        endnote_db_refs = en_refs)
kwb.pubs::replace_publishdates_in_pub_index_md(md_paths = pub_md_paths, 
                                               endnote_db_refs = en_refs)

kwb.pubs::replace_publications_in_pub_index_md(md_paths = pub_md_paths, 
                                               endnote_db_refs = en_refs)

# kwb.pubs:::replace_abstracts_in_pub_index_md(md_paths = pub_md_paths, 
#                                                endnote_db_refs = en_refs)


update_citations <- function(bib_df, 
                             lang = "de",
                             hugo_root_dir = ".") {
  
  sapply(seq_len(nrow(bib_df)), function (i) {
     
    reference <- bib_df[i, ]
    
    #refs <- reference %>%  dplyr::select(- .data$id)
    
    bib2df::df2bib(reference, file = sprintf("%s/content%spublication/%d/cite.bib", 
                                             hugo_root_dir,
                                             ifelse(lang == "", "" , sprintf("/%s/", lang)), 
                                             reference$en_id) %>% fs::path_abs())
  })
  
}

tmp <- bib2df::bib2df("publications_kwb.bib")
tmp$en_id <- as.integer(tmp$BIBTEXKEY)
tmp$BIBTEXKEY <- paste0("RN", tmp$BIBTEXKEY)
tmp$URL <- ifelse(!is.na(tmp$URL),
                  sprintf("https://publications.kompetenz-wasser.de%s", tmp$URL), 
                  NA_character_)
                          
update_citations(bib_df = tmp, lang = "de")

fs::dir_copy(path = "content/de/publication", "content/en/publication", overwrite = TRUE)
fs::dir_delete(path = "content/publication")



if (FALSE) {



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

add_url_root_to_citations <- function(url_root = "https://publications.kompetenz-wasser.de", 
                                      pub_dir = "content/de") {
  
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

 


}
