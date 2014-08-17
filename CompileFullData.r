setwd("~/Documents/R/chicrime/data/")
#print ("The CSV file should be named dffull.csv")
#df <- read.csv("~/Documents/R/chicrime/data/dffull.csv")
#df <- read.csv("~/Box Sync/Crime/All/dffull.csv")
df <- read.csv("~/Box Sync/Crime/2014/Crimes_-_2014.csv")
df$PosixDate <- as.POSIXct(strptime(df$Date, format="%m/%d/%Y %I:%M:%S %p"))
df <- df[c("Primary.Type","Case.Number","IUCR","Community.Area", "Latitude", "Longitude", "PosixDate")]
#df$Simpledate <- as.POSIXct(strptime(df$Date, format="%m/%d/%Y"))
save(df,file="crimesfull2.rda")
setwd("~/Documents/R/chicrime/")
df2014 <- df
#Combine the two-
df2014 <- subset (df2014, PosixDate > as.POSIXct(strptime("2014-1-1",format="%Y-%m-%d")))
total <- subset (df, PosixDate < as.POSIXct(strptime("2014-1-1",format="%Y-%m-%d")))
total <- rbind(total,df2014)
total1 <- total[!duplicated(total), ]
length(unique(total1$Case.Number)) # How many unique ##Need to do a better job removing unique values
df <- df[c("Primary.Type","IUCR","Community.Area", "Latitude", "Longitude", "PosixDate")]
save(df,file="crimesfull2.rda")

#as.POSIXct(strptime("2004-1-1"))  input$enddate, format="%Y-%m-%d")))