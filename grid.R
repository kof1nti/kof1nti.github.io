
layers <- ogrListLayers("areas to grid.gpkg")
g <- readOGR("areas to grid.gpkg", layers[1]) %>%
  st_as_sf() 
p <- st_read("points to be referenced.gpkg")

gpkglist = split(g, g$tile_name)


londongrid = function(g) {
  
  library(sf)
  library(rgdal)
  library(maps)
  library(purrr)
  library(terra)
  library(tidyverse)
  library(data.table)
  library(RPostgres)
  library(DBI)
  library(RODBC)
  library(odbc)
  
  ##### grid voro
  
  # initiate a start time
  start <- Sys.time()
  
  g2 <- st_make_grid(g, cellsize = 3.2, square = TRUE) # create grid
  
  # find centroid
  centroids <- st_centroid(g2) %>%
    st_coordinates() %>%
    as.data.frame()
  
  #split ceontroids and transform
  cen_sf <- st_as_sf(x = centroids,                         
                     coords = c("X", "Y"),
                     crs = 3857)
  
  cen_4326 <- st_transform(cen_sf, crs=4326)
  
  cen_4326.split <- cen_4326 %>%
    mutate(Longitude = unlist(map(cen_4326$geometry,1)),
           Latitude = unlist(map(cen_4326$geometry,2))) %>%
    cbind(centroids)
  
  # fortify grid and tranform
  g3 <- g2 %>%
    fortify()
  #select(geometry)
  
  g3.tr <- g3 %>%
    st_transform(., crs = 4326)
  
  # unlist coordinates for corners of grid for both normal and transformed grids
  coords = matrix(unlist(g3$geometry),ncol = 10,byrow = T)
  coords.2 = matrix(unlist(g3.tr$geometry),ncol = 10,byrow = T)
  
  # apply spatial functions
  bnd.a <- g3 %>%
    cbind(cen_4326.split,coords, coords.2) %>%
    mutate(., grid_ref_id = g$tile_name) %>%
    mutate(uid =  row_number()) %>%
    mutate(grid_ref_uid = paste(.$grid_ref_id, .$uid, sep = "_")) %>%
    dplyr::select(grid_ref_uid,Longitude, Latitude, X, Y, X1, X2,X6,X8,X1.1, X2.1, X6.1,X8.1) %>%
    rename("grid_ref_uid"="grid_ref_uid","longitude_centroid"="Longitude","latitude_centroid"="Latitude","x_centroid"="X","y_centroid"="Y",
           "lw"="X1", "ue"="X2", "uw"="X6", "le"="X8", "lw_4326"="X1.1", "ue_4326"="X2.1", "uw_4326"="X6.1", "le_4326"="X8.1") %>%
    .[g,] %>%
    mutate(area = st_area(.))%>%
    mutate(date= as.Date(start)) %>%
    mutate(author= "IM")
  
  ## use names in your data 
  p.grid <- bnd.a %>%
    sf::st_join(dplyr::select(p, Postcode)) %>%
    filter(!is.na(Postcode)) %>%
    dplyr::select(grid_ref_uid,Postcode)
  
  
  dsn_database = "#"   # Specify the name of your Database
  
  dsn_hostname = "#"  # Specify host name e.g.:"aws-us-east-1-portal.4.dblayer.com"
  dsn_port =  "#"                # Specify your port number. e.g. 98939
  dsn_uid = "#"         # Specify your username. e.g. "admin"
  dsn_pwd = "#"        # Specify your password. e.g. "xxx"
  
  ### localcon is the name from setting odbc connection on your local machine
  ## a successful connection opens db which can be viewd in connections in R 
  
  con <- dbConnect(odbc::odbc(),"localcon")

  ### to write to db use this 
  st_write(obj = bnd.a, dsn = con, Id(schema="public", table = "grid2"), append = TRUE)
  st_write(obj = p.grid, dsn = con, Id(schema="public", table = "pgrid"),append = TRUE)
  

  
  #to write to a directory use this
  list_data <- split(bnd.a, bnd.a$grid_ref_id)
  names(list_data) <- paste0(names(list_data))
  
  iwalk(list_data, ~st_write(.x, str_c(.y, ".gpkg"), row.names=FALSE))
  
  list_data_2 <- split(p.grid, p.grid$grid_ref_id)
  names(list_data_2) <- paste0('df_',  names(list_data_2))
  
  iwalk(list_data_2, ~st_write(.x, str_c(.y, ".gpkg"), row.names=FALSE), append= TRUE)
  
  print(Sys.time()-start)
  print(paste0('Done with grid ', ' test'))
  
}

# Run this functiopn
londongrid()

## Run this finally to loop 
out = lapply(gpkglist, function(x){
  londongrid(x)
  TRUE
})

