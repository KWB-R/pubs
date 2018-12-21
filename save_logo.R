### Download, crop and save KWB twitter icon
library(magick)
library(magrittr)
kwb_logo <- magick::image_read("https://www.kompetenz-wasser.de/wp-content/uploads/2017/08/cropped-logo-kwb_klein-new.png") 

### Size icons as recommended:
### https://sourcethemes.com/academic/docs/migrate-from-jekyll/
kwb_logo %>%
  magick::image_scale(geometry = magick::geometry_size_pixels(height = 40,
                                                              preserve_aspect = TRUE)) %>% 
  magick::image_write("static/img/logo.png")

