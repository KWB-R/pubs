### Download, crop and save KWB twitter icon
library(magick)
library(magrittr)
kwb_icon <- magick::image_read("https://pbs.twimg.com/profile_images/1009162345455767553/HIWTr690_400x400.jpg") 

### Size icons as recommended:
### https://sourcethemes.com/academic/docs/customization/#website-icon
  kwb_icon %>%
  magick::image_scale(geometry = magick::geometry_size_pixels(192,192)) %>% 
  magick::image_write("static/img/icon-192.png")
  
  kwb_icon %>%
    magick::image_scale(geometry = magick::geometry_size_pixels(32,32)) %>% 
    magick::image_write("static/img/icon.png")
