setwd("~/Documents/R/chitest/data/")
print ("The CSV file should be named dffull.csv")
df <- read.csv("~/Documents/R/chitest/data/dffull.csv")
df$PosixDate <- as.POSIXct(strptime(df$Date, format="%m/%d/%Y %H:%M"))
df <- df[c("Primary.Type", "Description", "Latitude", "Longitude", "PosixDate")]
save(df,file="crimesfull.rda")
setwd("~/Documents/R/chitest/")