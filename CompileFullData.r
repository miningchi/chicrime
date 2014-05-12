setwd("~/Documents/R/chicrime/data/")
print ("The CSV file should be named dffull.csv")
df <- read.csv("~/Documents/R/chicrime/data/dffull.csv")
df$PosixDate <- as.POSIXct(strptime(df$Date, format="%m/%d/%Y %H:%M"))
df <- df[c("Primary.Type", "Description", "Latitude", "Longitude", "PosixDate")]
save(df,file="crimesfull.rda")
setwd("~/Documents/R/chicrime/")
