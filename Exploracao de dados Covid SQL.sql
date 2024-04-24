/*
Exploração de dados da Covid-19 utilizando dados sobre os índices de mortes e vacinação até 2021.

Habilidades utilizadas: Joins, CTE's, Tabelas temporárias, Windows Functions, Funções de Agregação, Criação de Views, Converter tipos de dados

*/

-- Selecionando os dados que vamos usar:
SELECT
	Location AS País,
	date AS Data, total_cases AS CasosToTais,
	new_cases AS NovosCasos,
	total_deaths AS TotalMortes,
	population AS Populacao
FROM mortescovid
ORDER BY 1, 2


-- Visão Brasil

-- Total de casos vs População
-- Mostra as chances de você pegar Covid no seu país (no caso Brasil)


SELECT 
	Location AS País,
	date AS Data, population AS Populacao,
	total_cases AS CasosTotais,
	(total_deaths/population)*100 AS PorcentagemInfectados
FROM mortescovid
WHERE location = 'Brazil' and continent is not null
ORDER BY 1, 2


-- Total de casos vs Total de Mortes
-- Mostra as chances de morte ao pegar Covid no seu país (no caso Brasil)

SELECT
	Location AS País,
	date AS Data, total_cases AS CasosNovos,
	total_deaths AS TotalMortes,
	(total_deaths/total_cases)*100 AS PorcentagemMortes
FROM mortescovid
WHERE location = 'Brazil' and continent is not null
ORDER BY 1, 2


-- Visão global

-- Países com o maioir índice de infecção comparado com sua população

SELECT Location AS País,
	population AS Populacao,
	MAX(total_cases) AS MaiorinfestaçãoPorPais,
	MAX((total_cases/population))*100 AS PorcentagemInfectados
FROM mortescovid
WHERE continent is not null
GROUP BY population, location
ORDER BY PorcentagemInfectados DESC



-- País com maior índice de mortes por população

SELECT
	Location AS País,
	MAX(cast(total_deaths as bigint)) AS MaximoTotalMortes
FROM mortescovid
WHERE continent is not null
GROUP BY location
ORDER BY MaximoTotalMortes DESC



-- Analisando por Continente

-- Continentes com o maior índice de mortes por população

SELECT
	continent AS Continente,
	MAX(cast(total_deaths as bigint)) AS MaximoTotalMortes
FROM mortescovid
WHERE continent is not null
GROUP BY continent
ORDER BY MaximoTotalMortes DESC



-- Analisando Globalmente a porcentagem de morte durante todo período analisado

SELECT
	SUM(new_cases) as SomaCasosTotais,
	SUM(cast(new_deaths AS bigint)) AS QtdMortes,
	ROUND(SUM(cast(new_deaths AS bigint))/SUM(new_cases), 3)*100 AS PorcentagemMortesGlobal
FROM mortescovid
WHERE continent is not null
ORDER BY 1, 2



-- Quantidade da População que recebeu pelo menos uma vacinação ao longo dos meses

Select 
	dea.continent AS Continente,
	dea.location AS País,
	dea.date AS Data, dea.population AS Populacao,
	vac.new_vaccinations AS NovasVacinacoes, 
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as CrescentePessoasVacinadas
From mortescovid dea
Join vacinacovid vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3



-- Usando uma CTE para calcular com Partition By na query anterior

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From mortescovid dea
Join vacinacovid vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)

Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Usando uma tabela temporária para calcular a % de pessoas vacinadas

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From mortescovid dea
Join vacinacovid vac
	On dea.location = vac.location
	and dea.date = vac.date
	
Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Criando uma view para utilizar na visualização de dados:

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From mortescovid dea
Join vacinacovid vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 