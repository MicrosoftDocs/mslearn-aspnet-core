using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using WebSPA.Server.Services;

namespace WebSPA.Server.Controllers
{    
    public class CouponStatusController : Controller
    {
        private readonly ICouponService _couponService;
        
        public CouponStatusController(ICouponService couponService)
        {
            _couponService = couponService;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var allCoupons = await _couponService.GetAllAvailableCouponsAsync();

            ViewData["coupons"] = allCoupons;

            return View(allCoupons);
        }        
    }
}
