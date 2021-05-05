#Set start time
start_time <- Sys.time()
#Set the working directory
setwd("~/R/Scripts/Outliers")

library(lubridate)
#install.packages("devtools")
#devtools::install_github("hrbrmstr/AnomalyDetection")
library(AnomalyDetection)
library(hrbrthemes)
library(tidyverse)
library(ggplot2)

#-----------------------Create folder----------------------
directory='Anom_Plots'
dir.create(directory)
output='Filter_Output'
dir.create(output)
#--------------------------------------------------------

#Reading csv files
#Check.names is used to remove the errors in the name columns
readfile <- read.csv("Test_Git.csv",check.names=FALSE,fileEncoding="UTF-8-BOM")
# You will have to change the format of your date time dataset
readfile$Tiempo1 <- strptime(readfile$Tiempo1, format = "%d/%m/%Y", tz= "UTC")
readfile$Tiempo1 <- as.POSIXct(readfile$Tiempo1)


#Well's name
name <- unique(readfile$Name1)

#Auxiliary dataframe wich will be use to save filter results
df <- data.frame(matrix(ncol = 3, nrow = 0))
x <- c("Name1", "Tiempo1", "Nivel1")
colnames(df) <- x

#------------------Create loop for do the filter with all wells--------------

for(wel in name){
  #Filtered
  filter <- readfile %>% filter(readfile$`Name1`==wel)
  Data <- subset( filter, select = c('Tiempo1', 'Nivel1' ) ) #if you use -c(Tiempo1, Nivel1)
  # you will discard those columns
  #-----------------Select max_anoms (mxa) parameter-------------
  ct <- nrow(Data)
  if (ct >= 100) {
    mxa <- 0.45
  } else if (ct < 100 & ct >= 70){
    mxa <- 0.35
  } else if (ct < 70 & ct >= 40){
    mxa <- 0.3
  } else {
    mxa <- 0.2
  }
  
  #This detects the anomalies of the data and it uses tryCatch
  res <- tryCatch(ad_ts(Data, max_anoms=mxa, direction='both'),error = function(e) return(NULL))

  if (is.null(res$anoms)) {
    Data$Name1=paste0(wel,'_SinAnoms')
    Data <- Data[,c('Name1','Tiempo1','Nivel1')]
    df <- rbind(df,Data)
    next
  } else {
    myplot=ggplot(data=Data) +
            geom_line(
              data=Data, aes(Tiempo1, Nivel1,colour = "Time Series"),
              size=0.4) +
            #theme_classic()
            geom_point(
              data=res, aes(timestamp, anoms, colour= 'Anomalies'), alpha=1,size=2
            ) +
            scale_colour_manual("", 
                                breaks = c("Time Series", "Anomalies"),
                                values = c("lightslategray", "#cb181d")) + 
            theme_ipsum_rc(grid="XY") +
            theme(plot.title = element_text(hjust = 0.5)) +
            labs(title=paste0('Well: ',wel))+
            theme(legend.position="bottom",legend.text = element_text(size = 15))
    ggsave(paste0(directory,'/',wel,'_Anoms.jpg'),device = 'jpg', plot = myplot,
           width = 12, height = 8, dpi = 400)
    #---------------------------Filter------------------------------------
    #This will remove the outliers found it before
    Data2 <- subset(Data, !(Data$Tiempo1 %in% res$timestamp))
    Data2$Name1=wel
    Data2 <- Data2[,c('Name1','Tiempo1','Nivel1')]
    df <- rbind(df,Data2)
    
    #To reset row index values use:
    row.names(df) <- NULL
    #-------------------------------------------------------------------
  }
}
write.csv(df,paste0(output,'/Filtro_Anoms.csv'),row.names = FALSE)
#Set end time
elapsed_time <- Sys.time()-start_time
print('Proceso terminado')
elapsed_time

