namespace Coupon.API.Dtos
{
    using Coupon.API.Infrastructure.Models;
    using System.Collections.Generic;

    public class Mapper : IMapper<CouponDto, Coupon>
    {
        public CouponDto Translate(Coupon entity)
        {
            return new CouponDto
            {
                Code = entity.Code,
                Discount = entity.Discount
            };
        }

        public IEnumerable<CouponDto> Translate(IEnumerable<Coupon> entityList)
        {
            var listOfCouponDto = new List<CouponDto>();

            foreach (var entity in entityList)
            {
                listOfCouponDto.Add(
                    new CouponDto
                    {
                        Code = entity.Code,
                        Discount = entity.Discount
                    });
            }

            return listOfCouponDto;
        }
    }
}
