library(toxEval)
library(dplyr)
library(tidyr)
library(readxl)

source(file = "data_setup.R")
AOP_info <- read_xlsx("SI_6_AOP_relevance With Short AOP name.xlsx", sheet = "SI_AOP_relevance")


plot_heat_AOPs <- function(chemical_summary,AOP_info,
                                chem_site,
                                mean_logic,
                                sum_logic){
  
  SiteID <- site_grouping <- `Short Name` <- chnm <- maxEAR <- ".dplyr"
  site <- EAR <- sumEAR <- meanEAR <- ".dplyr"
  
  graphData <- toxEval:::graph_chem_data(chemical_summary, 
                               mean_logic=mean_logic,
                               sum_logic = sum_logic)
  
  if(!("site_grouping" %in% names(chem_site))){
    chem_site$site_grouping <- "Sites"
  }
  
  graphData <- chemical_summary %>%
    select(-Class) %>%
    left_join(select(AOP_info, AOP, endPoint=`Endpoint(s)`, Class=`X__1`), by="endPoint") %>%
    group_by(site,date,AOP, Class) %>%
    summarise(sumEAR=sum(EAR)) %>%
    data.frame() %>%
    group_by(site, AOP, Class) %>%
    summarise(meanEAR=ifelse(mean_logic,mean(sumEAR),max(sumEAR))) %>%
    data.frame() 
  
  graphData <- graphData %>%
    left_join(chem_site[, c("SiteID", "site_grouping", "Short Name")],
              by=c("site"="SiteID"))
  
  graphData$AOP <- factor(graphData$AOP)
  
  fill_text <- ifelse(mean_logic, "Mean EAR", "Max EAR")
  
  heat <- ggplot(data = graphData) +
    geom_tile(aes(x = `Short Name`, y=AOP, fill=meanEAR)) +
    theme_bw() +
    theme(axis.text.x = element_text( angle = 90,vjust=0.5,hjust = 1)) +
    ylab("AOP ID") +
    xlab("") +
    labs(fill=fill_text) +
    scale_fill_gradient( guide = "legend",
                         trans = 'log',
                         low = "white", high = "steelblue",
                         breaks=c(0.00001,0.0001,0.001,0.01,0.1,1,5),
                         na.value = 'transparent',labels=toxEval:::fancyNumbers2) +
    facet_grid(Class ~ site_grouping, scales="free", space="free") +
    theme(strip.text.y = element_text(angle=0, hjust=0), 
          strip.background = element_rect(fill="transparent", colour = NA),
          # axis.text.y = element_text(face=ifelse(levels(graphData$category) %in% c("Total"),"bold","italic")),
          panel.spacing = unit(0.05, "lines"),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.background = element_rect(fill = "transparent",colour = NA))
  
  return(heat)
  
}

aop_heat <- plot_heat_AOPs(chemicalSummary, AOP_info, tox_list$chem_site, 
               sum_logic = FALSE, mean_logic = FALSE)

ggsave(aop_heat, file="plots/SI6_AOP_heat.png", height = 9, width = 11)