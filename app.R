library(dash)
library(dashCoreComponents)
library(dashHtmlComponents)
library(dashBootstrapComponents)
library(ggplot2)
library(plotly)
library(dashTable)
library(tidyverse)
### Added tidyverse
app <- Dash$new(external_stylesheets = dbcThemes$BOOTSTRAP)
server = app$server

df <- read.csv('data/processed/happiness_merge_all.csv')
world_df <- read.csv("https://raw.githubusercontent.com/plotly/datasets/master/2014_world_gdp_with_codes.csv") %>% 
    select(CODE, COUNTRY)

merged_df <- merge(df, world_df, by.x = "Country", by.y= "COUNTRY", all = TRUE)
#names(merged_df)[4] <- "Ladder_score" 
#merged_df$Ladder_score[is.na(merged_df$Ladder_score)] <- 0
merged_df$happiness_rank <- rank(-merged_df[, 4], na.last = "keep", ties.method = 'min' )


names(df)[3] <- "Region"

region_list <- unique(df[, 3])
country_list <- unique(df[, 2])

preferences <- c(
    "Happiness score",
    "Logged GDP per capita",
    "Social support",
    "Healthy life expectancy",
    "Freedom to make life choices",
    "Generosity",
    "Perceptions of corruption",
    "Population (2020)",
    "Density",
    "Land Area",
    "Migrants net",
    "Cost of Living Index",
    "Rent Index",
    "Cost of Living Plus Rent Index",
    "Groceries Index",
    "Restaurant Price Index",
    "Local Purchasing Power Index"
)
region_indicator <- lapply(region_list, function(x) 
    list(label = x, value = x))

preferences_indicator <- lapply(preferences, function(x) 
    list(label = x, value = str_replace_all(x, pattern = " ", replacement = "_")))

country_indicator <- lapply(country_list, function(x) 
    list(label = x, value = x))

# light grey boundaries
l <- list(color = toRGB("grey"), width = 0.5)

# specify map projection/options
g <- list(
    showframe = FALSE,
    showcoastlines = FALSE,
    projection = list(type = 'Mercator')
)

world_fig <- plot_geo(merged_df)
world_fig <- world_fig %>% add_trace(
    z = ~happiness_rank, color = ~happiness_rank, colors = 'Blues',
    text = ~Country, locations = ~CODE, marker = list(line = l)
)
world_fig <- world_fig %>% colorbar(title = 'Happiness World Rank')
world_fig <- world_fig %>% layout(
    title = 'World Happiness Ranking',
    geo = g,
    clickmode = 'event+select'
)


create_error_graph <- function(df = merged_df, region = "Western Europe"){
  region_df <- df %>%
      filter(Regional_indicator == region)
  
  # Happiness rank plot for the selected region
  happiness_rank <- ggplot(region_df) +
      aes(x = Happiness_score,
          y = reorder(Country, Happiness_score),
          text = paste0("Country: ", Country, "\n",
                        "Happiness Score: ", Happiness_score, "\n",
                        "High: ", upperwhisker, "\n",
                        "Low: ", lowerwhisker),
          xmin = lowerwhisker,
          xmax = upperwhisker) +
      geom_point(color = "#0abab5", size = 3) +
      geom_errorbarh(height = 0.2) +
      labs(x = "Happiness Score", y = "")
  happiness_rank <- happiness_rank +
      theme_classic() 
  error <- ggplotly(happiness_rank, tooltip = "text") %>% layout(clickmode = 'event+select')
  return(error)
}

create_bar_graph <- function(df = merged_df, region = "Western Europe"){
  region_df <- df %>%
    filter(Regional_indicator == region)
  # Population density chart for the selected region
  density_chart <- ggplot(region_df) +
    aes(x = Density, 
        y = reorder(Country, Density)) +
    geom_bar(stat = "identity", fill = "#0abab5") +
    scale_x_continuous(expand = expansion(mult = c(0, 0))) +
    labs(x = "Density", y = "")
  density_chart <- density_chart +
    theme_classic()
 
  bar <- ggplotly(density_chart, tooltip = "x") %>% layout(clickmode = 'event+select')
  return(bar)
}


app$layout(
    htmlDiv(list(
        htmlH1(
            id="site_header",
            "Country Happiness Visualization"
        ),
        htmlH5(
            "This app is designed to explore world's happiness
                    scores and the ranking of its related matrix to help
                    user make  country specific decisions.",
            style = list("textAlign" = "center", "color" = "black")
        ),
        htmlBr(),
        htmlDiv(id = "topbar", list(
            htmlDiv(list(
                dbcLabel("Select Region"),
                dccDropdown(
                    id = 'region',
                    value = 'Western Europe',
                    options = region_indicator
                ))
            ),
            htmlDiv(list(
                dbcLabel("Select Preferences"),
                dccDropdown(
                    id = 'preference_name',
                    value = 'Happiness_score',
                    options = preferences_indicator
                ))
            )
        )),
        htmlBr(),
        htmlDiv(id = 'map_div',list(htmlH6("Hover on the worldmap to see happiness score index:", 
               style= list(
                 'textAlign' = 'left',
                 'color' = 'white',
                 'border' = '1px solid #d3d3d3', 
                 'border-radius' = '10px',
                 'background-color' = 'turquoise',
                 'padding-left' = '10px',
                 'padding-top' = '5px',
                 'padding-bottom' = '5px'
               )))),
        htmlBr(),
        htmlBr(),
     
        htmlDiv(id ='data_table', list(
            htmlDiv(list(
                dccGraph(
                    id = 'world_map',
                    figure = world_fig)
            )),
            htmlDiv(id = 'pref_barplot', list(
                htmlDiv(list(
                    dccGraph(
                        id = 'preference_bar_plot',
                    )
                ))
            ))
        )),
        htmlBr(),
        htmlDiv(id = 'country_div',list(htmlH6("Country-to-Country Comparison based on selected preferences", 
                                           style= list(
                                             'textAlign' = 'left',
                                             'color' = 'white',
                                             'border' = '1px solid #d3d3d3', 
                                             'border-radius' = '10px',
                                             'background-color' = 'turquoise',
                                             'padding-left' = '10px',
                                             'padding-top' = '5px',
                                             'padding-bottom' = '5px'
                                           )))),
        htmlBr(),
        htmlBr(),
        htmlDiv(id = 'row_4', list(
            htmlDiv(list(
                dccGraph(
                    id = 'error_plot',
                    figure = create_error_graph()
                )
            )),
            htmlDiv(list(
                dccGraph(
                    id = 'bar_plot',
                    figure = create_bar_graph()
                )
            ))
        )),
        htmlBr(),
        htmlBr(),
        htmlDiv(id = "map_header", list(
          htmlDiv(list(
            dbcLabel("Select Country"),
            dccDropdown(
              id = 'country_name',
              options = country_indicator,
              multi = TRUE
            ))
          )
        )),
        htmlBr(),
        htmlBr(),
        htmlBr(),
        htmlBr(),
        htmlBr(),
        htmlDiv(id = "table_summary",
                list(
          htmlDiv(list(
            dashDataTable(
              id = 'table',
              page_size = 5,
              style_cell=list('textAlign'= 'center'),
              style_header= list( 'border' =  '1px solid black' )
            )
          ))
        )
        ),
        htmlBr(),
        htmlBr(),
        htmlBr(),
        htmlBr(),
        htmlBr(),
        htmlBr(),
        htmlBr(),
        htmlBr(),
        htmlBr()
        
                
    ))
)

app$callback(
    output=list(id='country_name', property='options'),
    params=list(input(id='region', property='value')),
    function(input_value) {
        filtered_df <- df %>% filter(Region == input_value)
        filtered_list <- unique(filtered_df[, 2])
        
        lapply(filtered_list, function(x) list(label = x, value = x))
})


app$callback(
    output=list(id='bar_plot', property='figure'),
    params=list(input(id='region', property = 'value')),
    function(input_value){
        create_bar_graph(df = merged_df, region = input_value)
})

app$callback(
    output=list(id='error_plot', property='figure'),
    params=list(input(id='region', property = 'value')),
    function(input_value){
        create_error_graph(df = merged_df, region = input_value)
})

app$callback(
    output=list(id='preference_bar_plot', property='figure'),
    params=list(input(id='region', property='value'),
                input(id='preference_name', property='value')),
    function(region, column){
      region_df <- df %>% filter(Region == region)
      column_name <- str_replace_all(column, "_"," ")
      bar_plot <- ggplot(region_df) +
        aes(x = !!sym(column),
            fill = Country,
            y = reorder(Country, !!sym(column)),
            text = paste0("Country: ", Country, "\n",
                          str_replace_all(column, "_", " "), ": ", !!sym(column))) +
        geom_bar(stat = 'identity', fill="#0ABAB5") +
                 scale_x_continuous(expand=expansion(mult=c(0,0.5))) +
        xlab(column_name) + 
        ylab("")
    return(ggplotly(bar_plot, tooltip = "text"))
})

###App callback for data
app$callback(
    output = list(id = 'table', property= 'data'),
    params=list(input(id = 'country_name', property ='value')),
    function(input_value = "Canada") {
      country_df <- filter(df, Country %in% input_value) 
      country_df 
})

###App callback for preferences
app$callback(
   output = list(id = 'table', property= 'columns'),
   params=list(input(id = 'preference_name',property ='value')),
   function(preference_value = 'Social support') {
      col<-list( 
        list(id = "Country", name = "Country"),
        list(id = "Region", name = "Region"),
        list(
            id = preference_value,
            name = str_replace_all(preference_value, "_"," ")
        ))
      col
})

app$run_server(host = '0.0.0.0', debug=T) 
