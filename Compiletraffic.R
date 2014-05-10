setwd("~/Documents/R/chicrime/data/")
print ("The CSV file should be named df.csv")
traffic <- read.csv("~/Documents/R/chicrime/data/Chicago_Traffic_Tracker_-_Congestion_Estimates_by_Segments.csv")
traffic$PosixDate <- as.POSIXct(strptime(df$Date, format="%m/%d/%Y %H:%M"))
save(traffic,file="traffic.rda")
setwd("~/Documents/R/chicrime/")

