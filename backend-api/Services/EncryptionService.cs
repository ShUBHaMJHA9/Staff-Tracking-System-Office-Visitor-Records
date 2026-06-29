using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace IodEnterpriseApi.Services
{
    public static class EncryptionService
    {
        // 32-byte key for AES-256
        private static readonly byte[] Key = Encoding.UTF8.GetBytes("IOD_Global_Enterprise_OMS_SuperS"); 
        
        public static string EncryptDouble(double value)
        {
            try
            {
                using var aes = Aes.Create();
                aes.Key = Key;
                aes.GenerateIV();

                var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
                var valueBytes = BitConverter.GetBytes(value);

                using var ms = new MemoryStream();
                ms.Write(aes.IV, 0, aes.IV.Length); // prepend IV
                
                using (var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write))
                {
                    cs.Write(valueBytes, 0, valueBytes.Length);
                }
                
                return Convert.ToBase64String(ms.ToArray());
            }
            catch
            {
                return value.ToString(); // fallback
            }
        }

        public static double DecryptDouble(string encryptedText)
        {
            try
            {
                var fullCipher = Convert.FromBase64String(encryptedText);
                
                using var aes = Aes.Create();
                var iv = new byte[aes.BlockSize / 8];
                Array.Copy(fullCipher, 0, iv, 0, iv.Length);
                aes.Key = Key;
                aes.IV = iv;

                using var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);
                using var ms = new MemoryStream(fullCipher, iv.Length, fullCipher.Length - iv.Length);
                using var cs = new CryptoStream(ms, decryptor, CryptoStreamMode.Read);
                
                var plainBytes = new byte[8];
                int read = cs.Read(plainBytes, 0, plainBytes.Length);
                if (read == 8)
                {
                    return BitConverter.ToDouble(plainBytes, 0);
                }
                return 0;
            }
            catch
            {
                if (double.TryParse(encryptedText, out double val)) return val;
                return 0;
            }
        }
    }
}
