SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

SELECT Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 4) AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Ukraine' AND total_deaths > 0;

SELECT Location, date, Population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location = 'Ukraine'
ORDER BY 1, 2;

-- Countries with Highest Infection Rate compared to Population
SELECT 
    Location, 
    Population, 
    MAX(total_cases) AS HighestInfectionCount, 
    MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
SELECT 
    Location, 
    MAX(CAST(Total_deaths AS DECIMAL)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Showing continents with the highest death count per population
SELECT 
    continent, 
    MAX(CAST(Total_deaths AS DECIMAL)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS DECIMAL)) AS total_deaths, 
    SUM(CAST(new_deaths AS DECIMAL))/SUM(New_Cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(vac.new_vaccinations, DECIMAL)) 
    OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != '' AND vac.new_vaccinations > 0
ORDER BY 2, 3;

-- Using CTE to perform Calculation on Partition By in the previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(vac.new_vaccinations, DECIMAL)) 
    OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != '' AND vac.new_vaccinations > 0
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentageVaccinated
FROM PopvsVac;

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(vac.new_vaccinations, DECIMAL)) 
    OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != '' AND vac.new_vaccinations > 0;
