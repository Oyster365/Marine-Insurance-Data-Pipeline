# Marine-Insurance-Data-Pipeline

## Summary
I built a simple data pipeline where raw insurance policy, claim and customer data was made with Python as a CSV file, flows into PostgreSQL, is transformed with SQL, and a dashboard is made in Power BI. This pipeline replicates the process insurance product analysts use to monitor loss ratios, underwriting strategy, and annual profit.

## Files
The repository is organized in the following way. 

Generated Data -->
- **claims.csv** is the Python generated claims data
- **customers.csv** is the Python generated customers data
- **policies.csv** is the Python generated policies data

Images --> 
- **Power BI Dashboard Preview.PNG** is a clipping of the dynamic dashboard to preview
- **Schema Diagram.PNG** shows the relational diagram I created when designing the database

Other -->
- **Marine Insurance Dashboard.pbix** is the full dashboard in Power BI
- **genscript.py** is the script I used to generate the mock data for this project
- **script.sql** is the script I used to create tables, bring in data, and query the data before being sent to Power BI

## Database Relationships
This is the schema I created when developing the data for the database. It shows the relationship between customers, policies, and claims.

![Schema Diagram](Images/Schema%20Diagram.PNG)


## Dashboard
This is a preview of the dynamic Power BI dashboard created from the data pipeline. It shows insights regarding profitability, loss variables, and trends across various regions.

![Dashboard Preview](Images/Power%20BI%20Dashboard%20Preview.PNG)

## Tools
This project features the following tools
- **Python** to generate the three mock data CSV files
- **PostgreSQL** to create tables, set relationships, and write queries for analyitcs
- **Power BI** to build an interactive dashboard with slicers, cards and charts
- **VS Code** was used to save and organize Python and SQL script
