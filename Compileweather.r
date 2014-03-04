##Compile weather info:
setwd("~/Documents/R/chitest/data/")
print ("The CSV file should be named ChicagoTemperatureData.csv")
weather <- read.csv("~/Documents/R/chitest/data/ChicagoTemperatureData.csv", header=TRUE, sep = "")
weather <- subset(weather, Year>2000)
weather$wDate <- as.Date( paste( weather$Month , weather$Date , weather$Year, sep = "." )  , format = "%m.%d.%Y" )
weather$PosixDate <- as.POSIXct(strptime(weather$wDate, format="%Y-%m-%d"))
weather$TempFahr <- 9/5*weather$Temperature.Celsius.+32
weatherdata <- weather[c(6,7)]
save(weatherdata,file= "weather.rda")
setwd("~/Documents/R/chitest/")

