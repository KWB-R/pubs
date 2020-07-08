add_space_at_start_if_not_empty <- function (string) {
  ifelse(string != "", 
         sprintf(" %s", stringr::str_trim(string)), 
         "")
}

add_cursive_if_not_empty <- function (string) {
  ifelse(string != "", 
         sprintf("*%s*", stringr::str_trim(string)), 
         "")
}

add_dot_at_end_if_not_empty <- function (string) {
  ifelse(string != "", 
         sprintf(" %s.", stringr::str_trim(string)), 
         "")
}

add_semicolon_at_start_if_not_empty <- function (string) {
  ifelse(string != "", 
         sprintf(", %s", stringr::str_trim(string)), 
         "")
}

add_in_at_start_if_not_empty <- function (string) {
ifelse(string != "", 
       sprintf("***In:*** %s", stringr::str_trim(string)), 
       "")
}

add_kwb_style <- function(endnote_db_refs) {
 
 endnote_db_refs$publisher <- gsub("\r", 
                                   ", ", 
                                   endnote_db_refs$publisher)
 endnote_db_refs$publication <- "" 

 get_reference_type <- function (id) {
   is_sel_ref_type <- endnote_db_refs$reference_type %in% id
   endnote_db_refs[is_sel_ref_type,]
 }
 
 ### thesis (reference_type == 2)
 thesis <- get_reference_type(2)
 thesis$publication <- sprintf(
   "%s%s%s",
   add_dot_at_end_if_not_empty(thesis$type_of_work),
   add_dot_at_end_if_not_empty(thesis$secondary_title),
   add_space_at_start_if_not_empty(thesis$publisher)
 )
 
 ### conference_proceedings (reference_type == 3)
 conf_proceedings <- get_reference_type(3)
 conf_proceedings$publication <- sprintf(
   "%s%s%s",
   add_semicolon_at_start_if_not_empty(conf_proceedings$pages),
   add_in_at_start_if_not_empty(conf_proceedings$secondary_title),
   add_space_at_start_if_not_empty(conf_proceedings$place_published)
 )
 
 ### journal_article (reference_type == 0)
 journal_paper <- get_reference_type(0)
 
 journal_name <- add_cursive_if_not_empty(journal_paper$secondary_title) %>%
   add_space_at_start_if_not_empty()
 
 journal_paper$publication <- sprintf(
   "%s%s%s",
   journal_name,
   add_in_at_start_if_not_empty(conf_proceedings$secondary_title),
   add_space_at_start_if_not_empty(conf_proceedings$place_published)
 )
 
 
 
}


if(FALSE) {
dois <- contents$refs$electronic_resource_number[contents$refs$electronic_resource_number != ""]

is_simple_error <- function(x) inherits(x, "simpleError")

check_doi <- function(doi, dbg = TRUE) {
  
doi_url <- sprintf("https://doi.org/%s", doi)
response <-  httr::GET(doi_url)


if(httr::status_code(response)==404) {
  FALSE
} else {
  TRUE
}
}

dois_exist <- setNames(lapply(dois, check_doi), dois)
}