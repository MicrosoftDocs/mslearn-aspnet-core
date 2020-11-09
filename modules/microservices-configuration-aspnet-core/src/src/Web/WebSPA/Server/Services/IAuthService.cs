using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace WebSPA.Server.Services
{
    public interface IAuthService
    {
        Task<string> GetAccessTokenAsync();
    }
}
