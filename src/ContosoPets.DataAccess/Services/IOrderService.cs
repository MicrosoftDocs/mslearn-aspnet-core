using System.Collections.Generic;
using System.Threading.Tasks;
using ContosoPets.Domain.DataTransferObjects;
using ContosoPets.Domain.Models;

namespace ContosoPets.DataAccess.Services
{
    public interface IOrderService
    {
        Task<List<CustomerOrder>> GetAll();
        Task<CustomerOrder> GetById(int id);
        Task<bool> Delete(int id);
        Task<Order> Create(NewOrder order);
        Task<bool> SetFulfilled(int id);
    }
}