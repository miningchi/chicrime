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
    load("./demo/Crimestest.rda")
    df$NewDate <- as.Date(df$Date, format="%m/%d/%Y %H:%M")
    crimebydate <- subset(df, NewDate > as.Date(input$startdate) & NewDate < as.Date(input$enddate))
   
    
    ##Creates smaller database based on crime type
    crimetypedatabase <- subset(crimebydate, Primary.Type == input$crimetype)
  
    print (input$crimetype)
  ##crimetypedatabase
    crimetypedatabase
    
  }, options = list(aLengthMenu = c(10, 25, 50, 100, 1000), iDisplayLength = 10))
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Output 2 - Heat Map
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
  output$map <- renderPlot({
    ##Center Map on Chicago
    map.center <- geocode("Chicago,IL")
    colnames(map.center) <- c("lon","lat")
    
    ##Creates smaller database based on crime type
    load("./demo/Crimestest.rda")
    df$NewDate <- as.Date(df$Date, format="%m/%d/%Y %H:%M")
    crimebydate <- subset(df, NewDate > as.Date(input$startdate) & NewDate < as.Date(input$enddate))
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
    load("./demo/Crimestest.rda")
    df$NewDate <- as.Date(df$Date, format="%m/%d/%Y %H:%M")
    crimetypedatabase <- subset(df, Primary.Type == input$crimetype)
  
    plot1 <- ggplot(df, aes(x = month, fill = category)) + 
      geom_bar(colour = "black") + facet_wrap(~ category) +
      labs(x = "Months", y = "Crime Records") + 
      ggtitle(paste("Crimes around ", center.df$Location, 
                    ": Trends from ", temp.period[1],
                    " to ", temp.period[length(temp.period)], sep="")) +
      theme_bw() +
      theme(
        plot.title = element_text(size = 36, face = 'bold', vjust = 2),
        #axis.text.x = element_text(angle = 90, hjust = 1),
        axis.text.x = element_blank(),
        axis.text = element_text(size = 24),
        axis.title.x = element_text(size = 32),
        axis.title.y = element_text(size = 32),
        axis.ticks.x = element_blank(),
        strip.background = element_rect(fill = 'grey80'),
        strip.text.x = element_text(size = 26),
        legend.position = "none",
        panel.grid = element_blank()
      )
    
    ## Print
    print(plot1)
    
    }, width = 1280, height = 1280)
  
  })
    
