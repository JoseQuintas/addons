#include "sefazclass.ch"

FUNCTION ze_sefaz_MDFeEmAberto( Self, cUF, cCNPJ , cCertificado, cAmbiente )

   hb_Default( @::cVersao, WS_MDFE_DEFAULT )
   ::cProjeto := WS_PROJETO_MDFE
   ::cSoapAction  := "http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsNaoEnc/mdfeConsNaoEnc"
   ::aSoapUrlList := WS_MDFE_CONSULTANAOENCERRADOS
   ::Setup( cUF, cCertificado, cAmbiente )
   cCnpj := SoNumeros( cCnpj )

   ::cXmlEnvio := [<consMDFeNaoEnc versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlEnvio +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio +=    XmlTag( "xServ", "CONSULTAR N�O ENCERRADOS" )
   ::cXmlEnvio +=    XmlTag( iif( Len( cCnpj ) == 11, "CPF", "CNPJ" ), cCNPJ )
   ::cXmlEnvio += [</consMDFeNaoEnc>]
   ::XmlSoapPost()
   IF ::cStatus != "999"
      ::cStatus := Pad( XmlNode( XmlNode( ::cXmlRetorno , "retConsMDFeNaoEnc" ) , "cStat" ), 3 )
      ::cMotivo := XmlNode( XmlNode( ::cXmlRetorno , "retConsMDFeNaoEnc" ) , "xMotivo" )
   ENDIF

   RETURN ::cXmlRetorno
