let
    DataInicio = List.Min(Table.Column(#"NOME_TABELA","NOME_COLUNA")),
    DataFim = List.Max(Table.Column(#"NOME_TABELA","NOME_COLUNA")),
    //Culture: se não for explicitamente setada, pega o valor associado ao arquivo
    Culture = "pt-BR",
    CountDias = Duration.Days(DataFim - DataInicio),
    ListDatas = List.Dates(DataInicio, CountDias,#duration(1,0,0,0)),
    TabelaDatas = Table.FromList(ListDatas, Splitter.SplitByNothing(), {"Data"}, null, ExtraValues.Error),
    #"Tipo Alterado" = Table.TransformColumnTypes(TabelaDatas,{{"Data", type date}}),
    //Criação de campos relacionados (para outros campos, consultar https://msdn.microsoft.com/en-us/library/mt296606.aspx)
    Ano = Table.AddColumn(#"Tipo Alterado", "Ano", each Date.Year([Data]), Int64.Type),
    //Trimestre = Table.AddColumn(Ano, "Trimestre", each Date.QuarterOfYear([Data])),
    //Semestre = Table.AddColumn(Trimestre, "Semestre", each if [Mês] < 7 then 1 else 2),
    //SemanaAno = Table.AddColumn(Semestre, "Semana Ano", each Date.WeekOfYear([Data])),
    MesAno = Table.AddColumn(Ano, "Mês", each Date.Month([Data]), Int64.Type),
    AnoMes = Table.AddColumn(MesAno, "Ano Mês", each Number.ToText([Ano]) & Text.PadStart(Number.ToText([Mês]),2,"0"), type text),
    NomeMes = Table.AddColumn(AnoMes, "Nome Mês", each Date.MonthName([Data],Culture), type text),
    //NomeMesAno = Table.AddColumn(NomeMes, "Mês/Ano", each [Nome Mês]&"/"&Number.ToText([Ano])),
    NomeMesAnoAbreviado = Table.AddColumn(NomeMes, "Mês/Ano", each Text.Range([Nome Mês],0,3)&"/"&Number.ToText([Ano]), type text),
    #"Fim do Mês Inserido" = Table.AddColumn(NomeMesAnoAbreviado, "Fechamento Mês", each Date.EndOfMonth([Data]), type date),
    #"Dias inseridos no Mês" = Table.AddColumn(#"Fim do Mês Inserido", "Dias do Mês", each Date.DaysInMonth([Data]), Int64.Type),
    #"Personalização Adicionada" = Table.AddColumn(#"Dias inseridos no Mês", "Dia Corrido", each if [Data] < DateTime.Date(DateTime.LocalNow()) then 1 else 0,Int64.Type),
    #"Últimos caracteres inseridos" = Table.AddColumn(#"Personalização Adicionada", "Últimos caracteres", each Text.End(Text.From([Fechamento Mês], "pt-BR"), 2), type text),
    #"Texto Inserido Entre os Delimitadores" = Table.AddColumn(#"Últimos caracteres inseridos", "Texto Entre os Delimitadores", each Text.BetweenDelimiters(Text.From([Fechamento Mês], "pt-BR"), "/", "/"), type text),
    #"Colunas Mescladas" = Table.CombineColumns(#"Texto Inserido Entre os Delimitadores",{"Últimos caracteres", "Texto Entre os Delimitadores"},Combiner.CombineTextByDelimiter("/", QuoteStyle.None),"Ano/Mes")
in
    #"Colunas Mescladas"