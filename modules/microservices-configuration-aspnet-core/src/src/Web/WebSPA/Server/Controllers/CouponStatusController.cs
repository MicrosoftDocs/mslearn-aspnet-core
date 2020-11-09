using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using WebSPA.Server.Services;

namespace WebSPA.Server.Controllers
{    
    public class CouponStatusController : Controller
    {
        private readonly ILogger<CouponStatusController> _logger;
        private readonly ICouponService _couponService;
        
        public CouponStatusController(ILogger<CouponStatusController> logger, ICouponService couponService)
        {
            _logger = logger;
            _couponService = couponService;
        }

        [HttpGet]        
        public async Task<IActionResult> Index()
        {
            try
            {
                var cookie = Request.Headers["Cookie"].ToString();

                if (!String.IsNullOrEmpty(cookie) && cookie.Contains(".AspNetCore.Identity.Application="))
                {
                    var allCoupons = await _couponService.GetAllAvailableCouponsAsync();

                    ViewData["coupons"] = allCoupons;

                    return View(allCoupons);
                }
                else
                {
                    return RedirectToAction("Index", "ErrorController");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError("Error ! Exception while fetching coupon status.");
                _logger.LogError(ex.ToString());

                return RedirectToAction("Index", "ErrorController");
            }
            
        }        
    }
}
