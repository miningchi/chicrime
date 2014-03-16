suppressMessages(library(shiny))
suppressMessages(library(ggplot2))
suppressMessages(library(ggmap))
suppressMessages(library(RJSONIO))
suppressMessages(library(png))
suppressMessages(library(grid))
suppressMessages(library(RCurl))
suppressMessages(library(plyr))
suppressMessages(library(markdown))
suppressMessages(library(rCharts))
suppressMessages(library(parallel))
suppressMessages(library(xts)) #added this for trends
suppressMessages(library(stringr)) #added this for time, not sure if still needed
suppressMessages(library(gtable)) #added this for trends
suppressMessages(library(grid)) #added this for trends
load(file = "./data/weather.rda")
load(file = "./data/crimestest.rda")
#load(file = "./data/crimesfull.rda")

## Define server logic required to summarize and view the selected dataset
shinyServer(function(input, output) {
  
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Reactive Functions
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  datesubset <- reactive({
          subset(df, PosixDate > as.POSIXct(strptime(input$startdate, format="%Y-%m-%d")) & PosixDate < as.POSIXct(strptime(input$enddate, format="%Y-%m-%d")))
                   })
  
  datetypesubset <- reactive({
                 tempdate   <- subset(df, PosixDate > as.POSIXct(strptime(input$startdate, format="%Y-%m-%d")) & PosixDate < as.POSIXct(strptime(input$enddate, format="%Y-%m-%d")))
                 tempdatetype <- subset(tempdate, Primary.Type == input$crimetype)
                 return (tempdatetype)
                 })  

  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Output 1 - Data Table
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  output$datatable <- renderDataTable({
   
    datetypesubset() 
  
    }, options = list(aLengthMenu = c(10, 25, 50, 100, 1000), iDisplayLength = 10))
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Output 2 - Map
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
  output$mapheader <- renderPrint ("Does this work")
  
  output$map <- renderPlot({
     
    #Map Center
    map.center = geocode(input$center, messaging = FALSE)
    
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
      scale = temp.scale,  ## Set it to 2 for high resolution output
      messaging = FALSE,
      # other settings that are not used at the moment
      # language = "en-EN" Ref: https://spreadsheets.google.com/spreadsheet/pub?key=0Ah0xU81penP1cDlwZHdzYWkyaERNc0xrWHNvTTA1S1E&gid=1
      # style              Ref: https://developers.google.com/maps/documentation/staticmaps/#StyledMapElements
    )
    
    ## Convert the base map into a ggplot object
    ## All added Cartesian coordinates to enable more geom options later on
    map.base <- ggmap(map.base, extend = "panel", messaging = FALSE) + coord_cartesian() + coord_fixed(ratio = 1.5)
 
    ## add crime points
    crimetypedatabase <- datetypesubset() 
 p <- map.base + geom_point(aes(x=Longitude, y=Latitude), colour="red", size = 4, na.rm=TRUE, data=crimetypedatabase)
  
 print(p)
  })
 #, width = 1800, height = 1800)
  
  ###### TRENDS ###########
    output$trends1 <- renderPlot({
    
    crimetypedatabase <- datetypesubset()   
   
  #Convert to XTS for analysis Columns should be Primary Type and PosixData
    df.xts <- xts(x = crimetypedatabase[, c("Primary.Type","PosixDate")], order.by = crimetypedatabase[, "PosixDate"])
    #dyearly <- apply.yearly(df.xts, function(d) {print(d)}) # Troubleshooting
  #sum by crime type - NEED to allow different periods
    crimebytime <- apply.monthly(df.xts, function(d) {sum(str_count(d, input$crimetype ))})
    crimebytime<-data.frame(index(crimebytime),coredata(crimebytime[,1]))
    colnames(crimebytime)<-c("dates","crime")
  print(crimebytime)
  
 ##ADD WEATHER
 weatherdata <- subset(weatherdata, PosixDate > as.POSIXct(strptime(input$startdate, format="%Y-%m-%d")) & PosixDate < as.POSIXct(strptime(input$enddate, format="%Y-%m-%d")))
 weatherxts <- xts(weatherdata$TempFahr,weatherdata$PosixDate)
 weatherxts<-data.frame(index(weatherxts),coredata(weatherxts[,1]))
 colnames(weatherxts)<-c("dates","temperature")

# Plotting
 data<-ggplot(crimebytime,aes(dates,crime)) + xlab(NULL) + ylab("crime") + scale_y_log10() 
 data2 <- data +geom_line(aes(color="First line"))+ ggtitle("Crime Trends")
 data3 <- data2 +geom_line(data=weatherxts,aes(dates, temperature, color="Second line"))
 
#New approach to get two Y lines:
grid.newpage()

# two plots
# from http://rpubs.com/kohske/dual_axis_in_ggplot2

p1 <-ggplot(crimebytime,aes(dates,crime)) + geom_line(aes(color="red")) + theme_bw()
p2 <-ggplot(weatherxts,aes(dates,temperature)) + geom_line(aes(color="blue")) + theme_bw() %+replace% 
  theme(panel.background = element_rect(fill = NA))

# extract gtable
g1 <- ggplot_gtable(ggplot_build(p1))
g2 <- ggplot_gtable(ggplot_build(p2))

# overlap the panel of 2nd plot on that of 1st plot
pp <- c(subset(g1$layout, name == "panel", se = t:r))
g <- gtable_add_grob(g1, g2$grobs[[which(g2$layout$name == "panel")]], pp$t, 
                     pp$l, pp$b, pp$l)

# axis tweaks
ia <- which(g2$layout$name == "axis-l")
ga <- g2$grobs[[ia]]
ax <- ga$children[[2]]
ax$widths <- rev(ax$widths)
ax$grobs <- rev(ax$grobs)
ax$grobs[[1]]$x <- ax$grobs[[1]]$x - unit(1, "npc") + unit(0.15, "cm")
g <- gtable_add_cols(g, g2$widths[g2$layout[ia, ]$l], length(g$widths) - 1)
g <- gtable_add_grob(g, ax, pp$t, length(g$widths) - 1, pp$b)

# draw it
grid.draw(g)

#print(data3)
  }, width = 1280, height = 1280)
  
###ANALYSIS 

output$analysis <- renderPlot({
  crimebydate <- datesubset ()
  crimetypefreq <- crimebydate[c("Primary.Type")]
  b <- table(crimetypefreq)
  
print ("working")

print (b)
plot(b)
    })

  })
    
