#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

shinyServer(function(input, output) {

# Description of filter menu -----------------------------------------------------------

  fil_input <- reactive({
    
    menu_fil %>% 
      filter(Group == input$fil_sel)
    
  })
  
  output$desc <- renderText({
    
    tmp_txt <- fil_input()
    tmp_txt <- tmp_txt$Desc
    tmp_txt
    
  })
  
  
# Choosing between bau or new experiment -----------------------------------
  fil_pois <- reactive({
    
    if (input$bau_switch == T) {
      
      qpois_sel <- input$qpois_select
      
      dt %>% 
        mutate(qpois_lambda = qpois(qpois_sel, sum_lambda)) %>% 
        mutate(prop_error = round((qpois_lambda - SALE_AMT)/qpois_lambda*100, digits = 3),
               SKU_error = qpois_lambda - SALE_AMT) %>%
        select(LOCATION_CODE, PRODUCT_NAME, COLOR, qpois_lambda, SALE_AMT,
               prop_error, SKU_error,
               REQ_DATE, START_DATE, END_DATE)
      
    } else {
      
      dt_bau
        
    }
    
  })

# Minimum Forecast filtering ----------------------------------------------
  
  min_fil <- reactive({

      fil_pois() %>%
        filter(SALE_AMT >= input$fil_min)

  })

# Date Filtering ----------------------------------------------------------

  date_fil <- reactive({

    range_fil <- input$date_fil
    
    min_fil() %>%
      filter(REQ_DATE >= range_fil[1], REQ_DATE <= range_fil[2])

  })
  
# Model filtering ---------------------------------------------------------
  
  model_input <- reactive({
    
    date_fil() %>% 
      filter(PRODUCT_NAME %in% input$model_fil)
    
  })  
  
# Filtering base on accuracy case -----------------------------------------

  user_input <- reactive({
    
    if(input$fil_sel == "All data") {
      
      model_input()
      
    } else if(input$fil_sel == "Proper forecast") {
      
      model_input() %>% 
        filter(prop_error >= -40, prop_error <= 40)
      
    } else if(input$fil_sel == "Under forecast") {
      
      model_input() %>% 
        filter(prop_error < -40)
      
    } else if(input$fil_sel == "Over forecast") {
      
      model_input() %>% 
        filter(prop_error > 40) 
      
    } 
    
  })
  
# Plot histogram ----------------------------------------------------------

  output$his_acc <- renderPlot({
    
    user_input() %>% 
      ggplot(aes(x = prop_error)) + 
      geom_histogram(binwidth = 25, color = "white", fill = "coral2", alpha = 0.7) + 
      ylab("HS forecast records") +
      xlab("Distribution of Forecast error (%)") +
      theme_minimal() +
      theme(text = element_text(size = 15)) +
      scale_x_continuous(limits = c(-200,100))
    
  })
  
  output$his_res <- renderPlot({
    user_input() %>% 
      ggplot(aes(x = SKU_error)) + 
      geom_histogram(binwidth = 1, color = "white", fill = "coral2", alpha = 0.7) + 
      ylab("HS forecast records") +
      xlab("Distribution of Forecast error (SKU)") +
      theme_minimal() +
      theme(text = element_text(size = 15)) +
      scale_x_continuous(limits = c(-10,10))
  })

# Data table output -------------------------------------------------------

  output$details <- DT::renderDataTable({
    
    user_input() %>% 
      select(-START_DATE, -END_DATE) %>% 
      DT::datatable(colnames = c("Location", "Model", "Color", "Forecast", "Actual", "% Error", 
                                 "Error", "Req. Date"), 
                    filter = list(position = "top"))
    
  })

# Value Box ---------------------------------------------------------------
  
  output$no_record <- renderValueBox({
    
    tmp <- user_input()
    no_rec <- nrow(tmp)
    
    valueBox(
      format(no_rec, big.mark = ","), 
      "No. of Records",
      color = "green", icon = icon("bar-chart-o")
    )
  })  
  
  output$Mean_acc <- renderValueBox({
    
    tmp <- user_input()
    tmp %>% 
      filter(is.finite(prop_error)) -> tmp
    
    M_acc <- mean(tmp$prop_error)
    
    valueBox(
      round(M_acc, digits = 3), 
      "Mean % Error by Model",
      color = "red", icon = icon("check-circle")
    )
  })
  
  output$prop_fil <- renderValueBox({
    
    n_base <- nrow(model_input())
    prop_acc <- nrow(user_input())
    
    valueBox(
      round(prop_acc/n_base*100, digits = 3), 
      "% of group",
      color = "green", icon = icon("percent")
    )
  })
  
  output$Mean_total_acc <- renderValueBox({
    
    tmp <- user_input()
    sum_sale <- sum(tmp$SALE_AMT)
    bau_sum <- sum(tmp$FORECAST_SALE_AMT)
    new_sum <- sum(tmp$qpois_lambda)
    
    if (input$bau_switch == T) {
      
      M_total_acc <- (new_sum - sum_sale)/new_sum
      
    } else {
      
      M_total_acc <- (bau_sum - sum_sale)/bau_sum
      
    }
    
    valueBox(
      round(M_total_acc*100, digits = 3),
      "Mean % Error by Total",
      color = "red", icon = icon("check-circle")
    )
    
  })
  
# Download button ---------------------------------------------------------
  
  output$downloadData <- downloadHandler(
    
    filename = function() {
      paste0("Df_accuracy_", input$fil_sel, ".csv")
    },
    
    content = function(file) {
      write_csv(user_input(), file)
      
    }
    
  )
  
})