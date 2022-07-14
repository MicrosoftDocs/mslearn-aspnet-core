using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace WebCouponStatus.Services
{
    public interface ICouponService
    {
        Task<List<CouponDto>> GetAllAvailableCoupons();
    }
}
