using QRCoder;

namespace ContosoPets.Ui.Services
{
    public class QRCodeService
    {
        private readonly QRCodeGenerator _generator;

        public QRCodeService(QRCodeGenerator generator)
        {
            _generator = generator;
        }
        
        public string GetQRCodeAsBase64(string textToEncode)
        {
            QRCodeData qrCodeData = _generator.CreateQrCode(textToEncode, QRCodeGenerator.ECCLevel.Q);
            var qrCode = new Base64QRCode(qrCodeData);

            return qrCode.GetGraphic(4);
        }
    }
}