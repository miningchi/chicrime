library(shiny)
library(ggplot2)
library(ggmap)
library(RJSONIO)
library(png)
library(grid)
library(RCurl)
library(plyr)
library(markdown)
library(rCharts)
library(parallel)
library(xts)
library(stringr)

## Define server logic required to summarize and view the selected dataset
shinyServer(function(input, output) {
  
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Reactive Functions
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  ## Get Geocode
  map.geocode <- reactive({
    suppressMessages(data.frame(geocode = geocode(input$poi)))
  })
  
  ## Define Period
  map.period <- reactive({
    format(seq(input$start, length=input$months, by="months"), "%Y-%m")
  })
  
  ## Create Data Framework
  create.df <- reactive({
    
    ## Use Multicore if available
    num_core <- parallel::detectCores()
    if (num_core > 1) {
      registerDoSNOW(makeCluster(max(c(2, (num_core - 1))), type="SOCK"))
    }
    
    ## Mini function 1
    mini.unlist <- function(temp.data) {
      temp.data <- unlist(temp.data)
      output <- data.frame(
        category = temp.data[1],
        streetid = temp.data[4],
        streetname = temp.data[7],
        latitude = as.numeric(temp.data[5]),
        longitude = as.numeric(temp.data[8]),
        month = temp.data[10],
        type = temp.data[11])
      return(output)
    }
    
    ## Use Reactive Functions
    temp.geocode <- map.geocode()
    temp.period <- map.period()
    
    ## Output
    df
  })
   
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Output 1 - Data Table
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
  output$datatable <- renderDataTable({
    ##Main Data File
    load("./data/Crimestest.rda")
    #Subsets by date
    crimebydate <- subset(df, PosixDate > as.POSIXct(strptime(input$startdate, format="%Y-%m-%d")) & PosixDate < as.POSIXct(strptime(input$enddate, format="%Y-%m-%d")))
    ##Creates smaller database based on crime type
    crimetypedatabase <- subset(crimebydate, Primary.Type == input$crimetype)
    crimetypedatabase$PosixDate <- as.POSIXct(strptime(crimetypedatabase$Date, format="%m/%d/%Y %H:%M"))
    print (input$crimetype)
  ##crimetypedatabase
    crimetypedatabase
    
  }, options = list(aLengthMenu = c(10, 25, 50, 100, 1000), iDisplayLength = 10))
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Output 2 - Map
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
  output$map <- renderPlot({
    ##Center Map on Chicago
    map.center <- geocode("Chicago,IL")
    colnames(map.center) <- c("lon","lat")
    
    ##Creates smaller database based on crime type
    load("./data/Crimestest.rda")
    crimebydate <- subset(df, PosixDate > as.POSIXct(strptime(input$startdate, format="%Y-%m-%d")) & PosixDate < as.POSIXct(strptime(input$enddate, format="%Y-%m-%d")))
    crimetypedatabase <- subset(crimebydate, Primary.Type == input$crimetype)
    
    ##Plots values
    ##Need to update to allow for other types of maps
    ##Maybe map with another source - get google map
    ##SHmap <- qmap(c(lon=map.center$lon, lat=map.center$lat), source="google", zoom=12)
   
    map.center = geocode(input$center)
    temp.color <- "color"
    if (input$bw) {temp.color <- "bw"}
    temp.scale <- 1
    if (input$res) {temp.scale <- 2}
    
    map.base <- get_googlemap(
      as.matrix(map.center),
      maptype = input$type, ## Map type as defined above (roadmap, terrain, satellite, hybrid)
     # markers = map.center,
      zoom = input$zoom,            ## 14 is just about right for a 1-mile radius
      color = temp.color,   ## "color" or "bw" (black & white)
      scale = temp.scale,   ## Set it to 2 for high resolution output
      # other settings that are not used at the moment
      # language = "en-EN" Ref: https://spreadsheets.google.com/spreadsheet/pub?key=0Ah0xU81penP1cDlwZHdzYWkyaERNc0xrWHNvTTA1S1E&gid=1
      # style              Ref: https://developers.google.com/maps/documentation/staticmaps/#StyledMapElements
    )
    
    ## Convert the base map into a ggplot object
    ## All added Cartesian coordinates to enable more geom options later on
    map.base <- ggmap(map.base, extend = "panel") + coord_cartesian() + coord_fixed(ratio = 1.5)
 
    ## add crime points
 p <- map.base + geom_point(aes(x=Longitude, y=Latitude), colour="red", size = 4, data=crimetypedatabase)
    print(p)
  }, width = 1280, height = 1280)
  
  ###### TRENDS ###########
    output$trends1 <- renderPlot({
    
    #load data  
    load("./data/Crimestest.rda")
    crimebydate <- subset(df, PosixDate > as.POSIXct(strptime(input$startdate, format="%Y-%m-%d")) & PosixDate < as.POSIXct(strptime(input$enddate, format="%Y-%m-%d")))
    crimetypedatabase <- subset(crimebydate, Primary.Type == input$crimetype)
   # crimetypedatabase <- crimetypedatabase[complete.cases(crimetypedatabase), ]
    crimetypedatabase$PosixDate <- as.POSIXct(strptime(crimetypedatabase$Date, format="%m/%d/%Y %H:%M"))
 
  #Convert to XTS for analysis Columns should be Primary Type and NewDate
    df.xts <- xts(x = crimetypedatabase[, c(6,23)], order.by = crimetypedatabase[, "PosixDate"])
  
    #header <- head(df.xts, n=10)
    #print(header)
    #dyearly <- apply.yearly(df.xts, function(d) {print(d)}) # Troubleshooting
  
  #sum by crime type
  crimebytime <- apply.monthly(df.xts, function(d) {sum(str_count(d, input$crimetype ))})
  
  header <- head(crimebytime, n=10)
  print(header)
  
  #test <- to.daily(crimebytime,drop.time=TRUE,range)
  #header <- head(test, n=10)
 # print(header)
  
  
 ##ADD WEATHER
 
  load("./data/weather.rda")
 #crimebytime$weather <- weatherfinal$TempFahr[match(crimebytime$NewDate,weatherfinal$wDate)]
 weatherxts <- xts(weatherdata$TempFahr,weatherdata$PosixDate)
 #Round data to daily
 
 header <- head(weatherxts, n=10)
 print(header)
 
 crimeandweather <-merge(crimebytime, weatherxts)
 data <- crimeandweather[index(df.xts),]

 header <- head(data, n=10)
 print(header)
 
 ##Plotting
 #plot(crimebytime)
 plot(as.zoo(data), screens=1)
 plot(as.zoo(data), plot.type='single')
  }, width = 800, height = 800)
  
  })
    
