setwd to demo: setwd("~/Documents/R/chitest/data/")
The CSV file should be named df.csv
Import the CSV file: df <- read.csv("~/Documents/R/chitest/data/df.csv")
Add the new date: df$NewDate <- as.Date(df$Date, format="%m/%d/%Y %H:%M")
Save the RDA file: save(df,file="crimestest.rda")