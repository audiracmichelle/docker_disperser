# Test Disperser in the docker container

# use the following command to run the docker container
# simply indicate the location on the host machine on the left side of : by substituting LOCATION
# docker run -p 8787:8787 -e ROOT=true -e DISABLE_AUTH=true -v C:\Users\LOCATION:/home/rstudio/ audiracmichelle/disperser
# the files in the lower-right window in Rstudio are located in HOME = /home/rstudio/

# the docker container has these two packages already installed
# avoid running again
#devtools::install_github( 'lhenneman/SplitR')
#devtools::install_github( 'lhenneman/DisperseR')

library(disperseR) # our package
#library(SplitR)
library(ncdf4)
library(data.table)
library(tidyverse)
library(parallel)
library(sf)
library(viridis)
library(ggplot2)
library(scales)
library(ggsn)
library(gridExtra)
library(ggmap)
library(ggrepel)
library(fst)
library(USAboundaries)

# it looks like the disperser functions work better if a
# an existing address is given to `create_dirs`
# in this case use the location '/home/rstudio' to work
# with the docker container's file system
disperseR::create_dirs("/home/rstudio")

# disperseR::get_data(data = "all",
#                     start.year = "2005",
#                     start.month = "11",
#                     end.year = "2006",
#                     end.month = "02")
# the pbl extraction prompts an error message. 
# you can extract manually, although the file is not used. 
# use the following command params instead

disperseR::get_data(data = "metfiles",
                    start.year = "2005",
                    start.month = "11",
                    end.year="2006",
                    end.month="02")
# to validate that this function ran properly, the following
# files should be found inside the /main/input folder

# system("ls -R /home/rstudio/main/input/")
# /home/rstudio/main/input/:
# hpbl
# meteo
# zcta_500k
#
# /home/rstudio/main/input/hpbl:
#   hpbl.mon.mean.nc
#
# /home/rstudio/main/input/meteo:
#   RP200511.gbl
# RP200512.gbl
# RP200601.gbl
# RP200602.gbl
#
# /home/rstudio/main/input/zcta_500k:
#   cb_2017_us_zcta510_500k.cpg
# cb_2017_us_zcta510_500k.dbf
# cb_2017_us_zcta510_500k.prj
# cb_2017_us_zcta510_500k.shp
# cb_2017_us_zcta510_500k.shp.ea.iso.xml
# cb_2017_us_zcta510_500k.shp.iso.xml
# cb_2017_us_zcta510_500k.shp.xml
# cb_2017_us_zcta510_500k.shx
# cb_2017_us_zcta510_500k.zip

View(disperseR::units)

unitsrun2005 <- disperseR::units %>%
  dplyr::filter(year == 2005) %>% # only get data for 2005
  dplyr::top_n(2, SOx)  # sort and take the two rows with the biggest value for SOx

unitsrun2006 <- disperseR::units %>%
  dplyr::filter(year == 2006) %>%  # only get data for 2006
  dplyr::top_n(2, SOx)  # sort and take the two rows with the biggest value for SOx

unitsrun <- data.table::data.table(rbind(unitsrun2005, unitsrun2006))

input_refs <- disperseR::define_inputs(units = unitsrun,
                                       startday = '2005-11-01',
                                       endday = '2006-02-28',
                                       start.hours =  c(0, 6, 12, 18),
                                       duration = 12) #12O DEFAULT

input_refs_subset <- input_refs[format(as.Date(input_refs$start_day,
                                               format = "%Y-%m-%d"),
                                       format = "%d") == "01" & start_hour == 0]

# I set the keep.hysplit.files = TRUE
# after running the following command you can look inside
# /home/rstudio/main/process/3136-1_3136-1_13088_0/
# and you will see the PARDUMP file and other files
# which are used by the NOOA executable to produce the hysplit output
hysp_raw <- disperseR::run_disperser_parallel(input.refs = input_refs_subset,
                                              pbl.height = pblheight,
                                              species = 'so2',
                                              proc_dir = proc_dir,
                                              overwrite = FALSE, ## FALSE BY DEFAULT
                                              npart = 10, ##100 DEFAULT
                                              keep.hysplit.files = TRUE, ## FALSE BY DEFAULT
                                              mc.cores = parallel::detectCores())
# Several warnings will pop, but this is expected (I looked into splitR's github issues)
# the output is a list that contains strings. The strings describe the location of the hysplit output

# hysp_raw =
# [[1]]
# [1] "Partial trimmed parcel locations (below height 0 and the highest PBL height) written to /home/rstudio/main/output/hysplit/2005/11/hyspdisp_3136-1_2005-11-01_00.fst"
#
# [[2]]
# [1] "Partial trimmed parcel locations (below height 0 and the highest PBL height) written to /home/rstudio/main/output/hysplit/2005/12/hyspdisp_3136-1_2005-12-01_00.fst"
#
# [[3]]
# [1] "Partial trimmed parcel locations (below height 0 and the highest PBL height) written to /home/rstudio/main/output/hysplit/2006/01/hyspdisp_3136-1_2006-01-01_00.fst"
#
# [[4]]
# [1] "Partial trimmed parcel locations (below height 0 and the highest PBL height) written to /home/rstudio/main/output/hysplit/2006/02/hyspdisp_3136-1_2006-02-01_00.fst"
#
# [[5]]
# [1] "Partial trimmed parcel locations (below height 0 and the highest PBL height) written to /home/rstudio/main/output/hysplit/2006/01/hyspdisp_3136-2_2006-01-01_00.fst"
#

yearmons <- disperseR::get_yearmon(start.year = "2005",
                                   start.month = "07",
                                   end.year = "2006",
                                   end.month = "06")
unitsrun

# linked_zips <- disperseR::link_all_units(
#   units.run = unitsrun,
#   link.to = 'zips',
#   mc.cores = parallel::detectCores(),
#   year.mons = yearmons,
#   #pbl.height = pblheight,
#   pbl_trim = FALSE,
#   crosswalk. = crosswalk,
#   duration.run.hours = 20,
#   res.link = 12000,
#   overwrite = FALSE)

# link all units to counties
linked_counties <- disperseR::link_all_units(
  units.run=unitsrun,
  link.to = 'counties',
  mc.cores = parallel::detectCores(),
  year.mons = yearmons,
  #pbl.height = pblheight,
  pbl_trim = FALSE,
  counties. = USAboundaries::us_counties( ),
  crosswalk. = NULL,
  duration.run.hours = 20,
  overwrite = FALSE)
# link all units to grids
linked_grids <- disperseR::link_all_units(
  units.run=unitsrun,
  link.to = 'grids',
  mc.cores = parallel::detectCores(),
  year.mons = yearmons,
  #pbl.height = pblheight,
  pbl_trim = FALSE,
  crosswalk. = NULL,
  duration.run.hours = 20,
  overwrite = FALSE)

#head(linked_zips)
head(linked_counties)
head(linked_grids)

unique(linked_zips$comb)

# impact_table_zip_single <- disperseR::create_impact_table_single(
#   data.linked=linked_zips,
#   link.to = 'zips',
#   data.units = unitsrun,
#   zcta.dataset = zcta_dataset,
#   map.unitID = "3136-1",
#   map.month = "200511",
#   metric = 'N')
impact_table_county_single <- disperseR::create_impact_table_single(
  data.linked=linked_counties,
  link.to = 'counties',
  data.units = unitsrun,
  counties. = USAboundaries::us_counties( ),
  map.unitID = "3136-1",
  map.month = "200511",
  metric = 'N')
impact_table_grid_single <- disperseR::create_impact_table_single(
  data.linked=linked_grids,
  link.to = 'grids',
  data.units = unitsrun,
  map.unitID = "3136-1",
  map.month = "200511",
  metric = 'N')

head(impact_table_county_single)

# link_plot_zips <- disperseR::plot_impact_single(
#   data.linked = linked_zips,
#   link.to = 'zips',
#   map.unitID = "3136-1",
#   map.month = "20061",
#   data.units = unitsrun,
#   zcta.dataset = zcta_dataset,
#   metric = 'N',
#   graph.dir = graph_dir,
#   zoom = T, # TRUE by default
#   legend.name = 'HyADS raw exposure',
#   # other parameters passed to ggplot2::theme()
#   axis.text = element_blank(),
#   legend.position = c( .75, .15))
link_plot_grids <- disperseR::plot_impact_single(
  data.linked = linked_grids,
  link.to = 'grids',
  map.unitID = "3136-1",
  map.month = "20061",
  data.units = unitsrun,
  metric = 'N',
  graph.dir = graph_dir,
  zoom = F, # TRUE by default
  legend.name = 'HyADS raw exposure',
  # other parameters passed to ggplot2::theme()
  axis.text = element_blank(),
  legend.position = c( .75, .15))
link_plot_counties <- disperseR::plot_impact_single(
  data.linked = linked_counties,
  link.to = 'counties',
  map.unitID = "3136-1",
  map.month = "20061",
  counties. = USAboundaries::us_counties( ),
  data.units = unitsrun,
  metric = 'N',
  graph.dir = graph_dir,
  zoom = T, # TRUE by default
  legend.name = 'HyADS raw exposure',
  # other parameters passed to ggplot2::theme()
  axis.text = element_blank(),
  legend.position = c( .75, .15))

# the plots take some time to appear in the lower-right window but
# you should be able to see them
#link_plot_zips
link_plot_grids
link_plot_counties
