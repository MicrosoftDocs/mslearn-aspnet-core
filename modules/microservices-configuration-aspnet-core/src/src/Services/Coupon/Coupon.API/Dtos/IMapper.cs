using System.Collections.Generic;

namespace Coupon.API.Dtos
{
    public interface IMapper<TResult, TEntity>
    {
        TResult Translate(TEntity entity);
        IEnumerable<TResult> Translate(IEnumerable<TEntity> entity);
    }
}
