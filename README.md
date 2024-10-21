Location ID of countries can get from https://www.geonames.org/countries/
1. At the webpage, click on the hyperlink named after the country name (e.g. Singapore). You will be redirected to the webpage on that country.
2. At the webpage of that country, click on the hyperlink named after the country name (at the "country name" field. e.g. Singapore). You will be redirected to another webpage on that country.
3. The Location ID is at the URL (e.g. Location ID 1880251 from the URL https://www.geonames.org/1880251/singapore.html).

**scripts/get_inflows_to_country.R**
* For calling API to get inflow air travel volume to a country within a 6 months period from the start of 10 months ago till the end of 5 months ago (the most recent data available).
* Prompts for your API key.
* Prompts for location ID of country (i.e. destination country location ID).
* Prompts for the folder path to download result file from API call.

**scripts/get_country_outflows.R**
* For calling API to get a country's outflows air travel volume within a 6 months period from the start of 10 months ago till the end of 5 months ago (the most recent data available).
* Prompts for your API key.
* Prompts for location ID of country (i.e. origin country location ID).
* Prompts for the folder path to download result file from API call.

**scripts/get_country_outflows_with_lastStopBeforeEntryCountry.R**
* For calling API to get a country's outflows air travel volume (with last stop before entry country) within a 6 months period from the start of 10 months ago till the end of 5 months ago (the most recent data available).
* Cons for using this instead of get_country_outflows.R is the result does not have nonstopPassengerVolume (i.e. travel volume for passengers with zero stops between their origin and destination) column.
* Prompts for your API key.
* Prompts for location ID of country (i.e. origin country location ID).
* Prompts for the folder path to download result file from API call.

**scripts/get_destinationLocationIds_inflows_and_outflows.R**
* To get a list of countries, showing the proportion of inflow passenger volume from the origin country of interest, and the proportion of outflow passenger volume to Singapore.
* To get from an outflow file the destination countries (excluding Singapore). For each country:
  1. Call API to get country's inflows air travel volume within a 6 months period from the start of 10 months ago till the end of 5 months ago (the most recent data available).
  2. Get average monthly total passenger volume from inflows.
  3. Get average monthly total passenger volume from origin country (i.e. origin country extracted from the selected outflow file).
  4. Get proportion (i.e. a number between 0 and 1) from origin country.
  5. Call API to get country's outflows air travel volume within a 6 months period from the start of 10 months ago till the end of 5 months ago (the most recent data available).
  6. Get average monthly total passenger volume from outflows.
  7. Get average monthly total passenger volume to destination country (Singapore).
  8. Get proportion to destination country (Singapore).
  9. Output as transit_hubs.csv.
* Prompts for the outflow csv file to use for getting destinationLocationIds to each call API for inflows and outflows.
* Prompts for the folder path to download result file from API call (and also to output transit_hubs.csv).
* Prompts for your API key.
  
**scripts/get_from_originLocationId_to_destinationLocationId.R**
* For calling API to get air travel volume from an origin country to a destination country within a 6 months period from the start of 10 months ago till the end of 5 months ago (the most recent data available).
* Prompts for your API key.
* Prompts for origin country location ID.
* Prompts for destination country location ID.
* Prompts for the folder path to download result file from API call.
