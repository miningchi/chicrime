library(shiny)
# library(shinyIncubator)
# library(ggplot2)
# library(ggmap)
library(rCharts)
library(doSNOW)
library(foreach)

# Define UI for miles per gallon application
shinyUI(pageWithSidebar(
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Application title
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  headerPanel("Chicago Crime Data Visualisation"),
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Sidebar Panel
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  sidebarPanel(
    
    wellPanel(
      helpText(HTML("<b>READY?</b>")),
      HTML("Continue to scroll down and modify the settings. Come back and click this when you are ready to render new plots."),
      submitButton("Update Graphs and Tables")
    ),
    
    wellPanel(
      helpText(HTML("<b>BASIC SETTINGS</b>")),
      selectInput("crimetype", "Choose Crime Type:", choice = c("THEFT", "BATTERY", "BURGLARY","ROBBERY")),
      helpText("Examples: BATTERY, THEFT etc."),
      
      dateInput("startdate", "Start Date of Data Collection:", value = "2000-01-01", format = "mm-dd-yyyy",
                min = "2000-01-01", max = "2014-09-29"),
      
      dateInput("enddate", "End Date of Data Collection:", value = "2015-01-02", format = "mm-dd-yyyy",
                min = "startdate", max = "2014-09-30"),
      ##Need some validation that enddate is after start date
      
      helpText("Note: Enter info here if we want")      
    ),
    
    wellPanel(
      helpText(HTML("<b>MAP SETTINGS</b>")),
      textInput("center", "Enter a Location to Center Map, such as city or zipcode:", "Chicago"),
      selectInput("facet", "Choose Facet Type:", choice = c("none","type", "month", "category")),
      selectInput("type", "Choose Google Map Type:", choice = c("roadmap", "satellite", "hybrid","terrain")),    
      checkboxInput("res", "High Resolution?", FALSE),
      checkboxInput("bw", "Black & White?", FALSE),
      sliderInput("zoom", "Zoom Level (Recommended - 14):", 
                  min = 9, max = 20, step = 1, value = 12)
    ),
    
    wellPanel(
      helpText(HTML("<b>DENSITY PLOT SETTINGS</b>")),
      sliderInput("alpharanage", "Alpha Range:",
                  min = 0, max = 1, step = 0.1, value = c(0.1, 0.4)),
      sliderInput("bins", "Number of Bins:", 
                  min = 5, max = 50, step = 5, value = 15),
      sliderInput("boundwidth", "Boundary Lines Width:", 
                  min = 0, max = 1, step = 0.1, value = 0.1),
      selectInput("boundcolour", "Boundary Lines Colour:", 
                  choice = c("grey95","black", "white", "red", "orange", "yellow", "green", "blue", "purple")),
      selectInput("low", "Fill Gradient (Low):", 
                  choice = c("yellow", "red", "orange", "green", "blue", "purple", "white", "black", "grey")),
      selectInput("high", "Fill Gradient (High):", 
                  choice = c("red", "orange", "yellow", "green", "blue", "purple", "white", "black", "grey"))
    ),
    
    wellPanel(   
      helpText(HTML("<b>MISC. SETTINGS</b>")),
      checkboxInput("watermark", "Use 'Blenditbayes' Watermark?", TRUE),
      helpText("Note: automatically disabled when 'Facet' is used.")
    ),
    
    wellPanel(
      helpText(HTML("<b>ABOUT US</b>")),
      HTML('Rajiv Shah & Chris Pulec'),
      HTML('<br>'),
      HTML('Big Data Guys'),
      HTML('<br>'),
      HTML('<a href="http://www.rajivshah.com" target="_blank">About Rajiv</a>, ')
    ),
    
    wellPanel(
      helpText(HTML("<b>VERSION CONTROL</b>")),
      HTML('Version 0.1.2'),
      HTML('<br>'),
      HTML('Deployed on 04-Feb-2013')
    ),
    
    wellPanel(
      helpText(HTML("<b>CREDITS</b>")),
      HTML('<a href="https://blenditbayes.shinyapps.io/crimemap/" target=" blank">Crime Data Visualization</a>,  ')
    )
    
  ),
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Main Panel
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  mainPanel(
    tabsetPanel(
      tabPanel("Introduction", includeMarkdown("docs/introduction.md")),
      #tabPanel("LondonR Demo", includeMarkdown("docs/londonr.md")),
      #tabPanel("Sandbox (rCharts)", showOutput("myChart", "nvd3")),
      #tabPanel("Sandbox", includeMarkdown("docs/sandbox.md")),
      tabPanel("Data", dataTableOutput("datatable")),
      tabPanel("Crime Map", plotOutput("map")),
      tabPanel("Trends", plotOutput("trends1")),
      tabPanel("To Do", includeMarkdown("docs/To_do.md")),
      tabPanel("Changes", includeMarkdown("docs/changes.md"))
    ) 
  )
  
))
