IF OBJECT_ID ('tempdb..#Tabelas') IS NOT NULL DROP TABLE #Tabelas
IF OBJECT_ID ('tempdb..#Tamanho_Tabelas') IS NOT NULL DROP TABLE #Tamanho_Tabelas

CREATE TABLE #tabelas (ID INT IDENTITY, codigo VARCHAR(500))
CREATE TABLE #Tamanho_Tabelas (Nome_Tabela varchar(500), Qtd_linhas BIGINT, Espaco_Reservado_GB varchar(1000), Espaco_usado_GB varchar(1000),
Espaco_Indices_GB varchar(1000), Espaco_Nao_Usado_GB varchar(300))

insert into #tabelas
select 'INSERT INTO #Tamanho_Tabelas EXEC SP_SPACEUSED '''+SCHEMA_NAME(schema_id)+'.'+name+CHAR(39) as Nome_Tabela 
from sys.tables
order by name


DECLARE @CONT INT, @CODIGO NVARCHAR(MAX)
SET @CONT = 1


 WHILE @CONT <= (SELECT MAX(ID) FROM #tabelas)

    BEGIN
      
      SELECT @CODIGO = CODIGO FROM #tabelas
      WHERE ID = @CONT
      
      EXEC (@CODIGO)
      
      SET @CONT = @CONT +1
      

    END

update #Tamanho_Tabelas
set Espaco_Reservado_GB = REPLACE (Espaco_Reservado_GB,' KB',''),
    Espaco_usado_GB = REPLACE (Espaco_usado_GB,' KB',''),
    Espaco_Indices_GB = REPLACE (Espaco_Indices_GB,' KB',''),
    Espaco_Nao_Usado_GB = REPLACE (Espaco_Nao_Usado_GB,' KB','')
    
update #Tamanho_Tabelas
set Espaco_Reservado_GB = convert(decimal(18,2),(convert(decimal(18,2),Espaco_Reservado_GB) /1024/1024)),
    Espaco_usado_GB = convert(decimal(18,2),(convert(decimal(18,2),Espaco_usado_GB) /1024/1024)),
    Espaco_Indices_GB = convert(decimal(18,2),(convert(decimal(18,2),Espaco_Indices_GB) /1024/1024)),
    Espaco_Nao_Usado_GB = convert(decimal(18,2),(convert(decimal(18,2),Espaco_Nao_Usado_GB) /1024 /1024))


alter table #Tamanho_Tabelas alter column Espaco_Reservado_GB decimal (18,2)
alter table #Tamanho_Tabelas alter column Espaco_usado_GB decimal (18,2)
alter table #Tamanho_Tabelas alter column Espaco_Indices_GB decimal (18,2)
alter table #Tamanho_Tabelas alter column Espaco_Nao_Usado_GB decimal (18,2)


SELECT * FROM #Tamanho_Tabelas
where Nome_Tabela NOT like '%_IN[0-1-2-3]%'
AND  Nome_Tabela NOT like '%BKP%'
 AND Nome_Tabela NOT like '%2020%'
 AND Nome_Tabela NOT like '%2019%'
order by Espaco_usado_GB desc

