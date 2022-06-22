# Demand Forecast Project
This project is the example of R codes that has been push to productionize state. It's for the forecast of handset devices that will be allocating to each shops

This algorithm is quite simple (poisson regression) which is quite efficient for integrating into existing legacy system and the result is precise enough to utilize in the real world case.

The interesting points for this project is to use traditional statistics such as poisson distribution to determine the probability of the out of stock situation and estimate the confidence buffer.

## Path structure
- 📦Demand_Forecast
-  ┣ 📂calculate
-  ┃ ┣ 📂image
-  ┃ ┣ 📂input
-  ┃ ┃ ┣ 📂raw
-  ┣ 📂input
-  ┃ ┣ 📂raw
-  ┣ 📂investigate
-  ┣ 📂log
-  ┣ 📂output
-  ┣ 📂shiny
-  ┃ ┣ 📂input
