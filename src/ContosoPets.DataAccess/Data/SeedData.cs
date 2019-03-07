using System;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using ContosoPets.Domain.Models;

namespace ContosoPets.DataAccess.Data
{
    public static class SeedData
    {       
        public static void Initialize(ContosoPetsContext context)
        {
            if (!context.Products.Any())
            {
                context.Products.AddRange(
                    new Product
                    {
                        Name = "Squeaky Bone",
                        Price = 20.99m
                    },
                    new Product
                    {
                        Name = "Knotted Rope",
                        Price = 12.99m
                    }
                );

                context.SaveChanges();
            }

            if (!context.Customers.Any())
            {
                context.Customers.AddRange(
                    new Customer
                    {
                        FirstName = "Scott",
                        LastName = "Addie",
                        StreetAddress = "",
                        City = "",
                        StateOrProvinceAbbr = "",
                        Country = "",
                        PostalCode = "",
                        Phone = "",
                        Email = ""
                    },
                    new Customer
                    {
                        FirstName = "Cam",
                        LastName = "Soper",
                        StreetAddress = "",
                        City = "",
                        StateOrProvinceAbbr = "",
                        Country = "",
                        PostalCode = "",
                        Phone = "",
                        Email = ""
                    }
                );

                context.SaveChanges();
            }

            if (!context.Orders.Any())
            {
                IQueryable<Customer> sortedCustomers =
                    from c in context.Customers.AsNoTracking()
                    orderby c.Id
                    select c;

                context.Orders.AddRange(
                    new Order
                    {
                        OrderPlaced = DateTime.UtcNow.AddDays(-1),
                        OrderFulfilled = DateTime.UtcNow.AddHours(1),
                        Customer = sortedCustomers.FirstOrDefault()
                    },
                    new Order
                    {
                        OrderPlaced = DateTime.UtcNow.AddDays(-3),
                        OrderFulfilled = DateTime.UtcNow.AddHours(4),
                        Customer = sortedCustomers.LastOrDefault()
                    }
                );

                context.SaveChanges();
            }

            if (!context.ProductOrder.Any())
            {
                IQueryable<Order> sortedOrders =
                    from o in context.Orders.AsNoTracking()
                    orderby o.Id
                    select o;
                IQueryable<Product> sortedProducts =
                    from p in context.Products.AsNoTracking()
                    orderby p.Id
                    select p;

                context.ProductOrder.AddRange(
                    new ProductOrder
                    {
                        Order = sortedOrders.FirstOrDefault(),
                        Product = sortedProducts.FirstOrDefault(),
                        Quantity = 10
                    },
                    new ProductOrder
                    {
                        Order = sortedOrders.LastOrDefault(),
                        Product = sortedProducts.LastOrDefault(),
                        Quantity = 2
                    }
                );

                context.SaveChanges();
            }
        }
    }
}
