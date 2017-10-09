#define __TESTE__

#include "capicom.ch"
#include "hbclass.ch"
#ifdef __TESTE__

PROCEDURE TesteCapicom

   LOCAL cTexto, cSignatureValue, cDigestValue, cPublicKey

   cTexto    := "texto a ser gerado hash, no caso de arquivo, carregue o arquivo e passe para esta funcao"

   cDigestValue    := CapicomClass():HashData( cTexto )
   cSignatureValue := CapicomClass():Sign( cDigestValue, , , @cPublicKey )

   ?
   ? cDigestValue == CapicomClass():VerifySignature( cSignatureValue )
   ? IsValidSignatureCapicom( cDigestValue, cSignatureValue )
   ? cPublicKey

   WAIT

   RETURN
#endif

FUNCTION IsValidSignatureCapicom( cDigestValue, cSignatureValue )

   IF cDigestValue = NIL .OR. cSignatureValue = NIL
      RETURN .F.
   ENDIF

   RETURN CapicomClass():VerifySignature( cSignatureValue ) == cDigestValue

CLASS CapicomClass

   METHOD SelectCertificate()
   METHOD VerifySignature( cSignedData )
   METHOD HashData( cData, nAlgorithm )
   METHOD PublicKey( oCAPICOMCert )
   METHOD Sign( cDigestValue, oCAPICOMcert, nEncode, cPublicKey )

   END CLASS

METHOD SelectCertificate() CLASS CapicomClass

   LOCAL oCapicom, oCertificate

   oCapicom:= win_OleCreateObject( "CAPICOM.Store" )
   oCapicom:Open( CAPICOM_CURRENT_USER_STORE, "My", CAPICOM_STORE_OPEN_READ_ONLY )
   BEGIN SEQUENCE WITH { || __BreakBlock() }
      oCertificate := oCapicom:Certificates:Select( "Selecione um certificado digital", "Algoritmo de Assinatura SHA256RSA" )
   END SEQUENCE
   IF oCapicom:Certificates:Count() == 0
      RETURN NIL
   ENDIF

   RETURN oCertificate:Item( 1 )

METHOD VerifySignature( cSignedData ) CLASS CapicomClass

   LOCAL oCapicom

   IF cSignedData == NIL
      RETURN NIL
   ENDIF

   oCapicom := win_OleCreateObject( "CAPICOM.SignedData.1" )
   oCapicom:Verify( cSignedData, .F., CAPICOM_VERIFY_SIGNATURE_ONLY )

   RETURN oCapicom:Content

METHOD HashData( cData, nAlgorithm ) CLASS CapicomClass

   LOCAL oCapicom

   IF cData = NIL
      cData := DToS( Date() ) + Time()
   ENDIF

   IF nAlgorithm = NIL
      nAlgorithm := CAPICOM_HASH_ALGORITHM_SHA_256
   ENDIF

   oCapicom := win_OleCreateObject( "CAPICOM.HashedData.1" )
   oCapicom:Algorithm := nAlgorithm
   oCapicom:Hash( cData )

   RETURN oCapicom:Value

METHOD PublicKey( oCapicomCert ) CLASS CapicomClass

   LOCAL oCapicom, cPublicKey

   oCapicom := win_OleCreateObject( "CAPICOM.Signer.2" )
   oCapicom:Signer:Certificate := oCAPICOMCert
   oCapicom:Signer:Options := CAPICOM_CERTIFICATE_INCLUDE_CHAIN_EXCEPT_ROOT
   cPublicKey := StrTran( oCapicom:Certificate:Export( CAPICOM_ENCODE_BASE64 ), Chr(13) + Chr(10), "" )

   RETURN cPublicKey

METHOD Sign( cDigestValue, oCAPICOMCert, nEncode, cPublicKey ) CLASS CapicomClass

   LOCAL oCAPICOMSignedData, oCAPICOMSigner, oCAPICOMTimeStamp, cSignature

   IF cDigestValue = NIL
      RETURN NIL
   ENDIF

   IF nEncode = NIL
      nEncode := CAPICOM_ENCODE_BASE64
   ENDIF

   oCAPICOMSigner := win_OleCreateObject( "CAPICOM.Signer.2" ) // versao 2

   IF oCAPICOMCert = NIL
      oCAPICOMCert := ::SelectCertificate()
      IF oCAPICOMCert = NIL
         RETURN NIL
      ENDIF
      oCAPICOMSigner:Certificate := oCAPICOMcert
   ELSE
      oCAPICOMSigner:Certificate := oCAPICOMcert:DefaultInterface
   ENDIF

   IF ! ( oCAPICOMSigner:Certificate:HasPrivateKey ;
         .AND. DToS( oCAPICOMSigner:Certificate:ValidFromDate ) <= DToS( Date() ) ;
         .AND. DToS( oCAPICOMSigner:Certificate:ValidToDate ) >= DToS( Date() ) )
      RETURN NIL
   ENDIF

   oCAPICOMSigner:Options := CAPICOM_CERTIFICATE_INCLUDE_CHAIN_EXCEPT_ROOT
   cPublicKey             := StrTran( oCAPICOMSigner:Certificate:Export( CAPICOM_ENCODE_BASE64 ), Chr(13) + Chr(10), "" )

   oCAPICOMTimeStamp := win_OleCreateObject( "CAPICOM.Attribute" )
   oCAPICOMTimeStamp:Name  := CAPICOM_AUTHENTICATED_ATTRIBUTE_SIGNING_TIME
   oCAPICOMTimeStamp:Value := hb_DateTime()

   oCAPICOMSigner:AuthenticatedAttributes:Add( oCAPICOMTimeStamp )

   oCAPICOMSignedData := win_OleCreateObject( "CAPICOM.SignedData.1" )
   oCAPICOMSignedData:Content := cDigestValue

// segundo parametro falso, apenas retona assinatura do texto, n�o inclui no texto
   cSignature := oCAPICOMSignedData:Sign( oCAPICOMSigner, .F., nEncode )

   RETURN cSignature