library(toxEval)
library(dplyr)
library(tidyr)
library(ggplot2)
library(grid)

source(file = "data_setup.R")
source(file = "plot_tox_stacks_manuscript.R")

chem_site <- tox_list[["chem_site"]]

dir.create(file.path("plots"), showWarnings = FALSE)

i <- 1
for(class in unique(chemicalSummary$Class)){

  sub_class <- filter(chemicalSummary, Class %in% class)
  
  cleaned_class <- tolower(class)
  
  if(cleaned_class == "pahs"){
    cleaned_class <- "PAHs"
  }
  
  fancyTitle <- bquote(atop(bold("Figure SI-5 "*.(LETTERS[i])*":") ~
"Exposure-activity ratio values by site for chemical class" ~ .(cleaned_class) ~ "in Great Lakes tributaries, 2010-2013."))
  
  splot <- plot_tox_stacks_manuscript(sub_class, 
                               chem_site, 
                               category = "Chemical",
                               caption = fancyTitle)
  ggsave(splot, filename = paste0("plots/SI5",letters[i],".pdf"), width = 11, height = 5)
  i <- i+1
}


