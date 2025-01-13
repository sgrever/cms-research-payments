# 2023 Research Payment Data
# Author: Sara Grever 
# Created: 12/8/24
# Updated: 1/9/25
# Data link: https://openpaymentsdata.cms.gov/dataset/ec9521bf-9d97-4603-814c-f4132d34bc4f#data-table

library(data.table)
library(dplyr)
library(readr)
library(janitor)
library(ggplot2)
library(scales)
library(jsonlite)
library(stringr)
library(sf)
library(rnaturalearth)
library(leaflet)


### import raw

# load
abs_path <- file.path(getwd(), "data", "2023 Open Payments Research.csv")
payments_raw <- data.table::fread(abs_path)


message("Raw payment data imported")

# drop cols + snake case column names
payments <- payments_raw |> 
  clean_names() |> 
  select(payment_date = date_of_payment, 
         payment_amount = total_amount_of_payment_us_dollars,
         name_of_study,
         product_class = indicate_drug_or_biological_or_device_or_medical_supply_1,
         product_category = product_category_or_therapeutic_area_1,
         product_name = name_of_drug_or_biological_or_device_or_medical_supply_1,
         ndc_long = associated_drug_or_biological_ndc_1,
         recipient_state,
         recipient_country,
         teaching_hospital_name, 
         
         # 1-1-25 additions
         covered_recipient_type,
         noncovered_recipient_entity_name,
         covered_recipient_npi,
         covered_recipient_first_name,
         covered_recipient_last_name,
         payee_name = applicable_manufacturer_or_applicable_gpo_making_payment_name
  )

payments$payment_date[1:10] # "01/26/2023"
as.Date("01/26/2023", "%m/%d/%Y") # test

# drop additional cols, convert "" to NA globally
payments <- payments |> 
  mutate(payment_date = as.Date(payment_date, "%m/%d/%Y")) |> 
  mutate(across(where(is.character), ~ na_if(., "")))


### Clean up product names

payments_categorized <- payments |> 
  
  # 1. Set all to lowercase
  mutate(product_cat_short = str_to_lower(product_category)) |> 
  
  # 2. Wipe special characters
  mutate(product_cat_short = str_replace_all(
    product_cat_short, "/", " "
  )) |> 
  mutate(product_cat_short = 
           trimws(str_remove_all(product_cat_short, "[[:punct:]]"))) |>
  
  
  # 3. Consolidate into categories based on phrases 
  mutate(product_cat_short = case_when(
    
    # conserve important phrases
    str_detect(product_cat_short, "knee & ") ~ "knee & hip",
    str_detect(product_cat_short, "critical care") ~ "critical care",
    str_detect(product_cat_short, "clinical trial product") ~ "clinical trial",
    str_detect(product_cat_short, "deep brain") ~ "brain",
    str_detect(product_cat_short, "distal extremities") ~ "extremities",
    str_detect(product_cat_short, "growth hormone") ~ "growth hormone",
    str_detect(product_cat_short, "internal medicine") ~ "internal medicine",
    
    str_detect(product_cat_short, "medical imaging") ~ "imaging",
    str_detect(product_cat_short, "medical device") ~ "medical device",
    str_detect(product_cat_short, "medical supplies") ~ "medical supplies",
    str_detect(product_cat_short, "oral contraceptive") ~ "oral contraceptive",
    str_detect(product_cat_short, "plastic surgery") ~ "plastic surgery",
    str_detect(product_cat_short, "rare disease") ~ "rare diseases",
    
    # if "aortic" or "oncology" is anywhere in description, extract
    str_detect(product_cat_short, "aortic") ~ "aortic",
    str_detect(product_cat_short, "oncology") ~ "oncology",
    
    # otherwise, extract FIRST word
    T ~ str_extract(product_cat_short, "^[[:alpha:]]+"))
  ) |>
  
  # 4. Consolidate based on first word
  mutate(product_cat_short = case_when(
    str_detect(product_cat_short, "(cardio)|(cardia)") ~ "cardiology",
    str_detect(product_cat_short, "(cns)|(central nervo)") ~ "cns",
    str_detect(product_cat_short, "(neuro)|(nerve)") ~ "neurology",
    str_detect(product_cat_short, "gastro") ~ "gastroenterology",
    str_detect(product_cat_short, "immun") ~ "immunology",
    str_detect(product_cat_short, "diagnostic") ~ "diagnostics",
    str_detect(product_cat_short, "vaccine") ~ "vaccines",
    str_detect(product_cat_short, "anesth") ~ "anesthiology",
    str_detect(product_cat_short, "antibio") ~ "antiobiotics",
    str_detect(product_cat_short, "endocrin") ~ "endocrinology",
    str_detect(product_cat_short, "gene") ~ "genetics",
    str_detect(product_cat_short, "infect") ~ "infections",
    str_detect(product_cat_short, "orthop") ~ "orthopedics",
    str_detect(product_cat_short, "(spine)|(spinal)") ~ "spine",
    str_detect(product_cat_short, "transplant") ~ "transplants",
    str_detect(product_cat_short, "(obstetric)|(gyno)|(gyne)|(women)") ~ "womens health",
    str_detect(product_cat_short, "psych") ~ "psychiatry or psychology",
    product_cat_short %in% c("knee", "knees") ~ "knee", # don't override "Knee & Hip"
    T ~ product_cat_short
    
  ))


### State payments map

# top 3 product categories
state_top3 <- payments_categorized |> 
  filter(!is.na(product_cat_short)) |> 
  group_by(recipient_state, product_cat_short) |> 
  summarize(state_cat_sum = sum(payment_amount)) |> 
  arrange(recipient_state, desc(state_cat_sum)) |> 
  ungroup() |> 
  group_by(recipient_state) |> 
  slice(1:3) |> 
  summarise(top_3_categories = paste(product_cat_short, collapse = "; ")) |> 
  mutate(top_3_categories = str_to_upper(top_3_categories)) |> 
  filter(!is.na(recipient_state))


# add full state names for geo join 
payments_states <- tibble(state_abb = state.abb,
                          state_name = state.name) |>
  right_join(payments_ndc, 
             join_by("state_abb" == "recipient_state")) |> 
  group_by(state_name) |> 
  mutate(state_payments = sum(payment_amount)) |>
  select(state_abb, state_name, state_payments) |> 
  left_join(state_top3, 
            join_by("state_abb" == "recipient_state")) |> 
  distinct()

states_geo <- 
  rnaturalearth::ne_states(country = 'United States of America') |> 
  select(name, fips) 

payments_geo <- states_geo |> 
  right_join(payments_states,
             join_by("name" == "state_name"))
st_crs(payments_geo) # ["EPSG",4326] WGS 84


### Export

saveRDS(payments_ndc, "data/payments_clean.rds")
saveRDS(payments_geo, "data/payments_geo.rds")

message("Export complete")
