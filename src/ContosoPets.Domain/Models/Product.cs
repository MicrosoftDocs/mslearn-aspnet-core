using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace ContosoPets.Domain.Models
{
    public partial class Product
    {
        public Product()
        {
            ProductOrder = new HashSet<ProductOrder>();
        }

        public int Id { get; set; }
        public string Name { get; set; }
        [Column(TypeName = "decimal(18, 2)")]
        public decimal Price { get; set; }

        public virtual ICollection<ProductOrder> ProductOrder { get; set; }
    }
}
