using QRCoder;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

namespace ContosoPets.Ui.Services
{
    public class QRCodeService
    {
        private readonly QRCodeGenerator _generator;

        public QRCodeService(QRCodeGenerator generator)
        {
            _generator = generator;
        }
        
        public byte[] GetQRCodeAsPng(string textToEncode)
        {
            QRCodeData qrCodeData = _generator.CreateQrCode(textToEncode, QRCodeGenerator.ECCLevel.Q);
            var qrCode = new QRCode(qrCodeData);
            Bitmap qrCodeImage = qrCode.GetGraphic(4);

            return BitmapToPngBytes(qrCodeImage); //Convert bitmap into a byte array
        }

        private static byte[] BitmapToPngBytes(Bitmap img)
        {
            using (var stream = new MemoryStream())
            {
                img.Save(stream, ImageFormat.Png);
                return stream.ToArray();
            }
        }
    }

}