#1 Setting Paths, and Packages
myDrive <-  getwd()  
myPlace <- paste0(myDrive,"/myCBD/")  
upPlace <- paste0(myDrive,"/myUpstream/")  

# .path   <- paste0(myDrive,"/cbd")
# setwd(.path)

.packages	  <- c("tidycensus",    #load_variables, get_acs
                 "tidyr",         #spread
                 "dplyr",         #select
                 "readr")         #read_file
.inst       <- .packages %in% installed.packages() 
if(length(.packages[!.inst]) > 0) install.packages(.packages[!.inst]) 
lapply(.packages, require, character.only=TRUE)           

.ckey 	<- read_file(paste0(upPlace,"upstreamInfo/census.api.key.txt"))

#2 User Input Variables
#Variable Descriptions: https://www.census.gov/data/developers/data-sets.html
ACSYear     <- 2017
ACSSurvey   <- "acs5" # 5 year (acs5), or 1 year (acs1) data
Labels      <- load_variables(ACSYear,ACSSurvey) # view to see topics and labels
#write.table(Labels, "G:/OHE/HRSU/Fusion Center/Community Burden of Disease/labels.txt", sep="\t")


acs.netuse<-get_acs(state = 06, geography = "tract", survey = ACSSurvey,
                    year = ACSYear, variables = c("B28002_001","B28002_002"), key=.ckey,  moe_level=90)%>%  
  gather(descriptor,value,estimate,moe) %>%
  unite(temp,variable,descriptor) %>%
  spread(temp,value) %>%
  rename(n_net=B28002_002_estimate,N_net=B28002_001_estimate) %>%
  mutate(est_net=n_net/N_net,
         moe_net=moe_ratio(n_net,N_net,B28002_002_moe,B28002_001_moe),
         B28002_002=NULL,B28002_001_moe=NULL)

# ACS Table B17001
# Percent above the Federal Provery Limit
# Related measures include median tract income

acs.poverty<-get_acs(state = 06, geography = "tract", survey = ACSSurvey,
                     year = ACSYear, variables = c("B17001_001","B17001_002"), key=.ckey, moe_level=90) %>% 
  gather(descriptor,value,estimate,moe) %>%
  unite(temp,variable,descriptor) %>%
  spread(temp,value) %>%
  rename(n_pov=B17001_002_estimate,N_pov=B17001_001_estimate) %>%
  mutate(est_pov=n_pov/N_pov,
         moe_pov=moe_ratio(n_pov,N_pov,B17001_002_moe,B17001_001_moe),
         B17001_002_moe=NULL,B17001_001_moe=NULL)  %>%
   select(-NAME)
  

acs.education<-get_acs(state = 06, geography = "tract", survey = ACSSurvey,
                       year = ACSYear, variables = c("B15003_001","B15003_022"), 
                       key=.ckey, moe_level=90) %>% 
  gather(descriptor,value,estimate,moe) %>%
  unite(temp,variable,descriptor) %>%
  spread(temp,value) %>%
  rename(n_edu=B15003_022_estimate,N_edu=B15003_001_estimate) %>%
  mutate(est_edu=n_edu/N_edu,
         moe_edu=moe_ratio(n_edu,N_edu,B15003_022_moe,B15003_001_moe),
         moen = B15003_022_moe,moeN=B15003_001_moe) %>%
  select(-NAME)


# raw measure is percnet in categories. Aggretated here for interpretablhy and consistany with Alameda measures.


acs.rent<-get_acs(state = 06, geography = "tract", survey = ACSSurvey,
                         year = ACSYear, variables = sprintf("B25070_0%02d",1:10),
                         key=.ckey, moe_level=90) %>% 
  mutate(rent= ifelse( variable=="B25070_001",
                       "N_rent",
               ifelse( variable=="B25070_002" | variable=="B25070_003" | variable=="B25070_004" , 
                       "rent00to19",
               ifelse( variable=="B25070_005" | variable=="B25070_006" ,
                       "rent20to29",
                       "rent30up")))) %>%
  group_by(GEOID,NAME,rent) %>%
  #summarize(n=sum(estimate),moe=moe_sum(moe,estimate,na.rm=F)) %>%
  summarize(n=sum(estimate),moe=moe_sum(moe[which(estimate!=0)],which(estimate!=0,arr.ind=T))) %>%  #,na.rm=F
  gather(descriptor,value,n,moe) %>%
  unite(temp,descriptor,rent) %>%
  spread(temp,value) %>%
  rename(N_rent=n_N_rent, moe_rent=moe_N_rent) %>%
  mutate(est_rent00to19 = n_rent00to19/N_rent,
         est_rent20to29 = n_rent20to29/N_rent,
         est_rent30up   = n_rent30up/N_rent
         ,
         moe_rent00to19 = moe_ratio(n_rent00to19, N_rent,moe_rent00to19,moe_rent),
         moe_rent20to29 = moe_ratio(n_rent20to29, N_rent,moe_rent20to29,moe_rent),
         moe_rent30up   = moe_ratio(n_rent30up  , N_rent,moe_rent30up  ,moe_rent)
        ) 



if (1==2){
acs.own<-get_acs(state = 06, geography = "tract", survey = ACSSurvey,
                  year = ACSYear, variables = sprintf("B25106_0%02d",3:6),
                  key=.ckey, moe_level=90) %>% 
  gather(descriptor,value,estimate,moe) %>%
  unite(temp,variable,descriptor) %>%
  spread(temp,value) %>%
  rename(n_own00to19 = B25106_004_estimate,
         n_own20to29 = B25106_005_estimate,
         n_own30up   = B25106_006_estimate,
         N_own       = B25106_003_estimate) %>%
    mutate(est_own00to19 = n_own00to19/N_own,
           est_own20to29 = n_own20to29/N_own,
           est_own30up   = n_own30up/N_own,
           moe_own00to19 = moe_ratio(n_own00to19,N_own,B25106_004_moe,B25106_003_moe),
           moe_own20to29 = moe_ratio(n_own20to29,N_own,B25106_005_moe,B25106_003_moe),
           moe_own30up   = moe_ratio(n_own30up  ,N_own,B25106_006_moe,B25106_003_moe),
           B25106_003_moe=NULL,B25106_004_moe=NULL,B25106_005_moe=NULL,B25106_006_moe=NULL) %>%
  select(-NAME)


acs.renth<-get_acs(state = 06, geography = "tract", survey = ACSSurvey,
                   year = ACSYear, variables = c("B25074_001",sprintf("B25074_0%02d",3:9),
                                                 sprintf("B25074_0%02d",12:18)),
                   key=.ckey, moe_level=90) %>%
  mutate(renth= ifelse( variable=="B25074_001",
                        "N_renth",
                        ifelse( variable=="B25074_003" | variable=="B25074_012",
                        "renth00to19",
                        ifelse( variable=="B25074_004" | variable=="B25074_005" |
                                variable=="B25074_013" | variable=="B25074_014"  ,
                                "renth20to29",
                                "renth30up"))))%>%
  group_by(GEOID,NAME,renth) %>%
  #summarize(n=sum(estimate),moe=moe_sum(moe,estimate,na.rm=F)) #%>%
  #,na.rm=F
  summarize(n=sum(estimate),moe=moe_sum(moe[which(estimate!=0)],which(estimate!=0,arr.ind=T))) %>%
  gather(descriptor,value,n,moe) %>%
  unite(temp,descriptor,renth) %>%
  spread(temp,value) %>%
  rename(N_renth=n_N_renth, moe_renth=moe_N_renth) %>%
  mutate(est_renth00to19 = n_renth00to19/N_renth,
         est_renth20to29 = n_renth20to29/N_renth,
         est_renth30up   = n_renth30up/N_renth,
         moe_renth00to19 = moe_ratio(n_renth00to19 , N_renth,moe_renth00to19,moe_renth),
         moe_renth20to29 = moe_ratio(n_renth20to29,N_renth,moe_renth20to29,moe_renth),
         moe_renth30up   = moe_ratio(n_renth30up  ,N_renth,moe_renth30up  ,moe_renth))
#
#
acs.mortg<-get_acs(state = 06, geography = "tract", survey = ACSSurvey,
                  year = ACSYear, variables = sprintf("B25101_0%02d",3:6),
                  key=.ckey, moe_level=90) %>%
  gather(descriptor,value,estimate,moe) %>%
  unite(temp,variable,descriptor) %>%
  spread(temp,value) %>%
  rename(n_mortg00to19 = B25101_003_estimate,
         n_mortg20to29 = B25101_004_estimate,
         n_mortg30up   = B25101_005_estimate,
         N_mortg       = B25101_006_estimate) %>%
  mutate(est_mortg00to19 = n_mortg00to19/N_mortg,
         est_mortg20to29 = n_mortg20to29/N_mortg,
         est_mortg30up   = n_mortg30up/N_mortg,
         moe_mortg00to19 = moe_ratio(n_mortg00to19,N_mortg,B25101_004_moe,B25101_003_moe),
         moe_mortg20to29 = moe_ratio(n_mortg20to29,N_mortg,B25101_005_moe,B25101_003_moe),
         moe_mortg30up   = moe_ratio(n_mortg30up  ,N_mortg,B25101_006_moe,B25101_003_moe)) %>%
   select(-B25101_003_moe, -B25101_004_moe,-B25101_005_moe,-B25101_006_moe,-NAME)
} # end if 1==2


combined<-Reduce(function(x,y) merge(x,y,all=TRUE),mget(ls(pattern='acs.+')))

sdoh_dat_tract <- full_join(acs.education,acs.poverty,by="GEOID") %>%
                  full_join(acs.netuse %>% select(-NAME)) %>%
                  full_join(acs.rent)

cbdLinkCA  <- read.csv(paste0(myPlace,"/myInfo/Tract to Community Linkage.csv"),colClasses = "character")  # file linking MSSAs to census 
                                  # dataframe linking comID and comName





sdoh_dat_county <- left_join(sdoh_dat_tract,cbdLinkCA,by="GEOID") %>%
                     group_by(county) %>%
                     summarize(N_edu = sum(N_edu,na.rm=TRUE),
                               n_edu = sum(n_edu,na.rm=TRUE),
                               est_edu = round(100*(n_edu/N_edu),2)
                               )

# just education
sdoh_dat_county <- left_join(acs.education,cbdLinkCA,by="GEOID") %>%
  group_by(county) %>%
  summarize(N_edu = sum(N_edu,na.rm=TRUE),
            n_edu = sum(n_edu,na.rm=TRUE),
            est_edu = round(100*(n_edu/N_edu),2),
            moen  = moe_sum(moen, estimate =  n_edu, na.rm = TRUE),
            moeN = moe_sum(moeN, estimate =  N_edu, na.rm = TRUE),
            moe_edu = round(100*moe_ratio(n_edu,N_edu,moen,moeN),3)
  )



if (1==2) {

sdoh_dat_county <- left_join(acs.education,cbdLinkCA,by="GEOID") %>%
  group_by(county) %>%
  summarize(N_edu_C = sum(N_edu,na.rm=TRUE),
            n_edu_C = sum(n_edu,na.rm=TRUE),
            est_edu_C = round(100*(n_edu_C/N_edu_C),2),
            est_edu_X = (sum(est_edu*N_edu,na.rm=TRUE)/N_edu_C),
            moe_edu_C = round(100* (sqrt ( sum(moe_edu^2,na.rm=TRUE)) / N_edu_C),3),
            moe_SUM  = sqrt ( sum(moe_edu^2,na.rm=TRUE)),
            moe_SUM_BEN  = moe_sum(moe_edu, estimate = NULL, na.rm = TRUE),
            moe_n  = moe_sum(moen, estimate =  n_edu, na.rm = TRUE),
            moe_N  = moe_sum(moeN, estimate =  N_edu, na.rm = TRUE) ) %>%
            mutate(moeXXX = moe_ratio(n_edu_C,N_edu_C,moe_n,moe_N)
           
  )
}




sdoh_dat_community <- left_join(sdoh_dat_tract,cbdLinkCA,by="GEOID") %>%
  group_by(comID) %>%
  summarize(N_edu_C = sum(N_edu,na.rm=TRUE),
            n_edu_C = sum(n_edu,na.rm=TRUE),
            est_edu_C = round(100*(n_edu_C/N_edu_C),2),
            est_edu_X = (sum(est_edu*N_edu,na.rm=TRUE)/N_edu_C),
            moe_edu_C = round(100* (sqrt ( sum(moe_edu^2,na.rm=TRUE)) / N_edu_C),3)
            
  )


