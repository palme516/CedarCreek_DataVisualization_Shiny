# Cedar Creek Data Visualization App


# User interface ---------------------------------

source("cedarcreek_shiny.R")

# Sidebar ----------------------------------------

sidebar <- dashboardSidebar(
    
    sidebarMenu(
        menuItem("Overview", tabName = "overview"),
        menuItem("By Species", tabName = "species"),
        menuItem("Pairwise Comparison", tabName = "pairwise_compare")
    ),
    
    tags$footer(
        p(
            "Maintained by ",
            a(href = 'https://www.meredithspalmer.weebly.com', "Dr. Meredith S. Palmer.")
        ),
        
        align = "left",
        style = "
            position:absolute;
            bottom:0;
            width:100%;
            height:50px; /* Height of the footer */
            color: white;
            padding: 10px;
            background-color: black;
            z-index: 1000;"
    )
)

# Body -------------------------------------------

body <- dashboardBody(
    
    tabItems(
        
        tabItem(
            
            tabName = "overview",
            
            fluidRow(
                box(width = 12,
                    h1("Cedar Creek Camera Traps"),
                    "This dashboard facilitates exploration of the first five seasons of camera trap data (Nov 2017-May 2019) the ", 
                    a(href= 'https://www.cedarcreek.umn.edu/', 'Cedar Creek Ecosystem Science Reserve'), " (East Bethel, MN; lat. 
                    45°25’N, long. 126 93°10’W; 21 km2). These data are from 97 cameras that were deployed in a 0.20-km2 grid and 
                    classified with the help of citizen scientists on ", a(href='www.eyesonwild.com', "`Eyes on the Wild`."), "Data 
                    are generated and maintained by the lab group of Dr. ", a(href= 'https://cbs.umn.edu/isbell-biodiversity-lab/research', "Forest Isbell"),
                    "at the University of Minnesota. For questions relating to accessing data or metadata for collaboration, please 
                    contact ,", a(href = 'mailto:isbell@umn.edu', "Dr. Forest Isbell"), ". For questions relating to the functioning 
                    and use of this app, please contact ", a(href = 'mailto:palme516@umn.edu', 'Dr. Meredith Palmer.'))), 
            
            fluidRow(
                box(width = 12,
                    title = "Camera trap study design",
                    status = "primary",
                    "The camera trap study area covers the entirety of Cedar Creek Ecosystem Science Reserve, a 
                    long-term ecological research station situated in a transitional vegetation zone encompassing
                    prairies, evergreen forests, and leafy woodlands. 27 different species are recorded in the 
                    camera trap images.",
                    br(), 
                    br(),
                    "More camera trap information to come.")), 
            
            fluidRow(
                box(title = "Funding and collaboration",
                    width = 12,
                    status = "primary",
                    "Acknowledgements coming soon."))
        ),
        
# By species -------------------------------------

tabItem(
    
    tabName = "species",
    
    fluidRow(
        box(h2("INDIVIDUAL SPECIES PATTERNS"), width = 12)),
    
    fluidRow(
        box(
            title = "Choose a species",
            selectInput(inputId = "species_select",
                        label = "Select species:",
                        selected = "Squirrel",
                        choices = sort(unique(dat$species))), 
            
           radioButtons(inputId = "juvenile_select", 
                         label = "Select presence/absence of juveniles (optional):",
                         choices = list("All" = 1, "With_Junveniles" = 2, "Without_Juveniles" = 3), 
                         selected = 1), 
            "Select for records with or without juveniles. Default is all images of the species.", 
            br(),
            br(),
            
            checkboxGroupInput(inputId = "behavior_select", 
                               label = "Select performance of behaviors (optional):",
                               choices = c("Eating", "Standing", "Resting", "Moving",
                                           "Interacting")),
            "Select for records of animals performing certain behaviors. Default (unchecked) is all 
            images of the species.",
           br(), 
           br(), 
           
           strong("For deer, selection for antlers/no antlers visible coming soon.")
        ),
        
        box(
            title = "Subset records further (optional)",
            dateRangeInput(inputId = "date_range",
                           label = "Date Range:",
                           start = "2017-11-20",
                           end = "2019-05-15"),
            "Provided here are the first 5 seasons of Cedar Creek camera trap data. If you choose 
            dates outside of this range, it will generate an error.",
            br(),
            br(),
            
            numericInput(inputId = "independent_min",
                         label = "Set quiet period for independent detections (minutes):",
                         value = 15,
                         min = 0,
                         max = 1440),
            "Records of a given species will only be counted as one detection if they occur within
                    the set quiet period. This setting addresses bias caused by a single animal sitting in 
                    front of a camera for a long period of time and repeatedly triggering the camera. 
                    The default setting is 15 minutes."
        )),
    
    fluidRow(
        box(title = "Relative Activity Index (RAI) across camera grid",
            collapsible = TRUE,
            
            selectInput(inputId = "rai_select",
                        label = "Select response variable:",
                        selected = "Detections",
                        choices = list("Detections" = 1, "Total_Counts" = 2)), 
            
            leafletOutput(outputId = "rai_map"),
            "Detections or total animals seen per trap-night at each camera. Note that greyed-out squares
            were not operable during the selected period. Switch to log scale for easier viewing (small 
            value of 0.001 added to all RAI to address issue with 0s).",
            br(), 
            br(), 
            radioButtons(inputId = "log_select_map", 
                         label = "Select scale:",
                         choices = list("RAI" = 1, "log(RAI)" = 2), 
                         selected = 1)),
        
        box(title = "Basic Occupancy Modeling (OM) across camera grid",
            collapsible = TRUE,
            
            selectInput(inputId = "om_cov",
                        label = "Select occupancy covariate:",
                        selected = "Biome",
                        choices = c("Biome", "Habitat_Class", "Plant_Community", "LULC_Info")), 
            
            leafletOutput(outputId = "om_map"),
            "Occupancy modeling accounts for imperfect detection of camera trap method. In this analysis, 
            there is only ONE covariate on occupancy and NO covariates ondetection probability. More 
            in-depth analyses examining how habitat features affect occupancy and detection are strongly 
            recommended. Note: these calculations may fail if date range selected is too large. Consider
            what makes a `closed` season when selecting date range.", 
            br(), 
            br(),
            
            radioButtons(inputId = "detection_window",
                        label = "Select length of detection window:",
                        selected = 2,
                        choices = list("Day" = 1, "Week" = 2))
        )),
    
    fluidRow(
        box(title = "Environmental covariates of Relative Activity Index",
            collapsible = TRUE,
            selectInput(inputId = "metadata_select",
                        label = "Choose an environmental covariate:",
                        choices = c("Biome"), ##too many options to nicely render
                        selected = "Biome"), 
            
            plotlyOutput(outputId = "rai_metadata")), 
        
        box(title = "Diel activity pattern",
            collapsible = TRUE,
            "Kernel density distribution of the timing of the detections across all cameras across the 24-hour
            period. All times are scaled to solar time based on the date of the detection. NOTE: these values 
            have been corrected for daylight savings time.",
            plotOutput(outputId = "activity_plot"))
    ),
    
    fluidRow(
        
        box(title = "RAI over time: months",
            collapsible = TRUE,
            "Monthly RAI for the selected time period, calculated for the entire grid network (total
                    detections per total trap-nights across all operating cameras). An RAI of 0 indicates that 
                    there were no detections during that month.",
            plotlyOutput(outputId = "monthly_rai_hist"))
        
       ##put years here soon
        
        )),
    
# Species comparison -----------------------------

        tabItem(
            
            tabName = "pairwise_compare",
            
            fluidRow(
                box(h2("COMPARISON TOOL"), width = 12,
                    "This page enables the comparison of two data subsets. It can be used to compare 
                    patterns for a given species across seasons or behaviors, or to compare two species.")),
            
            fluidRow(
                box(
                    title = "Data Subset A:",
                    
                    selectInput(inputId = "species_select_A",
                                label = "Choose species for dataset A:",
                                selected = "Squirrel",
                                choices = sort(unique(dat$species))),
                    
                    dateRangeInput(inputId = "date_range_A",
                                   label = "Date Range:",
                                   start = "2017-11-20",
                                   end = "2019-05-15"),
                    
                    numericInput(inputId = "independent_min_A",
                                 label = "Set quiet period for independent detections (minutes):",
                                 value = 15,
                                 min = 0,
                                 max = 1440)),
                
                box(
                    title = "Data Subset B:",
                    
                    selectInput(inputId = "species_select_B",
                                label = "Choose species for dataset B:",
                                selected = "Black Bear",
                                choices = sort(unique(dat$species))),
                    
                    dateRangeInput(inputId = "date_range_B",
                                   label = "Date Range:",
                                   start = "2017-11-20",
                                   end = "2019-05-15"),
                    
                    numericInput(inputId = "independent_min_B",
                                 label = "Set quiet period for independent detections (minutes):",
                                 value = 15,
                                 min = 0,
                                 max = 1440))),
            
            fluidRow(
                box(title = "Diel overlap",
                    collapsible = TRUE,
                    textOutput(outputId = "activity_overlap"),
                    plotOutput(outputId = "activity_plot_compare")
                ),
                
                box(title = "Side-by-side trend over time",
                    collapsible = TRUE,
                    plotlyOutput(outputId = "rai_monthly_AB"))),
            
            fluidRow(
                box(title = "Plot of RAI A vs B",
                    collapsible = TRUE,
                    plotlyOutput(outputId = "rai_AB"),
                    "Option to switch to log scale for easier viewing (small value of 0.001 added 
                    to all RAI to address issue with 0s).",
                    radioButtons(inputId = "log_select", label = "",
                                 choices = list("RAI" = 1, "log(RAI)" = 2), 
                                 selected = 1))) 
 )))

# Dashboard --------------------------------------

dashboardPage(
    dashboardHeader(title = "Cedar Creek Cameras"),
    sidebar,
    body
)
