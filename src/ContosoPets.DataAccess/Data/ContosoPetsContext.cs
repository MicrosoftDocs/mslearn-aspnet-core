using Microsoft.EntityFrameworkCore;
// Add the ContosoPets.Domain.Models using statement

namespace ContosoPets.DataAccess.Data
{
    public partial class ContosoPetsContext : DbContext
    {
        public ContosoPetsContext(DbContextOptions<ContosoPetsContext> options)
            : base(options)
        {
        }

        // Add the DbSet<T> properties
    }
}
