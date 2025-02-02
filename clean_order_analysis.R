## -----------------------------------------------------------------------------
library(tidyverse)
library(lubridate)
library(janitor)
library(broom)


## -----------------------------------------------------------------------------
orders_original <- read.csv("anonymized_orders.csv")

masterdata_original <- read.csv("anonymized_masterdata.csv")


## -----------------------------------------------------------------------------
#rename so the common column titles match
orders_data <- orders_original %>%
  rename(article_id = ItemNo)

#join the 2 data sets by the common column
data_full <- left_join(orders_data, masterdata_original, by = "article_id")


## -----------------------------------------------------------------------------
#"fix" column names
data_full_clean <- data_full %>%
  clean_names() %>%
  rename(poh_timestamp = po_h_timestamp,
         pol_timestamp = po_l_timestamp
         )
#remove scientific numbers
options(scipen = 999)


## -----------------------------------------------------------------------------
#inspecting variable formats
str(data_full_clean)


## -----------------------------------------------------------------------------
#format date columns as date
data_full_clean <- data_full_clean %>%
  mutate(
    k_order_date = ymd(as.character(k_order_date)),
    #setting the latest month of the year as the date for the currently outstanding orders
    k_date_received = ifelse(k_date_received == "NULL", "2023-12-01", as.character(k_date_received)) %>%
      ymd(),
  )
#check for NAs
any(is.na(data_full_clean$k_order_date))
any(is.na(data_full_clean$k_date_received))


## -----------------------------------------------------------------------------
#calculate the monthly outstanding quantities
outstanding_qty <- data_full_clean %>%
  rowwise() %>%
  do({
    #create a sequence of months from order date to received date
    months_seq <- seq(from = floor_date(.$k_order_date, "month"),
                      to = floor_date(.$k_date_received, "month"),
                      by = "month")
    #calculate outstanding quantity per month
    data.frame(
      month = months_seq,
      article_id = .$article_id,
      outstanding_qty = ifelse(months_seq == floor_date(.$k_date_received, "month"), 
                               0, .$quantity)
    )
  })


## -----------------------------------------------------------------------------
#group outstanding quantity per article and month
outstanding_table <- outstanding_qty %>%
  group_by(article_id, month) %>%
  summarise(outstanding_qty = sum(outstanding_qty), .groups = "drop") %>%
  mutate(month = format(ymd(month), "%Y-%m"))

#result
print(outstanding_table)


## -----------------------------------------------------------------------------
#calculate the number of deleted orders
deleted_orders_count <- data_full_clean %>%
  filter(outstanding_quantity == 0 & quantity_received == 0) %>%
  nrow()

print(deleted_orders_count)


## -----------------------------------------------------------------------------
#indicate the deleted order numbers
deleted_orders <- data_full_clean %>%
  filter(outstanding_quantity == 0 & quantity_received == 0) %>%
  select(order_number, k_requested_receipt_date, k_order_date) %>%
  mutate(
    k_requested_receipt_date = ymd(as.character(k_requested_receipt_date))
  )
  
print(deleted_orders)


## -----------------------------------------------------------------------------
#calculate the amount of orders that contain sellable online products
orders_ecom <- data_full_clean %>%
  filter(sellable_online == TRUE) %>%
  distinct(order_number) %>%
  nrow()

print(orders_ecom)


## -----------------------------------------------------------------------------
#calculate the total value of e-com orders
value_orders_ecom <- data_full_clean %>%
  filter(sellable_online == TRUE) %>%
  summarise(total_ecom_value = sum(amount, na.rm = TRUE))

print(value_orders_ecom)
  


## -----------------------------------------------------------------------------
#calculate the e-com orders value out of the total value
total_order_value <- data_full_clean %>%
  summarise(total_value = sum(amount, na.rm = TRUE))

print(total_order_value)

#create the categories
values <- data.frame(
  category = c("E-commerce Orders", "Other Orders"),
  value = c(value_orders_ecom$total_ecom_value,
            total_order_value$total_value - value_orders_ecom$total_ecom_value)
)

#visualise
ggplot(values, aes(x = "", y = value, fill = category)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar(theta = "y") +
  labs(title = "E-commerce Orders vs Other Orders",
       fill = "Order Type") +
  theme_void()



## -----------------------------------------------------------------------------
order_fulfillment <- data_full_clean %>%
  #convert relevant columns to date format
  mutate(
    k_date_received = as.Date(k_date_received, format = "%Y%m%d"),
    k_expected_receipt_date = as.Date(k_expected_receipt_date, format = "%Y%m%d"),
    
    #delivery difference in days
    delivery_difference = as.numeric(k_date_received - k_expected_receipt_date)
  ) %>%
#remove NAs since they were only 39 out of 1000 observations
filter(!is.na(k_date_received) & !is.na(k_expected_receipt_date)) %>%
  mutate(
    #indicate delivery status
    delivery_status = case_when(
      delivery_difference < 0 ~ "Early",
      delivery_difference == 0 ~ "On Time",
      delivery_difference > 0 ~ "Delayed"
    )
  )

#summarise delivery status
delivery_stats <- order_fulfillment %>%
  #determine the order they appear
  mutate(delivery_status = factor(delivery_status, levels = c("Early", "On Time", "Delayed"))) %>%
  group_by(delivery_status) %>%
  summarise(
    count = n(),
    percentage = round(n() / nrow(order_fulfillment) * 100, 2)
  )

print(delivery_stats)

#visualise
ggplot(delivery_stats, aes(x = delivery_status, y = percentage, fill = delivery_status)) +
  geom_bar(stat = "identity", width = 0.7) +
  geom_text(aes(label = paste0(percentage, "%")), 
            vjust = -0.5, 
            size = 4) + 
  labs(
    title = "Order Receipt",
    x = "Status",
    y = "Percentage (%)",
    fill = "Status"
  ) +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) +  
  theme_minimal()



