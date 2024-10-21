library(dplyr)
library(httr)
library(jsonlite)
library(lubridate)
library(stringr)

number_of_months = 6
today = Sys.Date()
five_months_ago = today %m-% months(5)
end_date_input = format(five_months_ago, "%Y-%m")
start_date = five_months_ago %m-% months(number_of_months-1)
start_date_input = format(start_date, "%Y-%m")

#Enter destination country ID here
destination_country_id = 1880251

{
    # prompt for origin file
    if(exists("origin_filepath")){
        rm("origin_filepath")
    }
    
    readline(prompt = "Press Enter/Return to start selecting the outflow csv file to use for getting destinationLocationIds to each call API for inflows and outflows: ")
    origin_filepath = file.choose()
    cat(paste0('You have selected "', origin_filepath,'".\n\n'))
    
    # check whether the selected file contains destinationLocationId column
    origin_df <- read.csv(origin_filepath)
    
    cat("Checking whether the selected file contains destinationLocationId column.\n\n")
    
    if(sum(names(origin_df) == "destinationLocationId") == 0){
        stop(paste0('destinationLocationId column not found in "', origin_filepath,'".\n\n'))
    }

    
    # prompt for output folder to use so that will not re-do for any 
    # output files that are already generated
    if(exists("output_dir")){
        rm("output_dir")
    }
    
    readline(prompt = "Press Enter/Return to start selecting the folder to use for download result file to from API call. Click Save to confirm selection: ")
    output_dir = dirname(file.choose(new=TRUE))
    cat(paste0('You have selected "', output_dir,'".\n\n'))
    
    
    # use the selected file path to generate transit hub file path
    if(exists("transit_hub_filepath")){
        rm("transit_hub_filepath")
    }
    
    transit_hub_filepath = file.path(output_dir, "transit_hubs.csv")
    
    # prompt for API key
    api_key = readline(prompt = "Enter your API key: ")
    
    # create a transit hub dataframe
    origin_country_id <- origin_df$originCountryId[1]
    originCountryName <- origin_df$originCountryName[1]
    
    transit_hub_df <- 
        origin_df %>%
        select(locationId=destinationLocationId, locationName=destinationLocationName, 
               locationType=destinationLocationType) %>%
        filter(!locationId %in% c(origin_country_id, destination_country_id)) %>% # exclude Destination and origin country id
        distinct() %>%
        arrange(locationName)
        
    
    # create a function to be used for calling API for inflows and outflows
    call_api <- function(origin_country_location_id, destination_country_location_id){
        
        # generate output file name
        output_filename = ""
        if(origin_country_location_id == "" & destination_country_location_id != ""){
            output_filename = paste0(start_date_input, "_to_", end_date_input, "_location_id_", destination_country_location_id, "_inflows.csv")
        } else if(origin_country_location_id != "" & destination_country_location_id == ""){
            output_filename = paste0(start_date_input, "_to_", end_date_input, "_location_id_", origin_country_location_id, "_outflows.csv")
        }
        
        output_filepath = file.path(output_dir, output_filename)
        
        # if result file already downloaded, then skip
        if (file.exists(output_filepath)){
            cat(paste0('Result file "', output_filepath,'" already downloaded. Skip API call.\n\n'))
        } else{
            
            # call API
            api_url = paste0("https://developer.bluedot.global/travel/air/?originLocationIds=", origin_country_location_id,"&destinationLocationIds=", destination_country_location_id,"&originAggregationType=6&destinationAggregationType=6&startDate=", 
                             start_date_input, "&endDate=", end_date_input, "&includeCsv=true&api-version=v1")
            
            cat(paste0(format(Sys.time(), "%H:%M:%S"), ' - Calling API "', api_url,'"\n\n'))
            
            response = GET(api_url, add_headers("Ocp-Apim-Subscription-Key" = api_key, "Cache-Control" = "no-cache"))
            data = fromJSON(rawToChar(response$content))
            
            if(response$status_code == 401){
                stop(data$message)
            } else if(response$status_code == 400){
                stop(data$error)
            }
            
            # download result
            csvDownloadUrl = data$metadata$csvDownloadUrl
            
            cat(paste0(format(Sys.time(), "%H:%M:%S"), ' - Downloading result from URL "', csvDownloadUrl,'".\n\n'))
            download.file(url=csvDownloadUrl, destfile=output_filepath, method="auto")
            
            cat(paste0(format(Sys.time(), "%H:%M:%S"), ' - Result downloaded to "', output_filepath,'".\n\n'))
        }
        
        return(output_filepath)
    }
    
    transit_hub_df$average_monthly_totalPassengerVolume_inflows = 0
    transit_hub_df$average_monthly_totalPassengerVolume_outflows = 0
    transit_hub_df$originCountryId = origin_country_id
    transit_hub_df$originCountryName = originCountryName
    transit_hub_df$average_monthly_totalPassengerVolume_from_origin = 0
    transit_hub_df$proportionFromOrigin = 0.0
    transit_hub_df$DestinationCountryId = destination_country_id
    transit_hub_df$average_monthly_totalPassengerVolume_to_Destination = 0
    transit_hub_df$proportionToDestination = 0.0
    
    # loop through the locationId to do API calls for inflows, do API calls for outflows
    for(i in 1:nrow(transit_hub_df)){
        
        # print progress
        cat(paste0("Progress: ", i, " of ", nrow(transit_hub_df)," locations.\n\n"))
        
        locationId = as.character(transit_hub_df[i , "locationId"])
        
        # API call for inflows to locationId 
        cat(paste0(format(Sys.time(), "%H:%M:%S"), " - Get inflows to locationId ", locationId, ".\n\n"))
        origin_country_location_id = ""
        destination_country_location_id = locationId
        output_filepath = call_api(origin_country_location_id, destination_country_location_id)
        
        # get totalPassengerVolume for inflows
        cat(paste0(format(Sys.time(), "%H:%M:%S"), " - Get inflows totalPassengerVolume\n\n"))
        inflows_df <- read.csv(output_filepath)
        
        # exclude rows where the originLocationId is the same as destinationLocationId
        inflows_df <- inflows_df %>% filter(originLocationId != destinationLocationId)
        
        totalPassengerVolume_total = sum(inflows_df$totalPassengerVolume)
        average_monthly_totalPassengerVolume_inflows = totalPassengerVolume_total / number_of_months
        transit_hub_df[i , "average_monthly_totalPassengerVolume_inflows"] <- average_monthly_totalPassengerVolume_inflows
        totalPassengerVolume_from_origin <-
            inflows_df %>%
            filter(originCountryId == origin_country_id) %>%
            summarise(totalPassengerVolume=sum(totalPassengerVolume)) %>%
            pull(totalPassengerVolume)
        average_monthly_totalPassengerVolume_from_origin = totalPassengerVolume_from_origin / number_of_months
        transit_hub_df[i , "average_monthly_totalPassengerVolume_from_origin"] <- average_monthly_totalPassengerVolume_from_origin
        transit_hub_df[i , "proportionFromOrigin"] <- average_monthly_totalPassengerVolume_from_origin / average_monthly_totalPassengerVolume_inflows
        
        # API call for locationId outflows
        cat(paste0(format(Sys.time(), "%H:%M:%S"), " - Get locationId ", locationId, " outflows.\n\n"))
        origin_country_location_id = locationId
        destination_country_location_id = ""
        output_filepath = call_api(origin_country_location_id, destination_country_location_id)
        
        # get totalPassengerVolume for outflows
        cat(paste0(format(Sys.time(), "%H:%M:%S"), " - Get outflows totalPassengerVolume.\n\n"))
        outflows_df <- read.csv(output_filepath)
        
        # exclude rows where the originLocationId is the same as destinationLocationId
        outflows_df <- outflows_df %>% filter(originLocationId != destinationLocationId)
        
        totalPassengerVolume_total = sum(outflows_df$totalPassengerVolume)
        average_monthly_totalPassengerVolume_outflows <- totalPassengerVolume_total / number_of_months
        transit_hub_df[i , "average_monthly_totalPassengerVolume_outflows"] <- average_monthly_totalPassengerVolume_outflows
        totalPassengerVolume_to_Destination <-
            outflows_df %>%
            filter(destinationCountryId == destination_country_id) %>%
            summarise(totalPassengerVolume=sum(totalPassengerVolume)) %>%
            pull(totalPassengerVolume)
        average_monthly_totalPassengerVolume_to_Destination = totalPassengerVolume_to_Destination / number_of_months
        transit_hub_df[i , "average_monthly_totalPassengerVolume_to_Destination"] <- average_monthly_totalPassengerVolume_to_Destination
        transit_hub_df[i , "proportionToDestination"] <- average_monthly_totalPassengerVolume_to_Destination / average_monthly_totalPassengerVolume_outflows
    }
    
    write.csv(transit_hub_df, transit_hub_filepath, row.names = FALSE)
    cat(paste0(format(Sys.time(), "%H:%M:%S"), ' - Output inflows/outflows summary info into "', transit_hub_filepath, '".\n\n'))
    
    cat(paste0(format(Sys.time(), "%H:%M:%S"), ' - Completed.\n\n'))
}
