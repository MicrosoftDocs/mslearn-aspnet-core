using Microsoft.EntityFrameworkCore;
using ContosoPets.Domain.Models;

namespace ContosoPets.DataAccess.Data
{
    public partial class ContosoPetsContext : DbContext
    {
        public ContosoPetsContext()
        {
        }

        public ContosoPetsContext(DbContextOptions<ContosoPetsContext> options)
            : base(options)
        {
        }

        public virtual DbSet<Customer> Customers { get; set; }
        public virtual DbSet<Order> Orders { get; set; }
        public virtual DbSet<ProductOrder> ProductOrder { get; set; }
        public virtual DbSet<Product> Products { get; set; }
    }
}
