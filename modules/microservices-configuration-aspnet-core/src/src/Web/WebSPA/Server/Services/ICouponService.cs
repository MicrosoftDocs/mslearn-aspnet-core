using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using WebSPA.ViewModels;

namespace WebSPA.Server.Services
{
    public interface ICouponService
    {
        Task<List<Coupon>> GetAllAvailableCouponsAsync();
    }
}
