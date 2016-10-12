/*
ze_spedxmlvalida - Valida��o de XML
2016.07.28.1620 - Jos� Quintas
*/

/*
PROCEDURE PTESValidaXml

   LOCAL cRetorno

   cRetorno := ValidaXml( MemoRead( "d:\jpa\cordeiro\nfe\tmp\nf000094053-02-assinado.xml" ), "NFE" )
   MsgExclamation( cRetorno )

   RETURN
*/

FUNCTION ValidaXml( cXml, cTipo )

   LOCAL oXmlDomDoc, oXmlSchema, oXmlErro, cFileXSD := "", cRetorno := "ERRO"
	If cTipo = Nil
		cTipo := ""
	Endif
   //hb_DefaultValue( @cTipo, "" )

   BEGIN SEQUENCE WITH __BreakBlock()

      cRetorno   := "Erro Carregando MSXML2.DomDocument.6.0"
      oXmlDomDoc := win_OleCreateObject( "MSXML2.DomDocument.6.0" )
      oXmlDomDoc:aSync            := .F.
      oXmlDomDoc:ResolveExternals := .F.
      oXmlDomDoc:ValidateOnParse  := .T.

      cRetorno   := "Erro Carregando XML"
      oXmlDomDoc:LoadXml( cXml )
      IF oXmlDomDoc:ParseError:ErrorCode <> 0
         cRetorno := "Erro XML inv�lido " + ;
                     " Linha: "   + AllTrim( Transform( oXmlDomDoc:ParseError:Line, "" ) ) + ;
                     " coluna: "  + AllTrim( Transform( oXmlDomDoc:ParseError:LinePos, "" ) ) + ;
                     " motivo: "  + AllTrim( Transform( oXmlDomDoc:ParseError:Reason, "" ) ) + ;
                     " errcode: " + AllTrim( Transform( oXmlDomDoc:ParseError:ErrorCode, "" ) )
          BREAK
      ENDIF

      cRetorno   := "Erro Carregando MSXML2.XMLSchemaCache.6.0"
      oXmlSchema := win_OleCreateObject( "MSXML2.XMLSchemaCache.6.0" )

      DO CASE
      CASE cTipo == "NFE" 
      	IF !EMPTY(oSefaz:cPastaSchemas)
		    	cFileXSD := Left( hb_Argv(0), Rat( "\", hb_Argv(0) ) ) + "schemmas\nfe_v3.10.xsd" // runner
	    	ELSE
		    	cFileXSD := oSefaz:cPastaSchemas + "schemmas\nfe_v3.10.xsd" // runner
	    	ENDIF
      CASE cTipo == "CTE" 
      	IF !EMPTY(oSefaz:cPastaSchemas)
			    cFileXSD := Left( hb_Argv(0), Rat( "\", hb_Argv(0) ) ) + "schemmas\cte_v2.00.xsd" // runner
			ELSE
			    cFileXSD := oSefaz:cPastaSchemas + "schemmas\cte_v2.00.xsd" // runner
			ENDIF
      CASE cTipo == "MDFE" 
      	IF !EMPTY(oSefaz:cPastaSchemas)
			    cFileXSD := Left( hb_Argv(0), Rat( "\", hb_Argv(0) ) ) + "schemmas\mdfe_v1.00.xsd" // runner
			ELSE
			    cFileXSD := oSefaz:cPastaSchemas + "schemmas\cte_v2.00.xsd" // runner
			ENDIF
      OTHERWISE
         cRetorno := "OK"       /* Valida��o b�sica */
         BREAK
      ENDCASE
      IF .NOT. File( cFileXSD )
         cRetorno := "Erro n�o encontrado arquivo " + cFileXSD
         BREAK
      ENDIF

      cRetorno := "Erro Carregando " + cFileXSD
		IF cTipo == "NFE" // runner
      	oXmlSchema:Add( "http://www.portalfiscal.inf.br/nfe", cFileXSD )
 		ELSEIF cTipo == "CTE" 
      	oXmlSchema:Add( "http://www.portalfiscal.inf.br/cte", cFileXSD )
 		ELSEIF cTipo == "MDFE" 
      	oXmlSchema:Add( "http://www.portalfiscal.inf.br/mdfe", cFileXSD )
 		ENDIF

      oXmlDomDoc:Schemas := oXmlSchema
      oXmlErro := oXmlDomDoc:Validate()
      IF oXmlErro:ErrorCode <> 0
         cRetorno := "Erro: " + AllTrim( Transform( oXmlErro:ErrorCode, "" ) ) + " " + AllTrim( Transform( oXmlErro:Reason, "" ) )
         BREAK
      ENDIF
      cRetorno := "OK"

   END SEQUENCE

   RETURN cRetorno
