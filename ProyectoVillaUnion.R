require(rayshader)
require(raster)
require(rgl)
require(rayrender)
library(leaflet)
library(httr)
library(glue)
library(jsonlite)
library(leaflet)
library(raster)
library(rayshader)
library(MetBrewer)
library(sf)

setwd("~/mapa_VillaUnion")

# cargamos la imagen
Mapa<-"Mapa_villaunion.tif"
temp<-tempfile()

rgb = raster::brick(Mapa)
raster::plotRGB(rgb, scale=255)
dim(rgb)

# cargamos los datos de elevación, con los nulos en la zona donde no queremos elevar
DEM<-"NullRaster.tif"
temp2<-tempfile()

elevation1 = raster::raster(DEM)
res(elevation1) # resolucion del pixel
extent(elevation1) # extensión del raster
dim(elevation1) # dimensión del raster

elevation<-aggregate(elevation1,fact=1)
res(elevation) # resolución del pixel
extent(elevation) # extensión del raster
dim(elevation) # dimensión del raster

height_shade(raster_to_matrix(elevation)) %>%
  plot_map()

# spliteamos en rgb
names(rgb) = c("r","g","b")
rgb_r = rayshader::raster_to_matrix(rgb$r)
rgb_g = rayshader::raster_to_matrix(rgb$g)
rgb_b = rayshader::raster_to_matrix(rgb$b)
rgb

# chequeamos crs
raster::crs(rgb)
raster::crs(elevation)

# de ráster a matrix
el_matrix = rayshader::raster_to_matrix(elevation)

map_array = array(0,dim=c(nrow(rgb_r),ncol(rgb_r),3))

map_array[,,1] = rgb_r/255 #Red 
map_array[,,2] = rgb_g/255 #Blue 
map_array[,,3] = rgb_b/255 #Green 
map_array = aperm(map_array, c(2,1,3))

plot_map(map_array)

# reducimos el tamaño de la mátrix
small_el_matrix = resize_matrix(el_matrix, scale = 1) #Numbers less than 1 reduce the size of the elevation data

# reajustamos el mapa para que tenga la misma extensión que los datos de elevación
resized_overlay_file = paste0(tempfile(),".png")
grDevices::png(filename = resized_overlay_file, width = dim(small_el_matrix)[1], height = dim(small_el_matrix)[2])
par(mar = c(0,0,0,0))
plot(as.raster(map_array))
dev.off()
overlay_img = png::readPNG(resized_overlay_file)

zscale=30 #Larger number makes less vertical exaggeration

############################# Renderizamos ###########################################

ambient_layer = ambient_shade(small_el_matrix, zscale = zscale, multicore = TRUE, maxsearch = 200)
ray_layer = ray_shade(small_el_matrix, zscale = zscale, multicore = TRUE)

rgl::rgl.close() #Closes the rgl window

#ploteamos en 3d
(overlay_img) %>%
  add_shadow(ray_layer,0.3) %>%
  add_shadow(ambient_layer,0) %>%
  plot_3d(small_el_matrix,zscale=zscale,windowsize = c(8000, 8000), fov = 0, theta = 0, zoom = 0.75, phi = 30)

render_highquality(
  "villaunion_highres.png",
  samples=300, 
  scale_text_size = 24,
  clear=TRUE, 
  parallel = TRUE, 
  light = FALSE, 
  environment_light = "xanderklinge_4k.hdr",
  interactive = FALSE,
  intensity_env = 1.5,
  rotate_env = 180)


#ploteamos en 2d
(map_array) %>%
  add_shadow(ray_layer,0.3) %>%
  add_shadow(ambient_layer,0.3) %>%
  plot_map()



# Dynaimcally set window height and width based on object size
w <- nrow(small_el_matrix)
h <- ncol(small_el_matrix)

# Scale the dimensions so we can use them as multipliers
wr <- w / max(c(w,h))
hr <- h / max(c(w,h))

# Limit ratio so that the shorter side is at least .75 of longer side
if (min(c(wr, hr)) < .75) {
  if (wr < .75) {
    wr <- .75
  } else {
    hr <- .75
  }
}

render_highquality(
  "gcnp_highres.png", 
  parallel = TRUE, 
  samples = 300,
  light = FALSE, 
  interactive = FALSE,
  intensity_env = 1.5,
  rotate_env = 180,
)

