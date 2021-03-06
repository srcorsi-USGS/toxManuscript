library(toxEval)
library(dplyr)
library(tidyr)
library(stringi)

source(file = "data_setup.R")

chemicalSummary <- chemicalSummary %>%
  left_join(select(endPointInfo, 
                   endPoint=assay_component_endpoint_name,
                   family = intended_target_family,
                   subFamily = intended_target_family_sub), by="endPoint") 

graphData <- chemicalSummary %>%
  filter(!is.na(subFamily)) %>%
  group_by(site, Bio_category, subFamily, date) %>%
  summarize(sumEAR = sum(EAR)) %>%
  group_by(site, Bio_category, subFamily) %>%
  summarize(meanEAR = max(sumEAR)) %>%
  data.frame() %>%
  mutate(subFamily = stri_trans_totitle(subFamily))

orderSub <- graphData %>%
  group_by(Bio_category) %>%
  summarise(median = median(meanEAR[meanEAR != 0])) %>%
  data.frame() %>%
  arrange(desc(median))

orderGroups <- graphData %>%
  group_by(subFamily, Bio_category) %>%
  summarise(median = quantile(meanEAR[meanEAR != 0],0.5)) %>%
  data.frame() %>%
  mutate(Bio_category = factor(Bio_category, levels=orderSub$Bio_category)) %>%
  arrange(Bio_category, desc(median))

orderedSub <- rev(orderGroups$subFamily)[rev(orderGroups$subFamily) %in%                                unique(graphData$subFamily)]
orderedSub <- unique(orderedSub)

graphData$subFamily <- factor(graphData$subFamily, 
                              levels = orderedSub)

graphData$Bio_category <- factor(graphData$Bio_category, 
                                 levels = orderSub$Bio_category)

cbValues <- c("#DCDA4B","#999999","#00FFFF","#CEA226","#CC79A7","#4E26CE",
              "#FFFF00","#78C15A","#79AEAE","#FF0000","#00FF00","#B1611D",
              "#FFA500","#F4426e", "#4286f4","red","pink")

countNonZero <- graphData %>%
  group_by(subFamily) %>%
  summarise(nonZero = as.character(length(unique(site[meanEAR>0])))) %>%
  data.frame()

subPlot <- ggplot(graphData)+
  scale_y_log10("Maximum EAR Per Site",labels=toxEval:::fancyNumbers)+
  geom_boxplot(aes(x=subFamily, y=meanEAR,fill = Bio_category),
               lwd=0.1,outlier.size=1) +
  coord_flip() +
  theme_bw() +
  xlab("") +
  theme(plot.background = element_rect(fill = "transparent",colour = NA),
        axis.text = element_text(size=8, color = "black"),
        axis.text.y = element_text(vjust = 0.2), 
        axis.text.x = element_text(vjust = 0, margin = margin(-0.5,0,0,0)),
        axis.title = element_text(size=10)) +
  scale_fill_manual(values = cbValues, drop=TRUE)  +
  guides(fill=guide_legend(ncol=6)) +
  theme(legend.position="bottom",
        legend.justification = "left",
        legend.background = element_rect(fill = "transparent", colour = "transparent"),
        legend.title=element_blank(),
        legend.text = element_text(size=8),
        legend.key.height = unit(1,"line")) 

plot_info <- ggplot_build(subPlot)
layout_stuff <- plot_info$layout

if(packageVersion("ggplot2") >= "2.2.1.9000"){
  xmin <- 10^(layout_stuff$panel_scales_y[[1]]$range$range[1])
} else {
  xmin <- 10^(layout_stuff$panel_ranges[[1]]$x.range[1])
}


subPlot <- subPlot + 
  geom_text(data=countNonZero, aes(x=subFamily, y=xmin,label=nonZero),size=3) 

subPlot

dir.create(file.path("plots"), showWarnings = FALSE)
ggsave(subPlot, filename = "plots/SI6_subFamilies.png", width = 5, height = 5)
