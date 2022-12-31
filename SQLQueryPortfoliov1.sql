Select *
From PortfolioProject..CovidDeaths
Where continent is not null
Order By 3,4
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
WHERE continent is not null
Order By 1,2


--Total Cases vs Total Deaths...Likelihood of death resulting from Covid contraction based on location
Select location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 AS FatalityPercentage
From PortfolioProject..CovidDeaths
Where location = 'United States'
AND continent is not null
Order By 1,2


--Countries with the Highest Infection Rate compared to Population
Select location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
WHERE location = 'United States'
Order By 1,2


--Countries with the highest infection rates
Select location, population, Max(total_cases) AS HighestInfectionCount, Max((total_cases/population))*100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group By location, population
Order By PercentPopulationInfected DESC


--Countries with the highest death percentage per population
Select location, Max(cast(total_deaths AS int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group By location
Order By TotalDeathCount DESC


--Continents with the highest death count per population
Select continent, Max(cast(total_deaths AS int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group By continent
Order By TotalDeathCount DESC


--Global numbers...per day
Select date, SUM(new_cases) AS total_cases, SUM(Cast(new_deaths As INT)) AS total_deaths, SUM(Cast(new_deaths As INT))/SUM(new_cases)*100 AS FatalityPercentage
From PortfolioProject..CovidDeaths
--Where location = 'United States'
Where continent is not null
--Group By date
Order By 1,2


--Global numbers in total
Select SUM(new_cases) AS total_cases, SUM(Cast(new_deaths As INT)) AS total_deaths, SUM(Cast(new_deaths As INT))/SUM(new_cases)*100 AS FatalityPercentage
From PortfolioProject..CovidDeaths
--Where location = 'United States'
Where continent is not null
Order By 1,2



--Total Population vs Vaccinations
--Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.vaccinations,
SUM(CONVERT(int, vac.vaccinations)) OVER (Partition by dea.location Order By dea.location, dea.date) as RollingVaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinactions vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order By 2,3


--Using CTE to perform calculation on partition in previous query
With PopvsVac (continent, location, date, population, new_vaccinations, rollingvaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.location, dea.date) as RollingVaccinations
--(RollingVaccinations/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinactions vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order By 2,3
)
Select *, (rollingvaccinations/population)*100
From PopvsVac




--Temp Table to perform calculation on partition in previous query
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingvaccinations numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.location, dea.date) as RollingVaccinations
--(RollingVaccinations/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinactions vac
	ON dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not null
--Order By 2,3

Select *, (rollingvaccinations/population)*100
From #PercentPopulationVaccinated




--Creating view to store data for visualization
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.location, dea.date) as RollingVaccinations
--,(RollingVaccinations/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinactions vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
