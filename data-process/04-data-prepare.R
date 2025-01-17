### Author: JMZ
### Modified: 3/17/19
### Purpose: read in and process the raw data files - for use by the package owners

### Note: for file paths this assumes the working directory is the head package directory (soil modeling)

library(tidyverse)
library(devtools)
library(lubridate)
library(SoilModeling)


# Pull in the data that we need to do this problem, using only the microbe an soil data
flux_data <- rapid_data %>% inner_join(select(microbe_data,site,PLOTID,soilC,microbeC,soilWater),by=c("PLOTID","site"))

# Add in a column to flux_data for the different cases of beetle and fire data, which we call treatments
treatment_key <- expand(flux_data, nesting(beetles, fire)) %>%
  mutate(treatment = 1:n())


# average replicates at each site
small_Q10 <- weighted_Q10 %>% group_by(PLOTID) %>% summarize(Q10=mean(Q10))
# Join the Q10 data to the flux data
flux_data <- flux_data %>%
  left_join(select(small_Q10,Q10,PLOTID),by="PLOTID") %>%
  mutate(tempEffect = Q10^(Tsoil_C/10)) %>%
  left_join(treatment_key,by=(c("beetles","fire")))

# Now add in the treatment codes



use_data(flux_data,overwrite = TRUE)


# Save the cases as well
use_data(treatment_key,overwrite = TRUE)


