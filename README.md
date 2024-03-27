# kof1nti.github.io
A portfolio on creating a 2m square grids in R 
Steps in creating grid in R  portfolio

[grid portfolio](kof1nti.github.io)

# Highlights 
- Initiating a function
- Loading data 
- Calling libraries
- Creating grid 
- Finding centroids in epsg fromat
- Splitting centroids into X and Y 
- Fortifying grid to get coordiantes of corners and unlisting them
- Merging desired columns from steps and applying spatial functions 
 

### Write 1  
- Creating a databse connection
- Writing to db and appending all other layers

### Write 2 
- Generating list from merged results and writing to local directory

### Running function
- lapply function to get on list to loop results into db and append on every write


### Takeaways
- Always create grid in country utm as it has proven to get results close to actual earth distance ellipsoidal.

- Reproject to other CRS' to get coordinates

- Know the type of spatial joins or clips to use :st_intersection  attaches part of overlapping polygons to results  whilst .[] attaches whole area of overlapping ploygons.

- In the former spatial join, filter areas that are less than desired grid area 
