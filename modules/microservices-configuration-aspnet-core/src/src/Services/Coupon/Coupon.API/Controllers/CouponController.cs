namespace Coupon.API.Controllers
{
    using System;
    using System.Collections.Generic;
    using System.Data;
    using System.Linq;
    using System.Net;
    using System.Threading.Tasks;
    using Coupon.API.Dtos;
    using Coupon.API.Infrastructure.Models;
    using Coupon.API.Infrastructure.Repositories;
    using Microsoft.AspNetCore.Authorization;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Extensions.Logging;

    [ApiController]
    [Route("api/v1/[controller]")]
    public class CouponController : ControllerBase
    {
        private readonly ILogger<CouponController> _logger;
        private readonly ICouponRepository _couponRepository;
        private readonly IMapper<CouponDto, Coupon> _mapper;
        private readonly ExceptionTrigger _exceptionTrigger;

        public CouponController(
            ILogger<CouponController> logger,
            ICouponRepository couponRepository,
            IMapper<CouponDto, Coupon> mapper,
            ExceptionTrigger exceptionTrigger)
        {
            _logger = logger;
            _couponRepository = couponRepository;
            _mapper = mapper;
            _exceptionTrigger = exceptionTrigger;
        }

        [HttpGet("{code}")]
        [Authorize]
        [ProducesResponseType((int)HttpStatusCode.NotFound)]
        [ProducesResponseType((int)HttpStatusCode.BadRequest)]
        [ProducesResponseType(typeof(CouponDto), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<CouponDto>> GetCouponByCodeAsync(string code)
        {
            _logger.LogInformation("----- Get coupon {CouponCode}", code);

            var result = _exceptionTrigger.Process(code);

            if (result.shouldFire)
            {
                throw new Exception($"Exception code received: {code}");
            }

            if (result.configured)
            {
                return NotFound($"CONFIG: {result.message}");
            }

            var coupon = await _couponRepository.FindCouponByCodeAsync(code);

            if (coupon is null || coupon.Consumed)
            {
                return NotFound(coupon == null ? "ERROR: The coupon doesn't exist" : "ERROR: The coupon has been redeemed already");
            }

            var couponDto = _mapper.Translate(coupon);

            return Ok(couponDto);
        }
        
        [HttpGet]
        [AllowAnonymous]
        [ProducesResponseType((int)HttpStatusCode.NotFound)]
        [ProducesResponseType((int)HttpStatusCode.BadRequest)]
        [ProducesResponseType(typeof(List<CouponDto>), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<List<CouponDto>>> GetAllAvailableCouponAsync()
        {
            _logger.LogInformation("----- Get all available coupons");

            var allCoupons = await _couponRepository.GetAllAvailableCouponsAsync();

            if (allCoupons is null || !allCoupons.GetEnumerator().MoveNext())
            {
                return Ok("No coupon available for consumption.");
            }

            var returnList = new List<CouponDto>();
            
            allCoupons.ToList().ForEach(c => 
                returnList.Add(new CouponDto() 
                                { 
                                    Code = c.Code, 
                                    Discount=c.Discount 
                                }
                                ));

            return Ok(returnList);
        }
    }
}
