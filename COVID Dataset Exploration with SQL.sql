--COVID Data Exploration

--Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Convertung Data Types


SELECT *
FROM [Portfolio Project].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 3,4

-- Select Data that we are going to be starting with
SELECT location
	  ,date
	  ,total_cases
	  ,new_cases
	  ,total_deaths
	  ,population
FROM [Portfolio Project].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1,2


--Total cases vs Total Deaths
--Shows likelihood of dying if you contract COVID in United States
SELECT location
	  ,date
	  ,total_cases
	  ,total_deaths
	  ,(convert(int, total_deaths)/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project].[dbo].[CovidDeaths]
WHERE location = 'United States' and
	  continent IS NOT NULL
ORDER BY 1,2


--Total Cases vs Population
--Shows what percentage of population infected with COVID
SELECT location
	  ,date
	  ,population
	  ,total_cases
	  ,(total_cases/population)*100 AS PercentPopulationInfected
FROM [Portfolio Project].[dbo].[CovidDeaths]
--WHERE location = 'United States' and
--	  continent IS NOT NULL
ORDER BY 1,2


--Countries with highest infection rate compared to population
SELECT location
	  ,population
	  ,SUM(convert(bigint,total_cases)) AS TotalInfectionCount
	  ,MAX(total_cases) AS HighestInfectionCount
	  ,MAX((total_cases/population)*100) AS PercentPopulationInfected
FROM [Portfolio Project].[dbo].[CovidDeaths]
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--Countries with highest death count compared to population
SELECT location
	  ,MAX(CAST(total_deaths as bigint)) AS TotalDeathCount
FROM [Portfolio Project].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC


--Breaking things down by continent
--Showing continents with the highest death count per population
SELECT location
	  ,MAX(CAST(total_deaths as bigint)) AS TotalDeathCount
FROM [Portfolio Project].[dbo].[CovidDeaths]
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


--Global Numbers
SELECT SUM(new_cases) as total_cases
	  ,SUM(CAST(new_deaths as BIGINT)) AS total_deaths
	  ,(SUM(CAST(new_deaths as bigint))/SUM(new_cases))*100 AS DeathPercentage
FROM [Portfolio Project].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1,2


--Total Population vs Vaccinations
--Shows Percentage of Population that has received at least one COVID Vaccine
SELECT dea.continent
	  ,dea.location
	  ,dea.date
	  ,dea.population
	  ,vac.new_vaccinations
	  ,SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Portfolio Project].[dbo].[CovidDeaths] dea 
JOIN [Portfolio Project].[dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.location = 'United States'
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--Using CTE to perform Calculation on Partition by in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(SELECT dea.continent
	  ,dea.location
	  ,dea.date
	  ,dea.population
	  ,vac.new_vaccinations
	  ,SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Portfolio Project].[dbo].[CovidDeaths] dea 
JOIN [Portfolio Project].[dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.location = 'United States'
WHERE dea.continent IS NOT NULL)

SELECT *
	   ,round((RollingPeopleVaccinated/Population)*100,4) AS PercentVaccinated
FROM PopvsVac


--Using TEMP TABLE to perform calculation on partition by in previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent
	  ,dea.location
	  ,dea.date
	  ,dea.population
	  ,vac.new_vaccinations
	  ,SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Portfolio Project].[dbo].[CovidDeaths] dea 
JOIN [Portfolio Project].[dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *
	  ,(RollingPeopleVaccinated/Population)*100 AS PercentPeopleVaccinated
FROM #PercentPopulationVaccinated


--Creating View to store data for later visualizations
DROP VIEW if exists PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent
	  ,dea.location
	  ,dea.date
	  ,dea.population
	  ,vac.new_vaccinations
	  ,SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Portfolio Project].[dbo].[CovidDeaths] dea 
JOIN [Portfolio Project].[dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL