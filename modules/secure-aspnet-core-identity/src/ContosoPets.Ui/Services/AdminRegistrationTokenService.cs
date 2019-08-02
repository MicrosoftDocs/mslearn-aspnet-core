// using ContosoPets.Ui.Areas.Identity.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Threading.Tasks;

namespace ContosoPets.Ui.Services
{
    public class AdminRegistrationTokenService
    {
        private readonly Lazy<long> _creationKey = new Lazy<long>(() => BitConverter.ToInt64(Guid.NewGuid().ToByteArray(), 7));
        private readonly IServiceProvider _serviceProvider;

        private bool _adminExists;

        public AdminRegistrationTokenService(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public long CreationKey => _creationKey.Value;

        // public async Task<bool> AllowAdminUserCreationAsync()
        // {
        //     if (_adminExists)
        //     {
        //         return false;
        //     }
        //     else
        //     {
        //         using (var scope = _serviceProvider.CreateScope())
        //         {
        //             var dbContext = scope.ServiceProvider.GetRequiredService<ContosoPetsAuth>();

        //             if (await dbContext.Users.AnyAsync(user => user.IsAdmin))
        //             {
        //                 // There are already admin users so disable admin creation
        //                 _adminExists = true;
        //                 return false;
        //             }

        //             // There are no admin users so enable admin creation
        //             return true;
        //         }
        //     }
        // }

    }

}
