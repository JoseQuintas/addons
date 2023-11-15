#include "sefazclass.ch"

FUNCTION ze_Sefaz_MDFeEnvio( Self, cXml, cUF, cCertificado, cAmbiente, lSincrono )

   LOCAL oDoc, cBlocoXml, aList, nPos, cURLConsulta := "http:"

   hb_Default( @::cVersao, WS_MDFE_DEFAULT )
   ::cProjeto := WS_PROJETO_MDFE
   IF lSincrono != Nil .AND. ValType( lSincrono ) == "L"
      ::lSincrono := lSincrono
   ENDIF
   IF ::lSincrono
      ::aSoapUrlList := WS_MDFE_RECEPCAOSINC
      ::cSoapAction := "http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcaoSinc/mdfeRecepcao"
   ELSE
      ::aSoapUrlList := WS_MDFE_AUTORIZACAO
      ::cSoapAction  := "http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcao/MDFeRecepcao"
   ENDIF
   ::Setup( cUF, cCertificado, cAmbiente )

   IF cXml != NIL
      ::cXmlDocumento := cXml
   ENDIF
   IF ::AssinaXml() != "OK"
      RETURN ::cXmlRetorno
   ENDIF
   oDoc := XmlToDoc( cXml, .F. )
   aList := WS_MDFE_QRCODE
   nPos := hb_ASCan( aList, { | e | e[ 2 ] == ::cVersao + iif( oDoc:cAmbiente == "1", "P", "H" ) } )
   IF nPos != 0
      cURLConsulta := aList[ nPos, 3 ]
   ENDIF
   IF ! "<infMDFeSupl>" $ ::cXmlDocumento
      cBlocoXml := "<infMDFeSupl>"
      cBlocoXml += "<qrCodMDFe>"
      cBlocoXml += "<![CDATA["
      cBlocoXml += cURLConsulta + "?chMDFe=" + oDoc:cChave + "&" + "tpAmb=" + ::cAmbiente
      cBlocoXml += "]]>"
      cBlocoXml += "</qrCodMDFe>"
      cBlocoXml += "</infMDFeSupl>"
      ::cXmlDocumento := StrTran( ::cXmlDocumento, "</infMDFe>", "</infMDFe>" + cBlocoXml )
   ENDIF
   IF ::lSincrono
      ::cXmlEnvio := ::cXmlDocumento
   ELSE
      ::cXmlEnvio  := [<enviMDFe versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
      ::cXmlEnvio  +=    XmlTag( "idLote", "1" )
      ::cXmlEnvio  +=    ::cXmlDocumento
      ::cXmlEnvio  += [</enviMDFe>]
   ENDIF
   ::XmlSoapPost()
   ::cXmlRecibo := ::cXmlRetorno
   IF ::lSincrono
      ::cXmlProtocolo := ::cXmlRecibo
      ::MDFeGeraAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
   ELSE
      ::cRecibo    := XmlNode( ::cXmlRecibo, "nRec" )
      IF ::cStatus != "999"
         ::cStatus    := Pad( XmlNode( ::cXmlRecibo, "cStatus" ), 3 )
         ::cMotivo    := XmlNode( ::cXmlRecibo, "xMotivo" )
      ENDIF
      IF ! Empty( ::cRecibo ) .AND. ::cStatus != "999"
         Inkey( ::nTempoEspera )
         ::MDFeRetEnvio()
         ::MDFeGeraAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
      ENDIF
   ENDIF

   RETURN ::cXmlRetorno