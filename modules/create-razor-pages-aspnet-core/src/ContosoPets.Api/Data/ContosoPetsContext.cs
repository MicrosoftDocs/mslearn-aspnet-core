using Microsoft.EntityFrameworkCore;
using ContosoPets.Api.Models;

namespace ContosoPets.Api.Data
{
    public class ContosoPetsContext : DbContext
    {
        public ContosoPetsContext(DbContextOptions<ContosoPetsContext> options)
            : base(options)
        {
        }

        public DbSet<Product> Products { get; set; }
    }
}