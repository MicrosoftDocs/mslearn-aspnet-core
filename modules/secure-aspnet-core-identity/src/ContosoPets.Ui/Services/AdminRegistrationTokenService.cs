using System;

namespace ContosoPets.Ui.Services
{
    public class AdminRegistrationTokenService
    {
        private readonly Lazy<long> _creationKey = 
            new Lazy<long>(() => BitConverter.ToInt64(Guid.NewGuid().ToByteArray(), 7));

        public long CreationKey => _creationKey.Value;
    }
}
