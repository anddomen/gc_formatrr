library(shiny)
library(bslib)
library(readxl)
library(writexl)
library(tidyverse)

# Define UI for slider demo app ----
ui <- page_fillable(
  # Page theme ----
  theme = bs_theme(bootswatch = "minty"),
  
  # App title ----
  titlePanel("Reformat raw growth curve data from the plate reader"),
  
  # Requirements for using warning box----
  value_box(
    title = "",
    value = tags$p("Warning: This is for outputs from SoftMax pro only. Make sure your raw data file is a .xlsx file, not a .xls file and do not delete any lines.",
                   style = "font-size: 100%"),
    showcase = bsicons::bs_icon("exclamation-circle-fill"),
    showcase_layout = "top right",
    theme = value_box_theme(name = "danger"),
    min_height = "100px",
    max_height = "100px"
    ),
  
  # Value boxes for inputs ----
  layout_column_wrap(
    
    
    # Input: Select a file ----
    value_box(
      title = "Upload your data",
      value = fileInput( 
        "file1",
        label = h6("Choose XLSX File"),
        multiple = TRUE,
        accept = c(
          ".xlsx")
        ),
      showcase = bsicons::bs_icon("filetype-xlsx"),
      min_height = "200px",
      theme = value_box_theme(bg = "#e6f2fd", fg = "#0B538E" )
    ),
    
    
    # Input: Select interval ----
    value_box(
      title = "How long was your interval?",
      value = numericInput(
        "interval",
        label = h6("Enter in minutes"),
        value = 10
      ),
      showcase = bsicons::bs_icon("clock"),
      min_height = "200px",
      theme = value_box_theme(bg = "#ECE7FE", fg = "#482D64" )
    ),

    
    # Input: file name ----
    value_box(
      title = "Download your file",
      value = textInput(
        "filename",
        h6("What do you want your file to be called?"),
        value = "Enter text..."),
      # Download button ----
      downloadButton("downloadData", "Download"),
      showcase = bsicons::bs_icon("box-arrow-down"),
      min_height = "200px",
      theme = value_box_theme(bg = "#D8E7DE", fg = "#45644A" )
    ),
    
    
  ),
  
  # Output: Data file ----
  card(
    tableOutput("contents")
  )
)

# Define server logic to read and manipulate selected file ----
server <- function(input, output) {
  # Format table ----
  # Generate the formatted table after file upload as a reactive object 
  # and assign a name for download later
  df_growthcurve_formatted <- reactive({
    # input$file1 will be NULL initially
    
    req(input$file1)
    
    # import
    df <- read_xlsx(
      input$file1$datapath,
      skip = 2) |> 
      head(-3)
    
    cleaneddf <- df |> 
      select(-"Time") |> 
      rename("Temperature" = "Temperature(¡C)")
    
    #make a vector for the minutes
    minutes <- head(seq(0, nrow(cleaneddf)*input$interval, by = input$interval), -1)
    
    #Add minute and hour column, regroup those to the front
    mutateddf <- cleaneddf |> 
      mutate(Minutes = minutes) |> 
      mutate(Hours = Minutes/60) |> 
      relocate(Minutes, Hours)
    
    #find out the max column number and assign it to an object
    colnumb <- ncol(mutateddf)
    
    #Finally, switch rows and columns
    finaldf <- mutateddf |> 
      gather(key = "Well", value = "OD_reading", 4:colnumb)
    
    
  })
  
  # take the formatted table and render it
  output$contents <- renderTable(
    head(df_growthcurve_formatted(), n = 10)
    
  )
  
  # Download data server side ----
  output$downloadData <- downloadHandler(
    filename = function(){
      paste(input$filename, "_", Sys.Date(), ".xlsx", sep = "")
    },
    
    content = function(file){
      write_xlsx(df_growthcurve_formatted(), file)
    } 
  )
}

# Create Shiny app ----
shinyApp(ui, server)

