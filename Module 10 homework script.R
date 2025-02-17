##### BAE590 Module 10 homework script
##### Author: Kanjana Laosuntisuk
##### Date created: Nov 2, 2019
##### Last modified: Nov 2, 2019

# Clear workspace and load packages
rm(list=ls(all=TRUE))
library(tidyverse)
library(sf)
library(ggspatial)

# Load data
shelter <- read_sf("spatial_data/Potential_Emergency_Shelters.shp")
state_bounds <- read_sf("spatial_data/state_bounds.shp")
nc_county_bounds <- read_sf("spatial_data/NCDOT_County_Boundaries.shp")
nc_urban_bounds <- read_sf("spatial_data/NCDOT_Smoothed_Urban_Boundaries_simple.shp")

# inspect data
shelter
state_bounds
nc_county_bounds
nc_urban_bounds

# re-project data to EPSG = 32019
shelter <- st_transform(shelter, 32019)
st_crs(shelter)
state_bounds <- st_transform(state_bounds, 32019)
st_crs(state_bounds)
nc_county_bounds <- st_transform(nc_county_bounds, 32019)
st_crs(nc_county_bounds)
nc_urban_bounds <- st_transform(nc_urban_bounds, 32019)
st_crs(nc_urban_bounds)

##### How many potential emergency shelter sites are located in urban areas across NC?
##### Answer: 1545

# select shelters in nc_urban_bounds to find how many shelters in NC urban area
shelter_nc_urban <- st_intersection(shelter, st_geometry(nc_urban_bounds))
shelter_nc_urban
count(shelter_nc_urban)

# Plot shelters in NC urban area to confirm that shelter_nc_urban locate in nc_urban_bounds
ggplot() +
  geom_sf(data = nc_county_bounds) +
  geom_sf(data = nc_urban_bounds, fill = "red", alpha = 0.5) +
  geom_sf(data = shelter_nc_urban, color = "blue", size = 0.8, alpha = 0.5) +
  theme_bw()

##### How many shelters are located within 50 km of the Capital Area Metropolitan Organization (the name of the urban area surrounding Raleigh)?
##### Answer: 556

# filter Capital Area Metropolitan Organization from nc_urban_bounds
nc_urban_bounds %>%
  filter(NAME == "Capital Area Metropolitan Organization") -> nc_CAMO_bounds

# Calculate buffer of nc_CAMO_bounds with distance = 164042 feet (50 km)
nc_CAMO_buffer <- st_buffer(nc_CAMO_bounds, dist = 164042)

# select shelters in nc_CAMO_buffer to find how many shelters in within 50 km of CAMO
shelter_nc_CAMO <- st_intersection(shelter, st_geometry(nc_CAMO_buffer))
shelter_nc_CAMO
count(shelter_nc_CAMO) 

## Plot shelters within 50 km of CAMO 
ggplot() +
  geom_sf(data = nc_CAMO_buffer, fill = "red", color = "red", alpha = 0.2, size = 1) +
  geom_sf(data = nc_CAMO_bounds) +
  geom_sf(data = shelter_nc_CAMO, alpha = 0.5) +
  theme_bw() +
  annotation_scale(location = "br") +
  annotation_north_arrow(location = "tl")

##### How many potential shelters are there per county?
##### Answer: the plot generated by the following codes

# select NC geometry from state_bounds
state_bounds %>%
  filter(NAME == "North Carolina") %>%
  st_geometry() -> nc_geom

# count number of shelters in each county and separate attributes from shelter data
shelter %>%
  group_by(COUNTY) %>%
  count() %>%
  st_set_geometry(NULL) -> shelter_count
shelter_count

# change column name of shelter_count for joining
colnames(shelter_count) <- c("UpperCount", "n")
shelter_count

# join nc_county_bounds spatial data with shelter_count attributes
nc_county_bounds %>%
  left_join(shelter_count) -> nc_county_shelter
nc_county_shelter

# Plot shelters in NC 
ggplot() +
  geom_sf(data = nc_geom) +
  geom_sf(data = nc_county_shelter, aes(fill = n), size = 1) +
  scale_fill_viridis_c() +
  labs(fill = "No. of shelters") +
  annotation_scale(location = "bl") +
  theme_bw()

##### Extra credit: Determine, for urban areas, how many people there are in the area relative to the number of shelters (population / number of shelters)
##### Answer: the plot generated by the following codes

# join nc_urban_bounds and shelter_nc_urban 
nc_urban_bounds %>%
  st_join(shelter_nc_urban) -> nc_urban_shelter

# count number of shelter in each urban area and separate attributes from nc_urban_shelter data
nc_urban_shelter %>%
  group_by(OBJECTID.x) %>%
  count() %>%
  st_set_geometry(NULL) -> nc_urban_shelter_count
nc_urban_shelter_count

# change column name of nc_urban_shelter_count for joining
colnames(nc_urban_shelter_count) <- c("OBJECTID", "n")
nc_urban_shelter_count

# join nc_urban_bounds spatial data with nc_urban_shelter_count attributes
# calculate population per shelter
nc_urban_bounds %>%
  left_join(nc_urban_shelter_count) %>%
  mutate(pop_per_shelter = POP_EST/n) -> nc_urban_bounds_mutate
nc_urban_bounds_mutate

# plot population per shelter
ggplot() +
  geom_sf(data = nc_geom) +
  geom_sf(data = nc_urban_bounds_mutate, aes(fill = pop_per_shelter)) + 
  scale_fill_viridis_c() + 
  labs(fill = "Population/shelter") +
  annotation_scale(location = "bl") +
  theme_bw()
