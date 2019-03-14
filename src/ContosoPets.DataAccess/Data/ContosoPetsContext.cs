using ContosoPets.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace ContosoPets.DataAccess.Data
{
    public partial class ContosoPetsContext : DbContext
    {
        public ContosoPetsContext(DbContextOptions<ContosoPetsContext> options)
            : base(options)
        {
        }

        public virtual DbSet<Product> Products { get; set; }

        // Add the DbSet<T> properties
    }
}
