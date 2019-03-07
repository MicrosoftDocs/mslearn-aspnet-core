using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using ContosoPets.DataAccess.Data;
using ContosoPets.Domain.DataTransferObjects;
using ContosoPets.Domain.Models;

namespace ContosoPets.DataAccess.Services.Fluent
{
    public class OrderService : IOrderService
    {
        private readonly ContosoPetsContext _context;

        public OrderService(ContosoPetsContext context)
        {
            _context = context;
        }

        public async Task<List<CustomerOrder>> GetAll()
        {
            List<CustomerOrder> orders = await (_context.Orders.AsNoTracking()
                .OrderByDescending(o => o.OrderPlaced)
                .Select(o => new CustomerOrder
                {
                    OrderId = o.Id,
                    CustomerName = $"{o.Customer.LastName}, {o.Customer.FirstName}",
                    OrderFulfilled = o.OrderFulfilled.HasValue ? o.OrderFulfilled.Value.ToShortDateString() : string.Empty,
                    OrderPlaced = o.OrderPlaced.ToShortDateString(),
                    OrderLineItems = (o.ProductOrder.Select(po => new OrderLineItem
                    {
                        ProductQuantity = po.Quantity,
                        ProductName = po.Product.Name
                    })).ToList()
                })).ToListAsync();

            return orders;
        }

        public async Task<CustomerOrder> GetById(int id)
        {
            CustomerOrder order = await GetOrderById(id)
                .Select(o => new CustomerOrder
                {
                    CustomerName = $"{o.Customer.LastName}, {o.Customer.FirstName}",
                    OrderFulfilled = o.OrderFulfilled.HasValue ? o.OrderFulfilled.Value.ToShortDateString() : string.Empty,
                    OrderPlaced = o.OrderPlaced.ToShortDateString(),
                    OrderLineItems = (o.ProductOrder.Select(po => new OrderLineItem
                    {
                        ProductQuantity = po.Quantity,
                        ProductName = po.Product.Name
                    })).ToList()
                }).FirstOrDefaultAsync();

            return order;
        }

        public async Task<bool> Delete(int id)
        {
            bool isDeleted = false;
            Order order = await GetOrderById(id)
                .Include(o => o.ProductOrder)
                .FirstOrDefaultAsync();

            if (order != null)
            {
                _context.Remove(order);
                await _context.SaveChangesAsync();
                isDeleted = true;
            }

            return isDeleted;
        }


        public async Task<Order> Create(NewOrder newOrder)
        {
            var lineItems = new List<ProductOrder>();

            foreach (var li in newOrder.OrderLineItems)
            {
                lineItems.Add(new ProductOrder
                {
                    Quantity = li.Quantity,
                    ProductId = li.ProductId
                });
            }

            var order = new Order
            {
                CustomerId = newOrder.CustomerId,
                ProductOrder = lineItems
            };

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            return order;
        }

        public async Task<bool> SetFulfilled(int id)
        {
            bool isFulfilled = false;
            Order order = await GetOrderById(id).FirstOrDefaultAsync();

            if (order != null)
            {
                order.OrderFulfilled = DateTime.UtcNow;
                _context.Entry(order).State = EntityState.Modified;
                await _context.SaveChangesAsync();
                isFulfilled = true;
            }

            return isFulfilled;
        }

        private IQueryable<Order> GetOrderById(int id) =>
            _context.Orders.AsNoTracking().Where(o => o.Id == id);
    }
}