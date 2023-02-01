# Load magick library, which provides R interface with ImageMagick
library(magick)


# Set text color


# Read in image, save to `img` object
img <- image_read("villaunion_highres.png")

img_ <- image_annotate(img, "Carta Geológica Económica", font = "Cinzel Decorative",
                       color = "black", size = 30, gravity = "north",
                       location = "+0+50")
# Subtitle
img_ <- image_annotate(img_, "Villa Unión, Provincia de la Rioja", weight = 400, 
                       font = "Cinzel Decorative", location = "+0+120",
                       color = "black", size = 50, gravity = "north")

print(img_)

