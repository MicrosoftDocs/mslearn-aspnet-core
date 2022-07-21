using Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Services
{
    public interface IOrderingService
    {
        Task<List<Order>> GetOrdersAsync();

        Task<OrderData> GetOrderDetailsAsync(int orderId);

    }
}