#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#


# Define available period -------------------------------------------------

start_list <- as.character(head(sort(unique(dt$START_DATE)), 1))
end_list <- as.character(tail(sort(unique(dt$END_DATE)), 1))
model_list <- unique(sort(dt$PRODUCT_NAME))

# UI layout ---------------------------------------------------------------

shinyUI(

  dashboardPage(skin = "green",

# Header ------------------------------------------------------------------

                dashboardHeader(title = "Demand Forecast"),

# Side bar ----------------------------------------------------------------

                dashboardSidebar(
                  
                  dateRangeInput(inputId = "date_fil", label = h3("Forecast Range"), 
                              start = start_list, end = end_list, 
                              min = start_list, max = end_list), 
                  
                  materialSwitch(
                    inputId = "bau_switch",
                    label = "New Sandbox", 
                    status = "success",
                    right = F
                  ),
                  
                  sliderInput("qpois_select", label = h3("Poisson Conf"), min = 0.50, 
                              max = 0.99, value = 0.95, step = 0.05),
                  
                  sliderInput("fil_min", label = h3("Min. Exclude"), min = 1, 
                              max = 10, value = 5),
                  
                  pickerInput(inputId = "model_fil", label = h3("Model Selection"),
                              choices = as.list(model_list), 
                              selected = model_list,
                              options = list(`live-search` = T,
                                             `actions-box` = T),
                              multiple = T
                              ),
                  
                  selectInput(inputId = "fil_sel", label = h3("Filter criteria"),
                              choices = as.list(menu_fil$Group)), 
                  
                  box(title = "Description", height = 200, width = 12, background = "olive",
                      textOutput("desc")), 
                  
                  downloadButton("downloadData", "Download"),
                  tags$style(type='text/css', "#downloadData {margin-left: 15px;}")
                ),

# Body --------------------------------------------------------------------

                dashboardBody(
                  
                  fluidRow(
                    
                  # Value box  
                    column(width = 2,
                           valueBoxOutput(outputId = "no_record", width = NULL),
                           valueBoxOutput(outputId = "Mean_acc", width = NULL), 
                           valueBoxOutput(outputId = "Mean_total_acc", width = NULL), 
                           valueBoxOutput(outputId = "prop_fil", width = NULL)),
                    
                    # Histogram
                    column(width = 5,
                           box(title = "% Error Histogram", solidHeader = T, status = "danger", width = NULL,
                               plotOutput("his_acc", height = 405))), 

                    column(width = 5,
                           box(title = "SKU Error Histogram", solidHeader = T, status = "danger", width = NULL,
                               plotOutput("his_res", height = 405)))
                  ),
                  
                  fluidRow(
                    DT::dataTableOutput("details")
                  )
                  
                )                
    
  )
  
)