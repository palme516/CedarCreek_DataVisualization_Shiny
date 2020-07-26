library(here); library(overlap); library(maptools); library(lubridate); library(tidyverse); library(Hmisc)

# Import and merge data, covariates -----------------------------------------------

dat <- read.csv("EOTW_DataOutputwHabitat_JCproc12April.csv")
dat <- dat[c("Easting", "Northing", "site_fixed", "season", "speciesID", "ModeHowMany", "ModeAntlers", 
             "ModeYoung", "ModeLyingDown", "ModeStanding", "ModeMoving", "ModeEating",
             "ModeInteracting", "biome", "NLCD_DESCRIPTION", "ENAME",
             "C_TEXT", "DATE", "datetime_exif", "exif__MakerNotes.AmbientTemperature", 
             "exif__MakerNotes.MoonPhase")]
names(dat)[c(3:21)] <- c("site", "data.season", "species", "count", "antlers", "juveniles", "resting",
                         "standing", "moving", "eating", "interacting", "biome", "habitat_class", 
                         "plant_community", "LULC_info", "date", "datetime", "temp.c", "moon.phase")
dat$datetime <- strptime(dat$datetime, "%Y-%m-%d %H:%M:%S")
dat <- dat[!is.na(dat$datetime),] #ugh, for some reason can't figure out, not converting; only 11 entries though so remove 
dat$season <- ifelse(month(dat$datetime) %in% c(3:5), "Spring", 
                     ifelse(month(dat$datetime) %in% c(6:8), "Summer", 
                            ifelse(month(dat$datetime) %in% c(9:10), "Fall", "Winter"))) 
dat$Month <- month(dat$datetime)

# order dat and calculate time difs 
dat <- dat[order(dat$site, dat$species, dat$datetime),]
dat$index <- paste(dat$site, dat$species)
dat$delta.time.secs <- unlist(tapply(dat$datetime, INDEX = dat$index,
                                     FUN = function(x) c(0, `units<-`(diff(x), "secs"))))

# Format and scale times ----------------------------------------------------------

# set spatial coordinates
coords <- matrix(c(-93.201772, 45.42505), nrow=1) %>%
  sp::SpatialPoints(proj4string=sp::CRS("+proj=longlat +datum=WGS84"))

## CORRECT FOR NOT CORRECTING FOR TIME CHANGE 
# Cedar Creek camera traps are kept at one constant time throughout the year and do not change 
# with daylight savings. HOWEVER, the functions used here rely on the camera trap timezone to 
# correctly calculate sunrise/sunset. I have added back in the time changes throughout the years
# so that these sun times are correct. I am assuming that cameras were originally set to 'real time').
                                     
# min(dat$datetime) == 2017-11-20; next time change is 11 March 2018 

#--> for dates between 11-March-2018 and 4 Nov 2018, add +1 hour
# times between 5 Nov 2018 - 9 March 2019 fine 
#--> time between 10 March 2019 - max(dat$datetime)== 15 May 2019, add +1 hour

date.seq <- c(as.character(seq(as.Date("2018-03-11"), as.Date("2018-11-04"), 'days')), as.character(seq(as.Date("2019-03-10"), as.Date("2019-05-15"), 'day')))
dat$date <- as.character(dat$date)
for(i in 1:nrow(dat)){
  dat$correct.datetime[i] <- ifelse(dat$date[i] %in% date.seq, as.character(dat$datetime[i] + hours(1)),
                                    as.character(dat$datetime[i]))
}
x <- dat$correct.datetime
x <- unlist(x, use.names=F)
dat$correct.datetime <- NULL; dat$correct.datetime <- x

# specify date format
dat$date <- as.POSIXct(dat$correct.datetime, format = "%Y-%m-%d", tz = "America/Chicago")

# convert time to radians (could be done more efficiently with pipe)
dat$radians <- ((hour(dat$datetime)*60 + minute(dat$datetime))/(24*60)) * 2 * pi

# calculate suntime using function from overlap package, and coordinates and dates as formatted above
dat$Time.Sun <- sunTime(dat$radian, dat$date, coords)


# Merge with species metadata -----------------------------------------------------

dat$species <- capitalize(as.character(dat$species))
dat[dat$species == "Blackbear",]$species <- "Black Bear"
dat[dat$species == "Wolforcoyote",]$species <- "Wolf or Coyote"
dat[dat$species == "Otherbird",]$species <- "Bird (Other)"
dat[dat$species == "Sandhillcrane",]$species <- "Sandhill Crane"
dat[dat$species == "Birdsofprey",]$species <- "Birds of Prey"
dat[dat$species == "Dragonflyorbutterfly",]$species <- "Dragonfly or Butterfly"
dat[dat$species == "Domesticdogorcat",]$species <- "Domestic Dog or Cat"
dat[dat$species == "Othersmallmammals",]$species <- "Small Mammals (Other)"
dat[dat$species == "Otherrodents",]$species <- "Rodents (Other)"
dat$species <- factor(dat$species)


# Export cleaned file -------------------------------------------------------------

write.csv(dat, "cleaned_data_for_shiny.csv", row.names=F)


# Set up camera operation dates ---------------------------------------------------

effort <- read.csv("EOTW_cameraoperation.csv") 

empty_as_na <- function(x){
  if("factor" %in% class(x)) x <- as.character(x) 
  ifelse(as.character(x)!="", x, NA)
}

effort <- effort %>% mutate_each(funs(as.character)) %>% mutate_each(funs(empty_as_na))

final.df <- NULL 
for(i in 1:nrow(effort)){ 
  x <- effort[i,] %>% select_if(~ !any(is.na(.)))
  end.col <- names(x)[length(x)]
  x <- x %>% gather(., date.type, date.value, from_1:end.col, factor_key=T) 
  x$date.type <- sub("_[^_]+$", "", x$date.type)
  
  tot.seq <- NULL
  for(j in seq(1, by=2, len=nrow(x)/2)){
    sub <- x[c(j,j+1),]
    sub.seq <- as.character(seq(strptime(x[j,3], "%m/%d/%y"), strptime(x[j+1,3], "%m/%d/%y"), by='days')) 
    sub.seq <- substr(sub.seq, 1, 10)
    tot.seq <- c(tot.seq, sub.seq)
  }  
  tot.seq <- tot.seq[!duplicated(tot.seq)]
  sub.df <- data.frame(site = rep(as.character(x$camera[1]), length(tot.seq)), 
                       date = tot.seq)
  final.df <- rbind(final.df, sub.df)
}

write.csv(final.df, "cedarcreek_expanded_searcheffort.csv", row.names=F)
