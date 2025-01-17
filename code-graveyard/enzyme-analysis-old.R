library(tidyverse)
library(devtools)
library(SoilModeling)

### Author: JMZ
### Modified: 3/17/19
### Purpose: calculate Q10 proportion activities for different plots and sites based on enzyme data

inputFile = 'data-raw/MicrobialExoEnzymeActivities_COMASTER_README.csv'  # Data file we will read in to


inputData=read_csv(inputFile)

# Remove site names that we don't want:
siteNames = c('FEF','UMC','NWT','LSP','SPR')

# Gather all the data together and determine the degree used.
enzymes <- inputData %>%
  gather(key=enzyme,value=activity,-(1:10)) %>%
  separate(enzyme,c("enzyme","temperature"),sep="_") %>%  # Remove the underscore and have column for temperature
  filter(SITE %in% siteNames) %>%
  separate(temperature,c("temperature","junk"),sep="C") %>%  # Remove the C label
  mutate(temperature=as.numeric(temperature)) %>%  # make temperature numeric
  select(-junk) %>% # remove the junk column
  left_join(select(rapid_data,PLOTID,beetles,fire),by="PLOTID")  # Add in treatment codes


# Add in a column to flux_data for the different cases of beetle and fire data, which we call treatments
treatment_key <- expand(enzymes, nesting(beetles, fire)) %>%
  mutate(treatment = 1:n())

# Determine the total activity we have for each sample and temperature
total_activity <- enzymes %>%
  group_by(GalleryNumber,temperature) %>%
  summarize(total_activity = sum(activity))


# Join the treatment data to the enzyme
enzymes %>% inner_join(treatment_key,by=c("beetles","fire")) -> enzymes


# Join the activity data to the enzymes
enzyme_proportion <- enzymes %>%
  inner_join(total_activity,by=c("GalleryNumber","temperature")) %>%
  mutate(proportion = activity/total_activity)


enzyme_plot <- enzyme_proportion %>%
  filter(temperature ==15) %>%
  ggplot(aes(x = treatment, y = proportion,color=as.factor(treatment))) +
  geom_jitter(size=1) +
  geom_boxplot(outlier.size=0,alpha=0.5) +
  coord_cartesian(ylim = c(0, 1)) +
  facet_grid(.~enzyme) +
  labs(x='Treatment',y = "Proportional activity at 15 \u00B0C") +
  theme_bw(base_size = 16, base_family = "Helvetica") +
  theme(axis.title.x=element_text(face="bold"),axis.title.y=element_text(face="bold"),strip.background = element_rect(colour="white", fill="white"))+ scale_fill_discrete(name="Site")+
  guides(color=FALSE)


# Make a plot of the proportion of enzyme activity at each reference temperature and enzyme
fileName <- paste0('manuscript-figures/q10ProportionEnzymeSummary.png')
ggsave(fileName,plot=enzyme_plot,width=12,height=5)


# Next: we weight by proportional activity AND enzyme to get a Q10 as a function of temperature for each site.

# The average proportion of enzyme activity weights the contribution to Q10 at a given temperature at each site ...

# Let's think about this:
# - we can calculate the proportion of enzyme activity at each reference temperature.
# - do a regression for the activity weighted Q10 at each reference temperature for each site.


enzymes_Q10 <- enzymes %>%
  group_by(GalleryNumber,enzyme) %>%
  spread(key=temperature,value=activity) %>%
  mutate(Q10_4C = `15`/`4`,Q10_15C = `25`/`15`,Q10_25C = `35`/`25`) %>%
  ungroup() %>%
  select(GalleryNumber,SITE,PLOTID,enzyme,Q10_4C,Q10_15C,Q10_25C) %>% # Pull out variables we need
  gather(key=temperature,value=Q10_ratio,-(1:4)) %>%
  separate(temperature,c("junk","temperature"),sep="_") %>%  # Remove the _ label
  separate(temperature,c("temperature","junk"),sep="C") %>%  # Remove the C label
  mutate(temperature=as.numeric(temperature)) %>%  # make temperature numeric
  select(-junk)  # remove the junk column



 # enzymes_Q10 %>%
  #  ggplot() + geom_line(aes(x=temperature,y=Q10_ratio,group=GalleryNumber),color='grey') +
  #  facet_grid(SITE~enzyme) + ylim(c(0,20)) +
  #  geom_abline(data=hist_data,aes(slope=slope,intercept = intercept),color='blue',size=1)

# We need to join up

# Weight the Q10 ratio by each proportion at each sample
  weighted_Q10 <- enzymes_Q10 %>%
    left_join(select(enzyme_proportion,GalleryNumber,enzyme,temperature,proportion,treatment),
              by=c("GalleryNumber","enzyme","temperature")) %>%
    group_by(treatment,GalleryNumber,temperature) %>%
    summarize(Q10=sum(Q10_ratio*proportion,na.rm=TRUE))

#### Let's just use the weighted Q10 at 15 degrees C  (that is where the majority of the temperatures are ...)

  ### Make a plot of the weighted Q10 by treatment
  weighted_Q10 %>%
    filter(temperature==15) %>%
    ggplot(aes(x = treatment, y = Q10,color=as.factor(treatment))) +
    geom_jitter(size=3) +
    geom_boxplot(outlier.size=0,alpha=0.5) +
    coord_cartesian(ylim = c(0, 7)) +
    labs(x='Treatment',y = bquote(''*Q[10]*'')) +
    theme_bw(base_size = 16, base_family = "Helvetica") +
    theme(axis.title.x=element_text(face="bold"),axis.title.y=element_text(face="bold")) +
    guides(color=FALSE)

  # Define a general fitting function
  fit_enzyme_weighted <- function(sample) {

    fit_data <- sample %>% split(.$treatment) %>%
      map(~lm(.x$Q10 ~.x$temperature)) %>%
      map(summary) %>%
      map(broom::tidy) %>%
      bind_rows(.id="treatment")

    return(fit_data)

  }

  # Now we can plot the histogram by slope and intercept for treatment
  split_data_weighted <- weighted_Q10 %>% split(.$treatment) %>%
    map(fit_enzyme_weighted) %>%
    bind_rows(.id="treatment")

  # We have this almost ...
  # YAY!  Now do a histogram across all the sites
  Q10_temperature <- split_data_weighted %>%
    mutate(GalleryNumber = as.numeric(GalleryNumber)) %>%
    left_join(select(enzymes,GalleryNumber,treatment),by="GalleryNumber")
    group_by(treatment) %>%
    summarize(median=median(estimate) #,
              # q025=quantile(estimate,0.025),
              #  q975=quantile(estimate,0.975)
    ) %>%
    spread(key=term,value=median) %>%
    rename(slope=2,intercept=3)


use_data(split_data_weighted,overwrite = TRUE) # Save all the regression data
use_data(Q10_temperature,overwrite = TRUE)

  ## Let's make a plot of this Q10 as a function of temperature
q10plot <-  weighted_Q10 %>%
    ggplot() + geom_jitter(aes(x=temperature,y=Q10,group=GalleryNumber),color='grey') +
  geom_smooth(aes(x=temperature,y=Q10),method="lm",color='red') +
    #geom_abline(data=filter(Q10_temperature,site %in% unique(microbe_data$site)),aes(slope=slope,intercept=intercept,group=site),color="blue",size=1) +
    ylim(c(0,15)) +
    facet_grid(.~treatment) +
    labs(x ='Temperature (degrees Celsius)', y = bquote(''*Q[10]*'')) +
    theme_bw(base_size = 16, base_family = "Helvetica") +
    theme(axis.title.x=element_text(face="bold"),axis.title.y=element_text(face="bold"),strip.background = element_rect(colour="white", fill="white"))+ scale_fill_discrete(name="Site")+
    guides(color=FALSE)



# Make a plot of the proportion of enzyme activity at each reference temperature and enzyme
fileName <- paste0('manuscript-figures/q10EnzymeSummary.png')
ggsave(fileName,plot=q10plot,width=7,height=5)

