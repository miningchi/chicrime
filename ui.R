suppressMessages(library(shiny))
suppressMessages(library(rCharts))
suppressMessages(library(doSNOW))
suppressMessages(library(foreach))

shinyUI(pageWithSidebar(
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Application title
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  headerPanel("MiningChi - Chicago Crime Data Visualisation"),
  
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
      
      helpText("MM-DD-YEAR as Date Format")      
    ),
    
    wellPanel(
#       helpText(HTML("<b>MAP SETTINGS</b>")),
#   textInput("center", "Enter a Location to Center Map, such as city or zipcode:", "Chicago"),
#       selectInput("facet", "Choose Facet Type:", choice = c("none","type", "month", "category")),
#       selectInput("type", "Choose Google Map Type:", choice = c("roadmap", "satellite", "hybrid","terrain")),    
#       checkboxInput("res", "High Resolution?", FALSE),
#   checkboxInput("bw", "Black & White?", FALSE)
#       sliderInput("zoom", "Zoom Level (Recommended - 14):", 
#                   min = 9, max = 20, step = 1, value = 12)
#     
      )
    
   ),
  
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Main Panel
  ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
#just need to find the right HTML formatting

  mainPanel(
    tabsetPanel(
      tabPanel("Introduction", includeMarkdown("docs/introduction.md")),
      tabPanel("Data", dataTableOutput("datatable")),
      tabPanel("Crime Map", verbatimTextOutput("mapheader"), uiOutput("mapcenter"), uiOutput("mapzoom"),
               plotOutput("map",height = 600, width = 600), div(class="span1",uiOutput("mapfacet")),uiOutput("maptype"),uiOutput("mapres"),
               div(class="row-fluid",uiOutput("mapbw"))),
      tabPanel("Analysis", plotOutput("analysis")),
      tabPanel("Weather", plotOutput("weather")),
      tabPanel("Credits", includeMarkdown("docs/credits.md"))
    ) 
  )
  
))
