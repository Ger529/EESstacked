# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Title: Script for Evaluating Synthetic Variables Estimation (EES 2019 Voter Study, Bulgarian Sample) 
# Author: G.Carteny
# last update: 2022-05-04
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Country-spec workflow # ==============================================================================

cntry = 'BG'

EES2019_bg <- EES2019 %>% filter(countryshort==cntry)
EES2019_stckd_bg <- EES2019_stckd %>% filter(countryshort==cntry)
EES2019_cdbk_bg <- EES2019_cdbk %>% filter(countryshort==cntry)

rm(cntry)

# Generic dichotomous variables estimation # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

EES2019_bg_stack <- 
  cbind(EES2019_stckd_bg,  
        lapply(data = EES2019_stckd_bg, 
               X = list('Q2', 'Q7', 'Q9_rec', 'Q25_rec'),
               stack_var = 'party',
               FUN = gendic.fun) %>% 
          do.call('cbind',.)) %>% 
  as_tibble()

# Generic distance/proximity variables estimation # - - - - - - - - - - - - - - - - - - - - - - - - - - 

EES2019_bg_stack %<>%
  cbind(.,
        lapply(data = EES2019_bg,
               cdbk = EES2019_cdbk_bg,
               stack = EES2019_bg_stack,
               crit = 'average',
               rescale = T,
               check = F,
               keep_id = F,
               X = list('Q10','Q11','Q23'),
               FUN = gendis.fun) %>% 
          do.call('cbind',.)) %>% 
  as_tibble()

# Syntvars evaluation: Functions, variables and data frames # ==========================================

# Source auxiliary functions # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

source(here('Scripts', 'synteval', 'Synteval_auxfuns.R'))

# Country-specific data frames # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

csdf_lst <- list('std'  = EES2019_bg,
                 'cdbk' = EES2019_cdbk_bg,
                 'SDM'  = EES2019_bg_stack)


# Synthetic variables estimation variables # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

syntvars_vrbls <- list('dep'   = list('OLS'     = 'Q10_gen', 
                                      'logit'   = 'Q7_gen'),
                       'indep' = list('ctgrcl' = c('D3_rec', 'D8_rec',  'D5_rec', 'EDU_rec', 
                                                   'D1_rec', 'D7_rec'),
                                      'cntns'  =  c('D4_age', 'D10_rec')))


# Synthetic variables estimation data frames # - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


regdf_lst  <- list('OLS'   = regdf.auxfun(data        = csdf_lst$SDM,
                                          depvar      = syntvars_vrbls$dep$OLS,
                                          cat.indvar  = syntvars_vrbls$indep$ctgrcl, 
                                          cont.indvar = syntvars_vrbls$indep$cntns),
                   'logit' = regdf.auxfun(data        = csdf_lst$SDM,
                                          depvar      = syntvars_vrbls$dep$logit,
                                          cat.indvar  = syntvars_vrbls$indep$ctgrcl, 
                                          cont.indvar = syntvars_vrbls$indep$cntns))


# Relevant parties data frame # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

relprty_df <- 
  tibble('depvar'    = 
           lapply(1:length(regdf_lst$OLS), function(x){names(regdf_lst$OLS[[x]]) %>% .[2]}) %>% 
           unlist,
         'partycode' =
           lapply(1:length(regdf_lst$OLS), function(x){names(regdf_lst$OLS[[x]]) %>% .[2]}) %>% 
           unlist %>% 
           gsub('stack_','',.) %>% 
           as.numeric)  

relprty_df %<>% 
  mutate('partyname_eng' = 
           csdf_lst$cdbk %>% 
           dplyr::select(partyname_eng, Q7) %>% 
           filter(Q7 %in% relprty_df[['partycode']]) %>% 
           .[['partyname_eng']])



# Syntvars evaluation: Null and full regression models # ===============================================

set.seed(123)

fullmod_lst <- list('OLS'   = gensyn.fun(data        = csdf_lst$SDM,
                                         depvar      = syntvars_vrbls$dep$OLS,
                                         cat.indvar  = syntvars_vrbls$indep$ctgrcl, 
                                         cont.indvar = syntvars_vrbls$indep$cntns,
                                         yhat.name   = 'socdem_synt',
                                         regsum      = T),
                    'logit' = gensyn.fun(data        = csdf_lst$SDM,
                                         depvar      = syntvars_vrbls$dep$logit,
                                         cat.indvar  = syntvars_vrbls$indep$ctgrcl, 
                                         cont.indvar = syntvars_vrbls$indep$cntns,
                                         yhat.name   = 'socdem_synt',
                                         regsum      = T))

nullmod_lst <- list('OLS'   = lapply(X = regdf_lst$OLS,   regmod = 'OLS',   null_mod.auxfun),
                    'logit' = lapply(X = regdf_lst$logit, regmod = 'logit', null_mod.auxfun))


# fullmod_lst$OLS %>% lapply(.,summary)
# fullmod_lst$logit %>% lapply(.,summary)  

# Syntvars evaluation: OLS models summary # ============================================================

# stargazer::stargazer(fullmod_lst$OLS, type = 'text',
#                      column.labels = as.character(relprty_df$Q7),
#                      dep.var.labels = 'PTV',
#                      star.cutoffs = c(0.05, 0.01, 0.001),
#                      omit.stat=c("f", "ser"),
#                      header = F,
#                      style = 'ajps')

# Syntvars evaluation: logit models summary # ==========================================================

# stargazer::stargazer(fullmod_lst$logit, type = 'text',
#                      column.labels = as.character(relprty_df$Q7),
#                      dep.var.labels = 'Vote choice',
#                      star.cutoffs = c(0.05, 0.01, 0.001),
#                      omit.stat=c("f", "ser"),
#                      header = F,
#                      style = 'ajps')
# 

# Syntvars evaluation: OLS models fit stats # ==========================================================

# RMSE and Rsq # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


ols_df <- 
  tibble(
    'depvar'  = lapply(1:length(regdf_lst$OLS), 
                       function(x){
                         names(regdf_lst$OLS[[x]]) %>% .[2]
                       }) %>% unlist,
    'model'   = rep('full',length(regdf_lst$OLS)),
    'Rsq'     = lapply(1:length(fullmod_lst$OLS),
                       function(x) {
                         fullmod_lst$OLS[[x]] %>% summary %>% .$r.squared %>% round(., 3)
                       }) %>% unlist,
    'Adj_Rsq' = lapply(1:length(fullmod_lst$OLS),
                       function(x) {
                         fullmod_lst$OLS[[x]] %>% summary %>% .$adj.r.squared %>% round(., 3)
                       }) %>% unlist,
    'AIC'     = lapply(1:length(fullmod_lst$OLS),
                       function(x) {
                         fullmod_lst$OLS[[x]] %>% AIC
                       }) %>% unlist) %>% 
  rbind(.,
        tibble(
          'depvar'  = lapply(1:length(regdf_lst$OLS), 
                             function(x){
                               names(regdf_lst$OLS[[x]]) %>% .[2]
                             }) %>% unlist,
          'model'   = rep('null',length(regdf_lst$OLS)),
          'Rsq'     = lapply(1:length(nullmod_lst$OLS),
                             function(x) {
                               nullmod_lst$OLS[[x]] %>% summary %>% .$r.squared %>% round(., 3)
                             }) %>% unlist,
          'Adj_Rsq' = lapply(1:length(nullmod_lst$OLS),
                             function(x) {
                               nullmod_lst$OLS[[x]] %>% summary %>% .$adj.r.squared %>% round(., 3)
                             }) %>% unlist,
          'AIC'     = lapply(1:length(fullmod_lst$OLS),
                             function(x) {
                               nullmod_lst$OLS[[x]] %>% AIC
                             }) %>% unlist))

ols_df %<>% 
  left_join(., relprty_df, by='depvar') %>% 
  dplyr::select(depvar, partycode, partyname_eng, model,
                Rsq, Adj_Rsq, AIC)



# Syntvars evaluation: logit models fit stats # ========================================================


logit_df <- 
  tibble(
    'depvar'     = lapply(1:length(regdf_lst$logit), 
                          function(x){
                            names(regdf_lst$OLS[[x]]) %>% .[2]
                          }) %>% unlist,
    'model'      = rep('full',length(regdf_lst$logit)),
    'Ps_Rsq'     = lapply(1:length(fullmod_lst$logit),
                          function(x){
                            DescTools::PseudoR2(fullmod_lst$logit[[x]], which = 'McFadden')
                          }) %>% unlist,
    'Adj_Ps_Rsq' = lapply(1:length(fullmod_lst$logit),
                          function(x){
                            DescTools::PseudoR2(fullmod_lst$logit[[x]], which = 'McFaddenAdj')
                          }) %>% unlist,
    'AIC'        = lapply(1:length(fullmod_lst$logit),
                          function(x) {
                            fullmod_lst$logit[[x]] %>% AIC
                          }) %>% unlist
  ) %>% 
  rbind(.,
        tibble(
          'depvar'     = lapply(1:length(regdf_lst$logit), 
                                function(x){
                                  names(regdf_lst$OLS[[x]]) %>% .[2]
                                }) %>% unlist,
          'model'      = rep('null',length(regdf_lst$logit)),
          'Ps_Rsq'     = lapply(1:length(nullmod_lst$logit),
                                function(x){
                                  DescTools::PseudoR2(nullmod_lst$logit[[x]], which = 'McFadden')
                                }) %>% unlist,
          'Adj_Ps_Rsq' = lapply(1:length(nullmod_lst$logit),
                                function(x){
                                  DescTools::PseudoR2(nullmod_lst$logit[[x]], which = 'McFaddenAdj')
                                }) %>% unlist,
          'AIC'        = lapply(1:length(fullmod_lst$logit),
                                function(x) {
                                  nullmod_lst$logit[[x]] %>% AIC
                                }) %>% unlist
        ))


logit_df %<>% 
  left_join(., relprty_df, by='depvar') %>% 
  dplyr::select(depvar, partycode, partyname_eng, model,
                Ps_Rsq, Adj_Ps_Rsq, AIC)

# Full models evaluation # =============================================================================

# logit models 2, 3, 6, and 7 are affected by inflated SE of some predictors, more specifically: 
# Model 2: D8_rec
# Model 3: D7_rec
# Model 6: EDU_rec
# Model 7: D7_rec and D8_rec

# All model constant terms are affected (inflated SE), except Model 3.



# Syntvars evaluation: evaluating the source of misfit # ===============================================

tabs <- list()

# Model 2 # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

mdl  <- 2
df   <- regdf_lst$logit[[mdl]]
cols <- c('D8_rec')

tabs[[1]] <- lapply(data=df, y='stack_302', na=T, X = cols, FUN = tab.auxfun)
# lapply(tabs, head)

# No respondents from rural areas voted 
# for party 302

# Model 3 # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

mdl  <- 3
df   <- regdf_lst$logit[[mdl]]
cols <- c('D7_rec')

tabs[[2]] <- lapply(data=df, y='stack_303', na=T, X = cols, FUN = tab.auxfun)
# lapply(tabs, head)

# No upper middle or upper class Rs voted for party 303 

# Model 6 # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

mdl  <- 6
df   <- regdf_lst$logit[[mdl]]
cols <- c('EDU_rec')

tabs[[3]] <- lapply(data=df, y='stack_306', na=T, X = cols, FUN = tab.auxfun)
# lapply(tabs, head)


# No upper Rs with low education voted for party 3036

# Model 7 # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

mdl  <- 7
df   <- regdf_lst$logit[[mdl]]
cols <- c('D7_rec','D8_rec')

tabs[[4]] <- lapply(data=df, y='stack_307', na=T, X = cols, FUN = tab.auxfun)
# lapply(tabs, head)

# No Rs with upper middle/upper social class or low educated Rs voted for party 307

tabs %<>% unlist(recursive = F)

# Syntvars evaluation: LR TEST for partial logit models # ==============================================

anova_lst <- list()
partmod_lst <- list()

# Model 9 (2 for logit list) # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
mdl <- 2
x <- regdf_lst$logit[[mdl]] %>% na.omit %>% dplyr::select(-c(D8_rec))
y    <- names(x)[startsWith(names(x), 'stack')]
xs   <- names(x)[3:length(x)]
frml <- paste(y, paste0(xs, collapse = ' + '), sep = " ~ ") %>% as.formula

partmod_lst[[1]] <- glm(data = x, formula = frml, family = binomial)

anova_lst[[1]] <- anova(partmod_lst[[1]], fullmod_lst$logit[[mdl]], test='Chisq')

# H0 rejected at p<.05

# Model 10 (3 for logit list) # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mdl <- 3
x <- regdf_lst$logit[[mdl]] %>% na.omit %>% dplyr::select(-c(D7_rec))
y    <- names(x)[startsWith(names(x), 'stack')]
xs   <- names(x)[3:length(x)]
frml <- paste(y, paste0(xs, collapse = ' + '), sep = " ~ ") %>% as.formula

partmod_lst[[2]] <- glm(data = x, formula = frml, family = binomial)

anova_lst[[2]] <- anova(partmod_lst[[2]], fullmod_lst$logit[[mdl]], test='Chisq')

# H0 cannot be rejected 

# Model 13 (6 for logit list) # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mdl <- 6
x <- regdf_lst$logit[[mdl]] %>% na.omit %>% dplyr::select(-c(EDU_rec))
y    <- names(x)[startsWith(names(x), 'stack')]
xs   <- names(x)[3:length(x)]
frml <- paste(y, paste0(xs, collapse = ' + '), sep = " ~ ") %>% as.formula

partmod_lst[[3]] <- glm(data = x, formula = frml, family = binomial)

anova_lst[[3]] <- anova(partmod_lst[[3]], fullmod_lst$logit[[mdl]], test='Chisq')
# H0 cannot be rejected 

# Model 13 (7 for logit list) # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mdl <- 7
x <- regdf_lst$logit[[mdl]] %>% na.omit %>% dplyr::select(-c(D7_rec, D8_rec))
y    <- names(x)[startsWith(names(x), 'stack')]
xs   <- names(x)[3:length(x)]
frml <- paste(y, paste0(xs, collapse = ' + '), sep = " ~ ") %>% as.formula

partmod_lst[[4]] <- glm(data = x, formula = frml, family = binomial)

anova_lst[[4]] <- anova(partmod_lst[[4]], fullmod_lst$logit[[mdl]], test='Chisq')
# H0 cannot be rejected 

# LR test evaluation # =================================================================================

# H0 rejected for model 3,6,7 cannot be rejected. 
# For model 2 H0 rejected with p<.05. 

# Model 3: D7_rec
# Model 6: EDU_rec
# Model 7: D7_rec and D8_rec




# AIC data frames # ====================================================================================

# fullmod_lst$logit[c(mdls)] <- partmod_lst[c(mdls)]

finalmod_lst <- list()
finalmod_lst[['OLS']] <- fullmod_lst[['OLS']]
finalmod_lst[['logit']] <- fullmod_lst[['logit']]

finalmod_lst[['logit']][[1]] <- fullmod_lst[['logit']][[1]]
finalmod_lst[['logit']][[2]] <- fullmod_lst[['logit']][[2]]
finalmod_lst[['logit']][[3]] <- partmod_lst[[1]]
finalmod_lst[['logit']][[4]] <- fullmod_lst[['logit']][[3]]
finalmod_lst[['logit']][[5]] <- partmod_lst[[2]]
finalmod_lst[['logit']][[6]] <- fullmod_lst[['logit']][[4]]
finalmod_lst[['logit']][[7]] <- fullmod_lst[['logit']][[5]]
finalmod_lst[['logit']][[8]] <- fullmod_lst[['logit']][[6]]
finalmod_lst[['logit']][[9]] <- partmod_lst[[3]]
finalmod_lst[['logit']][[10]] <- fullmod_lst[['logit']][[7]]
finalmod_lst[['logit']][[11]] <- partmod_lst[[4]]


# partial logit models fit # ===========================================================================

parlogit_df <- 
  tibble(
    'depvar'     = lapply(c(3,6,7), 
                          function(x){
                            names(regdf_lst$logit[[x]]) %>% .[2]
                          }) %>% unlist,
    'model'      = rep('full',(length(partmod_lst)-1)),
    'Ps_Rsq'     = lapply(1:(length(partmod_lst)-1),
                          function(x){
                            DescTools::PseudoR2(partmod_lst[[x]], which = 'McFadden')
                          }) %>% unlist,
    'Adj_Ps_Rsq' = lapply(1:(length(partmod_lst)-1),
                          function(x){
                            DescTools::PseudoR2(partmod_lst[[x]], which = 'McFaddenAdj')
                          }) %>% unlist,
    'AIC'        = lapply(1:(length(partmod_lst)-1),
                          function(x) {
                            partmod_lst[[x]] %>% AIC
                          }) %>% unlist
  ) %>% 
  rbind(.,
        tibble(
          'depvar'     = lapply(c(3,6,7), 
                                function(x){
                                  names(regdf_lst$logit[[x]]) %>% .[2]
                                }) %>% unlist,
          'model'      = rep('null',length(partmod_lst)-1),
          'Ps_Rsq'     = lapply(c(3,6,7),
                                function(x){
                                  DescTools::PseudoR2(nullmod_lst$logit[[x]], which = 'McFadden')
                                }) %>% unlist,
          'Adj_Ps_Rsq' = lapply(c(3,6,7),
                                function(x){
                                  DescTools::PseudoR2(nullmod_lst$logit[[x]], which = 'McFaddenAdj')
                                }) %>% unlist,
          'AIC'        = lapply(c(3,6,7),
                                function(x) {
                                  nullmod_lst$logit[[x]] %>% AIC
                                }) %>% unlist
        ))


parlogit_df %<>%
  left_join(., relprty_df, by='depvar') %>% 
  dplyr::select(depvar, partycode, partyname_eng, model,
                Ps_Rsq, Adj_Ps_Rsq, AIC)




# AIC dataframes # =====================================================================================

# OLS AIC df 

ols_aic <- 
  ols_df %>%
  pivot_wider(id_cols = c('depvar', 'partycode', 'partyname_eng'), values_from = 'AIC',
              names_from = 'model') %>%
  mutate(diff = full - null) %>%
  mutate(across(c('full', 'null', 'diff'), ~round(.,3))) %>%
  dplyr::select(-c(partyname_eng))

# Logit AIC df 

logit_aic <- 
  logit_df %>%
  pivot_wider(id_cols = c('depvar', 'partycode', 'partyname_eng'), values_from = 'AIC',
              names_from = 'model') %>%
  mutate(diff = full - null) %>%
  mutate(across(c('full', 'null', 'diff'), ~round(.,3))) %>%
  dplyr::select(-c(partyname_eng)) %>% 
  rbind(
    ., 
    parlogit_df %>%
      pivot_wider(id_cols = c('depvar', 'partycode', 'partyname_eng'), values_from = 'AIC',
                  names_from = 'model') %>%
      mutate(diff = full - null) %>%
      mutate(across(c('full', 'null', 'diff'), ~round(.,3))) %>%
      dplyr::select(-c(partyname_eng)) %>% 
      mutate(depvar = paste0(depvar, '*'))
    )



# Clean the environment # ==============================================================================

rm(list=ls(pattern='auxfun|regdf|partlogit|fulllogit|nulllogit'))



