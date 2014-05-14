setwd("~/Documents/R/chitest/data/")
print ("The CSV file should be named df.csv")
df <- read.csv("~/Documents/R/chitest/data/df.csv")
df$PosixDate <- as.POSIXct(strptime(df$Date, format="%m/%d/%Y %I:%M:%S %p"))
df <- df[c("Primary.Type", "Description", "Latitude", "Longitude", "PosixDate")]
save(df,file="crimestest.rda")
setwd("~/Documents/R/chitest/")

