# CMS Research Payments 



## Background 

Pharmaceutical companies and device manufacturers must submit disclose payments to the Centers for Medicare & Medicaid Services annually. 

This Quarto dashboard analyzes research payments made to practitioners and institutions in 2023. It is intended for health professionals, journalists, and curious members of the public to see which disciplines receive high research activity, and who are key funding recipients.    


### Preview  


![](img/overview-tab2.png)



## Data  


The following datasets are leveraged:  

* [CMS Open Payments](https://openpaymentsdata.cms.gov/) for research in 2023
* [rnaturalearth](https://github.com/ropensci/rnaturalearth) United States polygons  


## Tools 

### R Version  

This webpage was built with R 4.3.1 and R Studio 2024.12.0.467. 

### Packages  


Data import and wrangling:  

* [data.table](https://cran.r-project.org/web/packages/data.table/index.html)  
* [dplyr](https://dplyr.tidyverse.org/)  
* [janitor](https://cran.r-project.org/web/packages/janitor/index.html) 
* [tidyr](https://tidyr.tidyverse.org/)  
* [forcats](https://forcats.tidyverse.org/)  

String manipulation:  

* [stringr](https://stringr.tidyverse.org/) 
* [glue](https://glue.tidyverse.org/)  
* [tidytext](https://cran.r-project.org/web/packages/tidytext/index.html)  

Visualization and tables:  

* [ggplot2](https://ggplot2.tidyverse.org/)  
* [ggwordcloud](https://lepennec.github.io/ggwordcloud/)  
* [scales](https://scales.r-lib.org/)
* [rnaturalearth](https://github.com/ropensci/rnaturalearth)  
* [leaflet](https://rstudio.github.io/leaflet/)  
* [DT](https://rstudio.github.io/DT/)  
