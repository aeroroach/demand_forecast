#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#


# Library loading ---------------------------------------------------------

library(shiny)
library(shinydashboard)
library(tidyverse)
library(DT)

menu_fil <- read_csv("filter_list.csv")

# UI layout ---------------------------------------------------------------

shinyUI(

  dashboardPage(skin = "green",

# Header ------------------------------------------------------------------

                dashboardHeader(title = "Demand Forecast"),

# Side bar ----------------------------------------------------------------

                dashboardSidebar(
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
                    column(width = 4,
                           valueBoxOutput(outputId = "period", width = NULL),
                           valueBoxOutput(outputId = "no_record", width = NULL),
                           valueBoxOutput(outputId = "Mean_acc", width = NULL)),
                    
                    # Histogram
                    column(width = 8,
                           box(title = "Error Histogram", solidHeader = T, status = "warning", width = NULL,
                               plotOutput("his_acc", height = 300)))
                    
                  ),
                  
                  fluidRow(
                    DT::dataTableOutput("details")
                  )
                  
                )                
    
  )
  
)