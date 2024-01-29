SELECT * 
	from sql_capstone_project..covid_deaths
	WHERE continent IS NOT NULL
	order by 3,4

--SELECT * 
--	from sql_capstone_project..covid_vaccinations
--	order by 3,4

--Exploratory Data Analysis 
--Select data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM sql_capstone_project..covid_deaths
order by 1,2

-- Looking at total cases vs total deaths

SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS death_percentage
FROM sql_capstone_project..covid_deaths
WHERE Location like '%states%'
order by 1,2

-- looking at total cases vs population

SELECT Location, date, total_cases, Population, (CAST(total_cases AS FLOAT)/CAST(Population AS FLOAT))*100 AS infected_percentage
FROM sql_capstone_project..covid_deaths
WHERE Location like '%states%'
order by 1,2

--  looking at countries with highest indection rate compared to population
SELECT Location, Population, MAX(total_cases) as hihgest_infection_count, (max(CAST(total_cases AS FLOAT)/CAST(Population AS FLOAT)))*100 AS percent_population_infected
FROM sql_capstone_project..covid_deaths
GROUP BY Location, Population
order by percent_population_infected DESC

--Countries with highest death count per population
SELECT Location, MAX(cast(total_deaths AS INT)) AS total_deaths_count
FROM sql_capstone_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY Location
order by total_deaths_count DESC

-- Details by continent
Select continent,  sum(new_deaths) AS total_deaths
from sql_capstone_project..covid_deaths
where continent IS NOT NULL
group by continent
ORDER BY total_deaths DESC

-- Global numbers
SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))*100 AS death_ratio
FROM sql_capstone_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
order by 1,2

-- Global total numbers
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))*100 AS death_ratio_percentage
FROM sql_capstone_project..covid_deaths
WHERE continent IS NOT NULL
order by 1,2


-- looking total population vs vaccinations
SELECT death.continent, death.Location, death.date, death.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations AS float)) OVER (PARTITION BY death.Location ORDER BY death.location, death.Date) AS rolling_count_of_ppl_vaccinated
, 
FROM sql_capstone_project..covid_deaths death
JOIN sql_capstone_project..covid_vaccinations vacc
	ON death.Location = vacc.Location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
order by 2,3

-- Use CTE

WITH PopvsVacc (continent, Location, date, population,new_vaccinations, rolling_count_of_ppl_vaccinated)
AS (
SELECT death.continent, death.Location, death.date, death.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations AS float)) OVER (PARTITION BY death.Location ORDER BY death.location, death.Date) AS rolling_count_of_ppl_vaccinated
FROM sql_capstone_project..covid_deaths death
JOIN sql_capstone_project..covid_vaccinations vacc
	ON death.Location = vacc.Location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL 
)
SELECT *, (rolling_count_of_ppl_vaccinated/population)*100 AS rolling_percentage_ppl_vaccinated
FROM PopvsVacc

-- USING Temp Table

DROP TABLE IF EXIST #PercentPopulationVaccinated --added on the top to do edits in case is needed

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
rolling_count_of_ppl_vaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.Location, death.date, death.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations AS float)) OVER (PARTITION BY death.Location ORDER BY death.location, death.Date) AS rolling_count_of_ppl_vaccinated
FROM sql_capstone_project..covid_deaths death
JOIN sql_capstone_project..covid_vaccinations vacc
	ON death.Location = vacc.Location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL 

SELECT *, (rolling_count_of_ppl_vaccinated/population)*100 AS rolling_percentage_ppl_vaccinated
FROM #PercentPopulationVaccinated

--creating view to store data for visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.Location, death.date, death.population, vacc.new_vaccinations
, SUM(CAST(vacc.new_vaccinations AS float)) OVER (PARTITION BY death.Location ORDER BY death.location, death.Date) AS rolling_count_of_ppl_vaccinated
FROM sql_capstone_project..covid_deaths death
JOIN sql_capstone_project..covid_vaccinations vacc
	ON death.Location = vacc.Location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL 

SELECT *
FROM PercentPopulationVaccinated