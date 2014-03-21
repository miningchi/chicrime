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
#load(file = "./data/crimestest.rda")
load(file = "./data/crimesfull.rda")

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
 
  output$maptitle <- renderUI({helpText(HTML("<b>MAP SETTINGS</b>"))})
  output$mapcenter <- renderUI({textInput("center", "Enter a Location to Center Map, such as city or zipcode, the click Update", "Chicago")})
  output$mapfacet <- renderUI({selectInput("facet", "Choose Facet Type:", choice = c("none","type", "month", "category"))})
  output$maptype <- renderUI({selectInput("type", "Choose Google Map Type:", choice = c("roadmap", "satellite", "hybrid","terrain"))})
  output$mapres <- renderUI({checkboxInput("res", "High Resolution?", FALSE)})
  output$mapbw <- renderUI({checkboxInput("bw", "Black & White?", FALSE)})
  output$mapzoom <- renderUI({sliderInput("zoom", "Zoom Level (Recommended - 14):", min = 9, max = 20, step = 1, value = 12)})
  
  output$map <- renderPlot({
     
    # Set Defaults for when Map starts
    if (is.null(input$center)) {map.center <- geocode("Chicago")}
      else {map.center = geocode(input$center)}
    
    if (is.null(input$bw)) {temp.color <- "color"}
      else {
         temp.color <- "color"
        if (input$bw) {temp.color <- "bw"}}
      
    if (is.null(input$res)) {temp.scale <- 2}
      else {
       temp.scale <- 1
        if (input$res) {temp.scale <- 2}}
    
    if (is.null(input$zoom)) {temp.zoom <- 14}
      else {temp.zoom <- input$zoom }
    
   #Get Base Map
    map.base <- get_googlemap(
      as.matrix(map.center),
      maptype = input$type, ## Map type as defined above (roadmap, terrain, satellite, hybrid)
     # markers = map.center,
      zoom = temp.zoom,            ## 14 is just about right for a 1-mile radius
      color = temp.color,   ## "color" or "bw" (black & white)
      scale = temp.scale,  ## Set it to 2 for high resolution output
      messaging = FALSE,
    )
    
    ## Convert the base map into a ggplot object
    ## All added Cartesian coordinates to enable more geom options later on
    map.base <- ggmap(map.base, extend = "panel", messaging = FALSE) + coord_cartesian() + coord_fixed(ratio = 1.5)
 
    ## add crime points
    crimetypedatabase <- datetypesubset() 
 p <- map.base + geom_point(aes(x=Longitude, y=Latitude), colour="red", size = 4, na.rm=TRUE, data=crimetypedatabase)
  
 plot(p)
  })
 #, width = 1800, height = 1800)
  
 

 
 
 
 
  ###### Weather variable ###########
    output$weather <- renderPlot({
    
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
 #Adding time series smoothing
 #weatherdata <- SMA(weatherdata,n=3)
 weatherxts <- xts(weatherdata$TempFahr,weatherdata$PosixDate)
 weatherxts<-data.frame(index(weatherxts),coredata(weatherxts[,1]))
 colnames(weatherxts)<-c("dates","temperature")

# Plotting
 #data<-ggplot(crimebytime,aes(dates,crime)) + xlab(NULL) + ylab("crime") + scale_y_log10() 
 #data2 <- data +geom_line(aes(color="red"))+ ggtitle("Crime Trends")
 #data3 <- data2 +geom_line(data=weatherxts,aes(dates, temperature, color="blue"))
 
#New approach to get two Y lines:
grid.newpage()

# two plots
# from http://rpubs.com/kohske/dual_axis_in_ggplot2

p1 <-ggplot(crimebytime,aes(dates,crime)) + geom_line(colour="red") + theme_bw()
p2 <-ggplot(weatherxts,aes(dates,temperature)) + geom_line(colour="blue") + theme_bw() %+replace% 
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
    
