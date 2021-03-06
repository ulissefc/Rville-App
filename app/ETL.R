#################################################################################
############################# Read in all Data ##################################
#################################################################################
#Read csv files
source(file = 'actuals.R')
source(file = 'readProj.R')
trim <- function (x) gsub("^\\s+|\\s+$", "", x)

reg_data <- read.csv(file = "data/Reg_Data_RVille.csv" )
playoff_data <- read.csv(file = "data/Playoff_Data_RVille.csv")
draft <- read.csv(file = "data/Draft_Data_Rville.csv")
actuals <- read_hist()
proj <- read_proj()

#################################################################################
################################### Clean Data ##################################
#################################################################################
###REGULAR SEASON DATA: 6 SEASONS
Reg_Data_01 <- reg_data %>%
              select(-Score,-Opponent,-Opponent.Name) %>%
              plyr::rename(c('Real.Opponent.Name' = 'Opponent_Name'))
Reg_Data_01$Team <- as.character(Reg_Data_01$Team) 
Reg_Data_01$Opponent_Name <- as.factor(Reg_Data_01$Opponent_Name)
Reg_Data_01$Win <- ifelse(Reg_Data_01$Outcome == 'Win',1,0)
Reg_Data_01$Loss <- ifelse(Reg_Data_01$Outcome == 'Loss',1,0)
Reg_Data_01$Pts_100 <- ifelse(Reg_Data_01$Points.For >= 100,1,0)




#PLAYOFF DATA: 6 SEASONS
playoff_data$Playoff_Wins <- ifelse(playoff_data$Outcome != 'Win',0,ifelse(playoff_data$Opponent == "Bye",0,1))
playoff_data$Playoff_Losses <- ifelse(playoff_data$Outcome == "Loss",1,0)
playoff_data$Byes <- ifelse(playoff_data$Opponent == "Bye",1,0)
playoff_data$Championships <- ifelse(playoff_data$Round != "Final",0,ifelse(playoff_data$Outcome == "Win",1,0))
playoff_data$Second_Place <- ifelse(playoff_data$Round != "Final",0,ifelse(playoff_data$Outcome == "Loss",1,0))
playoff_data$Third_Place <- ifelse(playoff_data$Round != "Third Place Game",0,ifelse(playoff_data$Outcome == "Win",1,0))
playoff_data$Playoff_Apperances <- ifelse(playoff_data$Round == "Quarter Final",1,0)

####DRAFT RESULTS DATA: 6 SEASONS
draft$WR <- ifelse(draft$POS == "WR",1,0)
draft$RB <- ifelse(draft$POS == "RB",1,0)
draft$QB <- ifelse(draft$POS == "QB",1,0)
draft$TE <- ifelse(draft$POS == "TE",1,0)
draft$DEF <- ifelse(draft$POS == "DEF",1,0)
draft$K <- ifelse(draft$POS == "K",1,0)

draft$Name <- gsub("\\s*\\([^\\)]+\\)","",as.character(draft$Player))
draft$Name <- gsub('Jr',"",gsub('Jr.',"",draft$Name))
draft$Name <- gsub('Sr.',"",draft$Name)

 draft <- select(draft,Year,Round,Pick,Name,POS,Team,WR,RB,QB,TE,DEF,K)

#Calculate average defense projections for 2014 to 2016: Impute average score for 2012 and 2013 with no data
Ave_Def <- proj %>%
  filter(Year > 2013, POS == "DEF") %>%
  group_by(Name) %>%
  summarize(Ave_Def = mean(Proj_Pts))

# #Calculate average defense projections for 2014 to 2016: Impute average score for 2012 and 2013 with no data
Ave_K <- proj %>%
  filter(Year > 2013, POS == "K") %>%
  group_by(Name) %>%
  summarize(Ave_K = mean(Proj_Pts))

###MERGE DRAFT RESULTS, PROJECTED FF PTS, AND ACTUAL FF PTS
draft$Name <- trim(draft$Name)
actuals$Name <- trim(actuals$Name)

#Merge draft results with Actuals Points Scored
Draft_Actuals <- left_join(draft,actuals, by = c('Year' = 'Year','Name' = 'Name'))
Draft_Actuals[is.na(Draft_Actuals)] <- 0 #missing actuals for players drafted and did not play

#Merge in Projections
Draft_Act_Proj_00 <- left_join(Draft_Actuals,proj, by = c('Year' = 'Year','Name' = 'Name','POS' = 'POS'))
Draft_Act_Proj_01 <- left_join(Draft_Act_Proj_00,Ave_Def, by = c('Name' = 'Name'))
Draft_Act_Proj_02 <- left_join(Draft_Act_Proj_01,Ave_K, by = c('Name' = 'Name'))
#Assign Average Defense projections for Kickers and Def prior to 2014.
Draft_Act_Proj_02$Projections <- ifelse(Draft_Act_Proj_02$Year < 2014 & Draft_Act_Proj_02$POS == "DEF",Draft_Act_Proj_02$Ave_Def,
                                 ifelse(Draft_Act_Proj_02$Year < 2014 & Draft_Act_Proj_02$POS == "K",Draft_Act_Proj_02$Ave_K,
                                        Draft_Act_Proj_02$Proj_Pts))

Draft_Act_Proj <- Draft_Act_Proj_02 %>%
                      select(-Proj_Pts,-Ave_Def,-Ave_K)
Draft_Act_Proj[is.na(Draft_Act_Proj)] <- 0
# Draft_Act_Proj <- Draft_Act_Proj[!(Draft_Act_Proj$Team == "Milk Man" &
#                                    Draft_Act_Proj$Name == "Zach Miller" &
#                                    Draft_Act_Proj$Projections == 0),]

#################################################################################
#####################  Regular Season Statistics ################################
################################################################################# 
#Historical overall statistics. Based on data through 2011. 
# Overall_Stats <- Reg_Data_01 %>%
#             group_by(Team) %>%
#             summarize(Overall_Pts_For = mean(Points.For), 
#                       Overall_Pts_Against = mean(Points.Against),
#                       Win_Pct = mean(Win_Pct))
# 
# #Season statistics
# Season_Stats <- Reg_Data_01 %>%
#                   group_by(Team,Season) %>%
#                   summarize(Pts_For = mean(Points.For),
#                             Pts_Against = mean(Points.Against),
#                             Win_Pct = mean(Win_Pct))
# 
# BestWorst_Seasons <- Season_Stats %>%
#                 group_by(Team) %>%
#                 summarize(Best_Season = max(Pts_For),
#                           Best_WinPct = max(Win_Pct),
#                           Worse_Season = min(Pts_For),
#                           Worse_WinPct = min(Win_Pct))
# 
# #Individual Game Statistics
# Game_Stats <- Reg_Data_01 %>%
#                 group_by(Team) %>%
#                 summarize(Best_Week = max(Points.For),
#                           Worse_Week = min(Points.For))
# 
# #Merge Statistics, Calc Wins and Losses, Format
# reg_statistics <- join_all(list(Overall_Stats,BestWorst_Seasons,Game_Stats), by = 'Team', type = 'left') %>%
#                       mutate(Wins = 65*Win_Pct, Losses = 65*(1-Win_Pct))
# 
# reg_statistics <- reg_statistics[,c(1,11,12,4,2,3,5:10)]



############################################################
############## Overall Record###############################
############################################################

Overall_Record <- Reg_Data_01 %>%
  group_by(Team) %>%
  summarize(Wins = sum(Win), Losses = sum(Loss))

Overall_Points_Season <- Reg_Data_01 %>%
  group_by(Season, Team) %>%
  summarize(Pts = sum(Points.For))
  
Overall_Points_Season <- Overall_Points_Season %>%
  group_by(Season) %>%
  summarize(Most = max(Pts), Least = min(Pts))  

Years_Active <- Reg_Data_01 %>%
  group_by(Team) %>%
  summarize(Yrs_Active = (sum(Win) + sum(Loss))/13)

############################################################
##############  Overall Points For Above Leg Lag ###########
############################################################ 
#Overall Points For
Historical_Pts_For_GM <- aggregate(Points.For ~ Team, data = Reg_Data_01, mean, na.rm = TRUE)
Historical_Pts_For_GM <- Historical_Pts_For_GM %>%
  plyr::rename(c('Points.For' = 'Overall_Pts_For')) %>%
  mutate(Dummy = "All")


Hist_Pts_For_Leg <- Reg_Data_01 %>%
  summarize(Total_Points = mean(Points.For)) %>%
  mutate(Dummy = "All")

Hist_Pts_All <- left_join(Historical_Pts_For_GM,Hist_Pts_For_Leg, by = c('Dummy' = 'Dummy')) %>%
  mutate(Diff = Overall_Pts_For - Total_Points) %>%
  select(-Dummy, -Total_Points, -Overall_Pts_For)

############################################################
############## Weeks Over 100 Pts Scored####################
############################################################

Games_Over_100 <- Reg_Data_01 %>%
  group_by(Team) %>%
  summarize(Games_100 = sum(Pts_100))


############################################################
############## Weeks Highest Points Scored######################
############################################################

Games_High_Score <- Reg_Data_01 %>%
  group_by(Season, Week) %>%
  summarize(Games_High_Score = max(Points.For), Games_Low_Score = min(Points.For))

HighLow <- left_join(Reg_Data_01, Games_High_Score, by = c('Season' = 'Season', 'Week' = 'Week'))

#Create indicator if highest or lowest points of week
HighLow$Pts_High <- ifelse(HighLow$Points.For == HighLow$Games_High_Score,1,0)
HighLow$Pts_Low <- ifelse(HighLow$Points.For == HighLow$Games_Low_Score,-1,0)

Total_HighLow <- HighLow %>%
  group_by(Team) %>%
  summarize(Total_High = sum(Pts_High), Total_Low = sum(Pts_Low))

############################################################
################## Merge Regular Season Statistics #########
############################################################

reg_statistics <- join_all(list(Overall_Record, Hist_Pts_All, Games_Over_100, Total_HighLow, Years_Active ), by = 'Team', type = 'left')
                  

#reg_statistics <- reg_statistics[,c(1,11,12,4,2,3,5:10)]
  


############################################################
################## Playoff  Statistics #####################
############################################################

#Sum playoff wins, byes, championships, and appearances
Playoff_Stats <- playoff_data %>%
          group_by(Team) %>%
          summarize(Playoff_Apperances = sum(Playoff_Apperances),
                    Playoff_Wins = sum(Playoff_Wins),
                    Playoff_Losses = sum(Playoff_Losses),
                    Byes = sum(Byes),
                    Championships = sum(Championships),
                    Second_Place = sum(Second_Place),
                    Third_Place = sum(Third_Place),
                    Playoffs_Pts_For = mean(Points.For),
                    Playoff_Pts_Against = mean(Points.Against))

#Merge Regular Season and Playoff Statistics
full_data <- join_all(list(reg_statistics,Playoff_Stats), by = 'Team', type = 'full')
full_data[is.na(full_data)] <- 0

############################################################
################## Calculate Rankings ######################
############################################################

rankings <- mutate(full_data, Power_Points = Wins - Losses + Diff + Total_High + Total_Low + Playoff_Apperances*4 + Byes*2 + Third_Place*6 + Second_Place*12 + Championships*24 )


#reg_final <- arrange(rankings[c(1,23,2,3,4,5:7,9:12)], desc(Inebo_Pts))
playoffs_final <- arrange(rankings[c(1,8:14)],desc(Playoff_Apperances))
rankings_final <- rankings[c(1,18,8,2,3,4,6,7,9,12,14,15,13)] %>% 
                    unite(Record, Wins:Losses, sep = "-") %>%
                    arrange(desc(Power_Points))


############################################################
#####################Save Data#############################
##########################################################
#define lists for user input selection in ui
team_list <- c('Bean','Fred','Jay','Fried','Sean','Trev','KB','Sammy','Rob','Chaz','Cory','Brandon','Tyler','Timmy','Jack')
year_list <- c(2011,2012,2013,2014,2015,2016)

save(playoffs_final, rankings_final, Reg_Data_01, Draft_Act_Proj,  
        team_list, year_list, file = 'data/all.RData')