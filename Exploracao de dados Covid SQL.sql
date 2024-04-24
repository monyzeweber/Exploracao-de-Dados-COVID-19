/*
Explora��o de dados da Covid-19 utilizando dados sobre os �ndices de mortes e vacina��o at� 2021.

Habilidades utilizadas: Joins, CTE's, Tabelas tempor�rias, Windows Functions, Fun��es de Agrega��o, Cria��o de Views, Converter tipos de dados

*/

-- Selecionando os dados que vamos usar:
SELECT
	Location AS Pa�s,
	date AS Data, total_cases AS CasosToTais,
	new_cases AS NovosCasos,
	total_deaths AS TotalMortes,
	population AS Populacao
FROM mortescovid
ORDER BY 1, 2


-- Vis�o Brasil

-- Total de casos vs Popula��o
-- Mostra as chances de voc� pegar Covid no seu pa�s (no caso Brasil)


SELECT 
	Location AS Pa�s,
	date AS Data, population AS Populacao,
	total_cases AS CasosTotais,
	(total_deaths/population)*100 AS PorcentagemInfectados
FROM mortescovid
WHERE location = 'Brazil' and continent is not null
ORDER BY 1, 2


-- Total de casos vs Total de Mortes
-- Mostra as chances de morte ao pegar Covid no seu pa�s (no caso Brasil)

SELECT
	Location AS Pa�s,
	date AS Data, total_cases AS CasosNovos,
	total_deaths AS TotalMortes,
	(total_deaths/total_cases)*100 AS PorcentagemMortes
FROM mortescovid
WHERE location = 'Brazil' and continent is not null
ORDER BY 1, 2


-- Vis�o global

-- Pa�ses com o maioir �ndice de infec��o comparado com sua popula��o

SELECT Location AS Pa�s,
	population AS Populacao,
	MAX(total_cases) AS Maiorinfesta��oPorPais,
	MAX((total_cases/population))*100 AS PorcentagemInfectados
FROM mortescovid
WHERE continent is not null
GROUP BY population, location
ORDER BY PorcentagemInfectados DESC



-- Pa�s com maior �ndice de mortes por popula��o

SELECT
	Location AS Pa�s,
	MAX(cast(total_deaths as bigint)) AS MaximoTotalMortes
FROM mortescovid
WHERE continent is not null
GROUP BY location
ORDER BY MaximoTotalMortes DESC



-- Analisando por Continente

-- Continentes com o maior �ndice de mortes por popula��o

SELECT
	continent AS Continente,
	MAX(cast(total_deaths as bigint)) AS MaximoTotalMortes
FROM mortescovid
WHERE continent is not null
GROUP BY continent
ORDER BY MaximoTotalMortes DESC



-- Analisando Globalmente a porcentagem de morte durante todo per�odo analisado

SELECT
	SUM(new_cases) as SomaCasosTotais,
	SUM(cast(new_deaths AS bigint)) AS QtdMortes,
	ROUND(SUM(cast(new_deaths AS bigint))/SUM(new_cases), 3)*100 AS PorcentagemMortesGlobal
FROM mortescovid
WHERE continent is not null
ORDER BY 1, 2



-- Quantidade da Popula��o que recebeu pelo menos uma vacina��o ao longo dos meses

Select 
	dea.continent AS Continente,
	dea.location AS Pa�s,
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



-- Usando uma tabela tempor�ria para calcular a % de pessoas vacinadas

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



-- Criando uma view para utilizar na visualiza��o de dados:

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From mortescovid dea
Join vacinacovid vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 