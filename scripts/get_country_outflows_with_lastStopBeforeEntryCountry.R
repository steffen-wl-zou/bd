library(httr)
library(jsonlite)
library(lubridate)
library(stringr)

today = Sys.Date()
five_months_ago = today %m-% months(5)
end_date_input = format(five_months_ago, "%Y-%m")
start_date = five_months_ago %m-% months(5)
start_date_input = format(start_date, "%Y-%m")

{
    # prompt for API key
    api_key = readline(prompt = "Enter your API key: ")
    
    # prompt for location id of country
    origin_country_location_id = readline(prompt = "Enter location ID of country: ")
    
    # prompt for output folder to use
    if(exists("output_dir")){
        rm("output_dir")
    }
    
    readline(prompt = "Press Enter/Return to start selecting the folder to use for download result file to from API call. Click Save to confirm selection: ")
    output_dir = dirname(file.choose(new=TRUE))
    cat(paste0('You have selected "', output_dir,'".\n\n'))
    
    # call API
    api_url = paste0("https://developer.bluedot.global/travel/air/international?originLocationIds=", origin_country_location_id, "&destinationLocationIds=&originAggregationType=6&destinationAggregationType=6&startDate=", 
                     start_date_input, "&endDate=", end_date_input, "&includePortOfExit=&includeLastStopBeforeEntry=true&includePortOfEntry=&includeCsv=true&api-version=v1")
    
    cat(paste0('Calling API "', api_url,'"\n\n'))
    
    response = GET(api_url, add_headers("Ocp-Apim-Subscription-Key" = api_key, "Cache-Control" = "no-cache"))
    data = fromJSON(rawToChar(response$content))
    
    if(response$status_code == 401){
        stop(data$message)
    } else if(response$status_code == 400){
        stop(data$error)
    }
    
    # download result
    csvDownloadUrl = data$metadata$csvDownloadUrl

    output_filename = paste0(start_date_input, "_to_", end_date_input, "_location_id_", origin_country_location_id, "_outflows_includeLastStopBeforeEntry.csv")
    output_filepath = file.path(output_dir, output_filename)
    
    cat(paste0('Downloading result from URL "', csvDownloadUrl,'".\n\n'))
    download.file(url=csvDownloadUrl, destfile=output_filepath, method="auto")
    
    cat(paste0('Result downloaded to "', output_filepath,'".\n\n'))
}
